import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_detail_repository.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';

import '../fixtures/test_keys.dart';
import '../helpers/test_database.dart';

class _MockLoginService extends Mock implements LoginService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultRepository backupConfig removal', () {
    late VaultRepository repository;
    const ownerPubkey = 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';

    setUp(() {
      repository = VaultRepository(_MockLoginService());
    });

    tearDown(() => repository.dispose());

    test('persisting null backupConfig clears stewards so hydration has no config', () async {
      final steward = createSteward(
        pubkey: 'b0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e',
        name: 'S',
      );
      final config = createBackupConfig(
        vaultId: 'vault-del-bc',
        threshold: 1,
        totalKeys: 1,
        stewards: [steward],
        relays: const ['wss://relay.example.com'],
      );
      final created = DateTime.utc(2025, 1, 1);
      final withConfig = Vault(
        id: 'vault-del-bc',
        name: 'V',
        createdAt: created,
        ownerPubkey: ownerPubkey,
        backupConfig: config,
        pushEnabled: true,
      );
      await repository.addVault(withConfig);
      final loadedWith = await repository.getVault('vault-del-bc');
      expect(loadedWith!.backupConfig, isNotNull);
      expect(loadedWith.backupConfig!.stewards, hasLength(1));

      await repository.saveVault(loadedWith.copyWith(backupConfig: null));
      final loadedWithout = await repository.getVault('vault-del-bc');
      expect(loadedWithout!.backupConfig, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Steward position-conflict regression tests
  // ---------------------------------------------------------------------------

  group('VaultRepository steward position conflicts', () {
    late AppDatabase db;
    late VaultRepository repository;

    const ownerPubkey = TestHexPubkeys.alice;
    const macPubkey = TestHexPubkeys.bob;

    setUp(() {
      db = newTestDatabase();
      repository = VaultRepository(_MockLoginService(), db: db);
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
    });

    test(
      '_persistVault: adding owner at position 1 when Mac already occupies position 1 succeeds',
      () async {
        // Arrange: vault with Mac as the only steward at share_index 1.
        const vaultId = 'vault-reposition';
        final mac = createSteward(pubkey: macPubkey, name: 'Mac');
        final configV1 = createBackupConfig(
          vaultId: vaultId,
          threshold: 1,
          totalKeys: 1,
          stewards: [mac],
          relays: const ['wss://relay.example.com'],
        );
        await repository.addVault(
          Vault(
            id: vaultId,
            name: 'Reposition Vault',
            createdAt: DateTime.utc(2026, 5, 11),
            ownerPubkey: ownerPubkey,
            backupConfig: configV1,
          ),
        );

        // Confirm Mac is at share_index 1.
        final v1 = await repository.getVault(vaultId);
        expect(v1!.backupConfig!.stewards, hasLength(1));

        // Act: user edits the plan and adds themselves (owner) at position 1,
        // pushing Mac to position 2. This previously triggered a UNIQUE
        // constraint on (vault_id, share_index) WHERE left_at IS NULL.
        final owner = createOwnerSteward(pubkey: ownerPubkey, name: 'Owner');
        final configV2 = createBackupConfig(
          vaultId: vaultId,
          threshold: 1,
          totalKeys: 2,
          stewards: [owner, mac], // owner first → shareIndex 1, mac → 2
          relays: const ['wss://relay.example.com'],
        );

        // Must not throw.
        await expectLater(
          repository.updateBackupConfig(vaultId, configV2),
          completes,
        );

        // Assert: both stewards present at their new positions.
        final v2 = await repository.getVault(vaultId);
        final stewards = v2!.backupConfig!.stewards;
        expect(stewards, hasLength(2));
        expect(stewards.any((s) => s.pubkey == ownerPubkey), isTrue);
        expect(stewards.any((s) => s.pubkey == macPubkey), isTrue);

        // Verify via the DB that share indices are correct.
        final rows = await db.stewardDao.activeForVault(vaultId);
        final byPubkey = {for (final r in rows) r.pubkey: r.shareIndex};
        expect(byPubkey[ownerPubkey], 1);
        expect(byPubkey[macPubkey], 2);
      },
    );

    test(
      'upsertStewardRow: incumbent at same share_index is retired when a new id arrives',
      () async {
        // Arrange: vault with a steward row (id=old-uuid) at share_index 1.
        const vaultId = 'vault-upsert-incumbent';
        const oldStewardId = 'old-steward-uuid';
        const newStewardId = 'new-steward-uuid';

        await repository.addVault(
          Vault(
            id: vaultId,
            name: 'Incumbent Test',
            createdAt: DateTime.utc(2026, 5, 11),
            ownerPubkey: ownerPubkey,
          ),
        );
        // Insert a steward directly into the DB (simulates an earlier config).
        await db.into(db.stewards).insert(StewardsCompanion.insert(
              id: oldStewardId,
              vaultId: vaultId,
              shareIndex: 1,
              pubkey: const Value(macPubkey),
              name: const Value('Mac-old'),
              joinedAt: DateTime.now().millisecondsSinceEpoch,
            ));

        // Act: steward-side shard ingestion calls upsertStewardRow with a
        // different id for the same (vault_id, share_index=1) slot. This
        // previously caused UNIQUE constraint failure.
        await expectLater(
          repository.upsertStewardRow(
            id: newStewardId,
            vaultId: vaultId,
            shareIndex: 1,
            pubkey: macPubkey,
            name: 'Mac-new',
          ),
          completes,
        );

        // Assert: only the new steward is active; old one is soft-retired.
        final activeRows = await db.stewardDao.activeForVault(vaultId);
        expect(activeRows, hasLength(1));
        expect(activeRows.single.id, newStewardId);
        expect(activeRows.single.name, 'Mac-new');

        final oldRow = await db.stewardDao.getById(oldStewardId);
        expect(oldRow, isNotNull);
        expect(oldRow!.leftAt, isNotNull, reason: 'old steward must be soft-retired');
      },
    );

    test(
      'inviteCode is hydrated from invitations table after overlay is cleared (restart simulation)',
      () async {
        // Arrange: vault with an invited steward + invitation row.
        const vaultId = 'vault-invite-hydrate';
        final invited = createInvitedSteward(name: 'Mac', inviteCode: 'mac-invite-001');
        final config = createBackupConfig(
          vaultId: vaultId,
          threshold: 1,
          totalKeys: 1,
          stewards: [invited],
          relays: const ['wss://relay.example.com'],
        );
        await repository.addVault(
          Vault(
            id: vaultId,
            name: 'Invite Hydrate Vault',
            createdAt: DateTime.utc(2026, 5, 11),
            ownerPubkey: ownerPubkey,
          ),
        );
        await repository.updateBackupConfig(vaultId, config);
        // Seed the invitation row that generateInvitationLink would normally write.
        await db.into(db.invitations).insert(InvitationsCompanion.insert(
              code: 'mac-invite-001',
              vaultId: vaultId,
              stewardId: Value(invited.id),
              payload: '{}',
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ));

        // Simulate restart: dispose and recreate (overlay cleared).
        repository.dispose();
        repository = VaultRepository(_MockLoginService(), db: db);

        // Act: hydrate vault from DB.
        final vault = await repository.getVault(vaultId);
        final steward = vault!.backupConfig!.stewards.single;

        // Assert: inviteCode survives restart via the invitations table.
        expect(steward.inviteCode, 'mac-invite-001');
        expect(steward.pubkey, isNull);
        expect(steward.status, StewardStatus.invited);

        // Also verify VaultDetailRepository (the UI path) sees it.
        final detailRepo = VaultDetailRepository(db: db);
        addTearDown(detailRepo.dispose);
        final detail = await detailRepo.getVaultDetail(vaultId);
        expect(detail!.backupConfig!.stewards.single.inviteCode, 'mac-invite-001');
      },
    );
  });
}
