import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndk/ndk.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/invitation_link.dart';
import 'package:horcrux/models/invitation_status.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/event_authorizer.dart';
import 'package:horcrux/services/login_service.dart';

import '../fixtures/test_keys.dart';
import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const vaultId = 'auth-vault';
  const recoveryRequestId = 'auth-recovery-request';

  late AppDatabase db;
  late VaultRepository repository;
  late EventAuthorizer authorizer;

  Nip01Event event({
    required NostrKind kind,
    String pubKey = TestHexPubkeys.alice,
    List<List<String>> tags = const [],
  }) {
    return Nip01Event(
      pubKey: pubKey,
      kind: kind.value,
      tags: tags,
      content: '',
      createdAt: 1759759657,
    );
  }

  Nip01Event shareDataEvent({
    String vaultId = vaultId,
    String pubKey = TestHexPubkeys.alice,
  }) {
    return event(
      kind: NostrKind.shareData,
      pubKey: pubKey,
      tags: [
        ['vault_id', vaultId],
        ['share_index', '0'],
        ['total_shares', '2'],
        ['threshold', '1'],
      ],
    );
  }

  Future<void> seedVault() async {
    final config = createBackupConfig(
      vaultId: vaultId,
      threshold: 1,
      totalKeys: 2,
      stewards: [
        createOwnerSteward(
          id: 'owner-steward',
          pubkey: TestHexPubkeys.alice,
          name: 'Alice',
        ),
        createSteward(
          id: 'bob-steward',
          pubkey: TestHexPubkeys.bob,
          name: 'Bob',
        ),
      ],
      relays: ['wss://relay.example.com'],
    );

    await repository.addVault(
      Vault(
        id: vaultId,
        name: 'Authorization Vault',
        createdAt: DateTime.utc(2026),
        ownerPubkey: TestHexPubkeys.alice,
        backupConfig: config,
      ),
    );
  }

  Future<void> seedInvitation({
    required String inviteCode,
    String? redeemedBy,
  }) async {
    final link = createInvitationLink(
      inviteCode: inviteCode,
      vaultId: vaultId,
      ownerPubkey: TestHexPubkeys.alice,
      relayUrls: ['wss://relay.example.com'],
      inviteeName: 'Bob',
    ).updateStatus(
      redeemedBy == null ? InvitationStatus.pending : InvitationStatus.redeemed,
      redeemedBy: redeemedBy,
      redeemedAt: redeemedBy == null ? null : DateTime.utc(2026),
    );

    await db.invitationDao.upsert(
      InvitationsCompanion.insert(
        code: inviteCode,
        vaultId: vaultId,
        payload: jsonEncode(invitationLinkToJson(link)),
        createdAt: DateTime.utc(2026).millisecondsSinceEpoch,
        acceptedAt: Value(link.redeemedAt?.millisecondsSinceEpoch),
        acceptedByPubkey: Value(redeemedBy),
      ),
    );
  }

  setUp(() async {
    db = newTestDatabase();
    repository = VaultRepository(LoginService(), db: db);
    authorizer = EventAuthorizer(repository, db);
    await seedVault();
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  group('EventAuthorizer', () {
    test('denies unknown and unrouted kinds by default', () async {
      final unknown = Nip01Event(
        pubKey: TestHexPubkeys.alice,
        kind: 999,
        tags: [
          ['vault_id', vaultId],
        ],
        content: '',
        createdAt: 1759759657,
      );

      expect(
        await authorizer.authorize(
          rumor: unknown,
          verifiedSenderPubkey: TestHexPubkeys.alice,
        ),
        AuthDecision.deny,
      );

      expect(
        await authorizer.authorize(
          rumor: event(
            kind: NostrKind.shareError,
            tags: [
              ['vault_id', vaultId],
            ],
          ),
          verifiedSenderPubkey: TestHexPubkeys.alice,
        ),
        AuthDecision.deny,
      );
    });

    test('authorizes shareData from the verified creator', () async {
      expect(
        await authorizer.authorize(
          rumor: shareDataEvent(),
          verifiedSenderPubkey: TestHexPubkeys.alice,
        ),
        AuthDecision.allow,
      );

      expect(
        await authorizer.authorize(
          rumor: shareDataEvent(vaultId: 'new-inbound-vault'),
          verifiedSenderPubkey: TestHexPubkeys.alice,
        ),
        AuthDecision.allow,
      );
    });

    test('denies shareData from a forged creator or wrong existing owner', () async {
      expect(
        await authorizer.authorize(
          rumor: shareDataEvent(),
          verifiedSenderPubkey: TestHexPubkeys.bob,
        ),
        AuthDecision.deny,
      );

      expect(
        await authorizer.authorize(
          rumor: shareDataEvent(pubKey: TestHexPubkeys.bob),
          verifiedSenderPubkey: TestHexPubkeys.bob,
        ),
        AuthDecision.deny,
      );
    });

    test('authorizes invitations by invite code and redeemed pubkey', () async {
      const pendingInviteCode = 'pending-invite';
      const redeemedInviteCode = 'redeemed-invite';
      await seedInvitation(inviteCode: pendingInviteCode);
      await seedInvitation(
        inviteCode: redeemedInviteCode,
        redeemedBy: TestHexPubkeys.bob,
      );

      for (final kind in [
        NostrKind.invitationAcceptance,
        NostrKind.invitationDenial,
      ]) {
        expect(
          await authorizer.authorize(
            rumor: event(
              kind: kind,
              pubKey: TestHexPubkeys.bob,
              tags: [
                ['invite_code', pendingInviteCode],
                ['vault_id', vaultId],
              ],
            ),
            verifiedSenderPubkey: TestHexPubkeys.bob,
          ),
          AuthDecision.allow,
        );
        expect(
          await authorizer.authorize(
            rumor: event(
              kind: kind,
              pubKey: TestHexPubkeys.bob,
              tags: [
                ['invite_code', redeemedInviteCode],
                ['vault_id', vaultId],
              ],
            ),
            verifiedSenderPubkey: TestHexPubkeys.bob,
          ),
          AuthDecision.allow,
        );
        expect(
          await authorizer.authorize(
            rumor: event(
              kind: kind,
              pubKey: TestHexPubkeys.charlie,
              tags: [
                ['invite_code', redeemedInviteCode],
                ['vault_id', vaultId],
              ],
            ),
            verifiedSenderPubkey: TestHexPubkeys.charlie,
          ),
          AuthDecision.deny,
        );
      }
    });

    test('denies invitations with missing or unknown invite codes', () async {
      expect(
        await authorizer.authorize(
          rumor: event(kind: NostrKind.invitationAcceptance),
          verifiedSenderPubkey: TestHexPubkeys.bob,
        ),
        AuthDecision.deny,
      );
      await seedInvitation(inviteCode: 'known-invite');
      expect(
        await authorizer.authorize(
          rumor: event(
            kind: NostrKind.invitationAcceptance,
            tags: [
              ['invite_code', 'known-invite'],
            ],
          ),
          verifiedSenderPubkey: TestHexPubkeys.bob,
        ),
        AuthDecision.deny,
      );
      expect(
        await authorizer.authorize(
          rumor: event(
            kind: NostrKind.invitationDenial,
            tags: [
              ['invite_code', 'unknown-invite'],
              ['vault_id', vaultId],
            ],
          ),
          verifiedSenderPubkey: TestHexPubkeys.bob,
        ),
        AuthDecision.deny,
      );
    });

    test('denies invitations whose vault_id does not match stored invitation', () async {
      await seedInvitation(inviteCode: 'vault-mismatch-invite');

      for (final kind in [
        NostrKind.invitationAcceptance,
        NostrKind.invitationDenial,
      ]) {
        expect(
          await authorizer.authorize(
            rumor: event(
              kind: kind,
              tags: [
                ['invite_code', 'vault-mismatch-invite'],
                ['vault_id', 'different-vault'],
              ],
            ),
            verifiedSenderPubkey: TestHexPubkeys.bob,
          ),
          AuthDecision.deny,
        );
      }
    });

    test('authorizes keyHolderRemoved only from the vault owner', () async {
      final rumor = event(
        kind: NostrKind.keyHolderRemoved,
        tags: [
          ['vault_id', vaultId],
        ],
      );

      expect(
        await authorizer.authorize(
          rumor: rumor,
          verifiedSenderPubkey: TestHexPubkeys.alice,
        ),
        AuthDecision.allow,
      );
      expect(
        await authorizer.authorize(
          rumor: rumor,
          verifiedSenderPubkey: TestHexPubkeys.bob,
        ),
        AuthDecision.deny,
      );
    });

    test('authorizes shareConfirmation only from known stewards', () async {
      final rumor = event(
        kind: NostrKind.shareConfirmation,
        tags: [
          ['vault_id', vaultId],
        ],
      );

      expect(
        await authorizer.authorize(
          rumor: rumor,
          verifiedSenderPubkey: TestHexPubkeys.bob,
        ),
        AuthDecision.allow,
      );
      expect(
        await authorizer.authorize(
          rumor: rumor,
          verifiedSenderPubkey: TestHexPubkeys.charlie,
        ),
        AuthDecision.deny,
      );
    });

    test('authorizes recoveryRequest from owner or known steward', () async {
      final rumor = event(
        kind: NostrKind.recoveryRequest,
        tags: [
          ['vault_id', vaultId],
          ['recovery_request_id', recoveryRequestId],
        ],
      );

      expect(
        await authorizer.authorize(
          rumor: rumor,
          verifiedSenderPubkey: TestHexPubkeys.alice,
        ),
        AuthDecision.allow,
      );
      expect(
        await authorizer.authorize(
          rumor: rumor,
          verifiedSenderPubkey: TestHexPubkeys.bob,
        ),
        AuthDecision.allow,
      );
      expect(
        await authorizer.authorize(
          rumor: rumor,
          verifiedSenderPubkey: TestHexPubkeys.charlie,
        ),
        AuthDecision.deny,
      );
    });

    test(
      'authorizes recoveryResponse only from request participants',
      () async {
        await repository.addRecoveryRequestToVault(
          vaultId,
          RecoveryRequest.makeFromParticipants(
            id: recoveryRequestId,
            vaultId: vaultId,
            initiatorPubkey: TestHexPubkeys.alice,
            requestedAt: DateTime.utc(2026),
            status: RecoveryRequestStatus.inProgress,
            threshold: 1,
            stewardPubkeys: const [TestHexPubkeys.bob],
          ),
        );
        final rumor = event(
          kind: NostrKind.recoveryResponse,
          tags: [
            ['vault_id', vaultId],
            ['recovery_request_id', recoveryRequestId],
          ],
        );

        expect(
          await authorizer.authorize(
            rumor: rumor,
            verifiedSenderPubkey: TestHexPubkeys.bob,
          ),
          AuthDecision.allow,
        );
        expect(
          await authorizer.authorize(
            rumor: rumor,
            verifiedSenderPubkey: TestHexPubkeys.charlie,
          ),
          AuthDecision.deny,
        );
      },
    );

    test('denies enforcing kinds when required tags are absent', () async {
      for (final kind in [
        NostrKind.recoveryRequest,
        NostrKind.recoveryResponse,
        NostrKind.shareConfirmation,
        NostrKind.keyHolderRemoved,
      ]) {
        expect(
          await authorizer.authorize(
            rumor: event(kind: kind),
            verifiedSenderPubkey: TestHexPubkeys.alice,
          ),
          AuthDecision.deny,
        );
      }
    });
  });
}
