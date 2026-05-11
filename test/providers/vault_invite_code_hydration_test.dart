import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/ndk.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_detail_repository.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/backup_service.dart';
import 'package:horcrux/services/invitation_sending_service.dart';
import 'package:horcrux/services/invitation_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
import 'package:horcrux/utils/date_time_extensions.dart';

import '../fixtures/test_keys.dart';
import '../helpers/test_database.dart';

// Minimal mocks — only what InvitationService needs at the boundaries.
class _MockLoginService extends Mock implements LoginService {}

class _MockNdkService extends Mock implements NdkService {}

class _MockInvitationSendingService extends Mock implements InvitationSendingService {}

class _MockRelayScanService extends Mock implements RelayScanService {}

class _MockBackupService extends Mock implements BackupService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('invite code hydration', () {
    late AppDatabase db;
    late VaultRepository repository;
    late _MockLoginService mockLoginService;

    const ownerPubkey = TestHexPubkeys.alice;
    const macPubkey = TestHexPubkeys.bob;
    const vaultId = 'vault-invite-hydration';

    setUp(() {
      db = newTestDatabase();
      mockLoginService = _MockLoginService();
      repository = VaultRepository(mockLoginService, db: db);
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
    });

    /// Seeds an owned vault with an invited steward (no pubkey) and a
    /// corresponding invitation row, then returns the steward's id and the
    /// invite code.
    Future<({String stewardId, String inviteCode})> _seedVaultWithInvitedSteward() async {
      await repository.addVault(
        Vault(
          id: vaultId,
          name: 'Hydration Test Vault',
          createdAt: DateTime.utc(2026, 5, 11, 16, 0),
          ownerPubkey: ownerPubkey,
          pushEnabled: true,
        ),
      );

      final invited = createInvitedSteward(name: 'Mac', inviteCode: 'invite-mac-001');
      final config = createBackupConfig(
        vaultId: vaultId,
        threshold: 1,
        totalKeys: 1,
        stewards: [invited],
        relays: const ['wss://relay.example.com'],
      );
      await repository.updateBackupConfig(vaultId, config);

      // Seed the invitations table (what generateInvitationLink normally writes).
      await db.into(db.invitations).insert(
            InvitationsCompanion.insert(
              code: 'invite-mac-001',
              vaultId: vaultId,
              stewardId: Value(invited.id),
              payload: '{}',
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

      return (stewardId: invited.id, inviteCode: 'invite-mac-001');
    }

    test(
      'VaultRepository hydrates inviteCode from invitations table after overlay is cleared',
      () async {
        final seed = await _seedVaultWithInvitedSteward();

        // Simulate a restart: dispose the repository (clears overlay) and create
        // a fresh instance backed by the same DB.
        repository.dispose();
        repository = VaultRepository(mockLoginService, db: db);

        final vault = await repository.getVault(vaultId);
        final steward = vault!.backupConfig!.stewards.single;

        expect(steward.inviteCode, 'invite-mac-001',
            reason: 'inviteCode must survive a restart by being read from the invitations table');
        expect(steward.pubkey, isNull);
        expect(steward.status, StewardStatus.invited);
        expect(seed.stewardId, steward.id); // same steward slot
      },
    );

    test(
      'VaultDetailRepository hydrates inviteCode from invitations table',
      () async {
        await _seedVaultWithInvitedSteward();

        // VaultDetailRepository has no overlay at all — this was always restart-safe
        // only if it read from the invitations table.
        final detailRepository = VaultDetailRepository(db: db);
        addTearDown(detailRepository.dispose);

        final detail = await detailRepository.getVaultDetail(vaultId);
        final steward = detail!.backupConfig!.stewards.single;

        expect(steward.inviteCode, 'invite-mac-001');
        expect(steward.status, StewardStatus.invited);
      },
    );

    test(
      'processInvitationAcceptanceEvent updates existing invited steward in-place (no duplicate) even after restart',
      () async {
        // ── Arrange ───────────────────────────────────────────────────────────
        await repository.addVault(
          Vault(
            id: vaultId,
            name: 'Hydration Test Vault',
            createdAt: DateTime.utc(2026, 5, 11, 16, 0),
            ownerPubkey: ownerPubkey,
            pushEnabled: true,
          ),
        );

        // Simulate the invite flow: InvitationService.generateInvitationLink
        // creates the invited steward + invitation row. We replicate that here.
        final mockNdkService = _MockNdkService();
        final mockSendingService = _MockInvitationSendingService();
        final mockRelayScanService = _MockRelayScanService();
        final mockBackupService = _MockBackupService();

        when(mockLoginService.getCurrentPublicKey()).thenAnswer((_) async => ownerPubkey);
        when(mockLoginService.encryptText(any))
            .thenAnswer((i) async => i.positionalArguments[0] as String);
        when(mockLoginService.decryptText(any))
            .thenAnswer((i) async => i.positionalArguments[0] as String);
        when(mockBackupService.distributeKeysIfNecessary(any)).thenAnswer((_) async {});
        when(
          mockSendingService.sendInvitationLink(
            inviteCode: anyNamed('inviteCode'),
            vaultId: anyNamed('vaultId'),
            vaultName: anyNamed('vaultName'),
            ownerPubkey: anyNamed('ownerPubkey'),
            ownerName: anyNamed('ownerName'),
            inviteeName: anyNamed('inviteeName'),
            relayUrls: anyNamed('relayUrls'),
            recipientPubkey: anyNamed('recipientPubkey'),
          ),
        ).thenAnswer((_) async => 'event-id-send');

        final invitationService = InvitationService(
          repository,
          mockSendingService,
          mockLoginService,
          () => mockNdkService,
          mockRelayScanService,
          mockBackupService,
          db,
        );

        // Generate the invite — this writes the invited steward + invitation row.
        await invitationService.generateInvitationLink(
          vaultId: vaultId,
          inviteeName: 'Mac',
          relayUrls: const ['wss://relay.example.com'],
        );

        // Confirm only one steward exists after invite creation.
        final configBeforeAcceptance = await repository.getBackupConfig(vaultId);
        expect(configBeforeAcceptance!.stewards, hasLength(1));
        expect(configBeforeAcceptance.stewards.single.pubkey, isNull);
        final generatedCode = configBeforeAcceptance.stewards.single.inviteCode!;

        // ── Simulate restart ──────────────────────────────────────────────────
        repository.dispose();
        repository = VaultRepository(mockLoginService, db: db);

        // Re-create InvitationService with the fresh repository.
        final invitationServiceAfterRestart = InvitationService(
          repository,
          mockSendingService,
          mockLoginService,
          () => mockNdkService,
          mockRelayScanService,
          mockBackupService,
          db,
        );

        // Verify inviteCode is present even after restart.
        final configAfterRestart = await repository.getBackupConfig(vaultId);
        expect(
          configAfterRestart!.stewards.single.inviteCode,
          generatedCode,
          reason: 'inviteCode must be recoverable from the invitations table after restart',
        );

        // ── Act: Mac accepts the invite ───────────────────────────────────────
        final acceptancePayload = json.encode({
          'invite_code': generatedCode,
          'invitee_pubkey': macPubkey,
          'responded_at': DateTime.now().toIso8601String(),
        });
        final acceptanceEvent = Nip01Event(
          kind: NostrKind.invitationAcceptance.value,
          pubKey: macPubkey,
          tags: const [],
          createdAt: secondsSinceEpoch(),
          content: acceptancePayload,
        );

        await invitationServiceAfterRestart.processInvitationAcceptanceEvent(
          event: acceptanceEvent,
        );

        // ── Assert ────────────────────────────────────────────────────────────
        final updatedConfig = await repository.getBackupConfig(vaultId);
        expect(updatedConfig, isNotNull);

        // Must be exactly ONE steward — no duplicate invited entry.
        expect(
          updatedConfig!.stewards,
          hasLength(1),
          reason:
              'acceptance must update the existing invited steward in-place, not add a duplicate',
        );

        final steward = updatedConfig.stewards.single;
        expect(steward.pubkey, macPubkey);
        expect(steward.name, 'Mac');
        expect(
          steward.status,
          anyOf(StewardStatus.awaitingKey, StewardStatus.holdingKey),
          reason: 'accepted steward should not remain in invited state',
        );
      },
    );
  });
}
