import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';

import '../fixtures/test_keys.dart';
import '../helpers/test_database.dart';

class _MockLoginService extends Mock implements LoginService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultRepository held_shares hydration', () {
    late AppDatabase db;
    late VaultRepository repository;

    setUp(() {
      db = newTestDatabase();
      repository = VaultRepository(_MockLoginService(), db: db);
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
    });

    test('hydrated Share.createdAt uses vault epoch seconds (not ms)', () async {
      final createdAt = DateTime.utc(2024, 6, 15, 12, 30, 45);
      final createdAtMs = createdAt.millisecondsSinceEpoch;

      final fixture = await VaultFixture.stewarded(
        db,
        ownerPubkey: TestHexPubkeys.alice,
        threshold: 2,
        totalShares: 3,
        createdAt: createdAtMs,
      );

      await (db.update(db.vaults)..where((v) => v.id.equals(fixture.vaultId))).write(
        const VaultsCompanion(primeMod: Value('prime-mod')),
      );

      final share = Share(
        payload: 'payload-bytes',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        scheme: null,
        creatorPubkey: TestHexPubkeys.alice,
        vaultId: fixture.vaultId,
        // Wrong units on purpose — hydration must derive seconds from the vault row.
        createdAt: createdAtMs,
      );

      await repository.addShareToVault(fixture.vaultId, share);

      final shares = await repository.getSharesForVault(fixture.vaultId);
      expect(shares, hasLength(1));

      final expectedSeconds = createdAtMs ~/ 1000;
      expect(shares.single.createdAt, expectedSeconds);

      final json = shareToJson(shares.single);
      expect(json['created_at'], expectedSeconds);
    });

    test(
      'addShareToVault replaces prior row for same vault, shareIndex, and '
      'distributionVersion (republished gift-wrap id)',
      () async {
        final fixture = await VaultFixture.stewarded(
          db,
          ownerPubkey: TestHexPubkeys.alice,
          threshold: 2,
          totalShares: 3,
        );

        await (db.update(db.vaults)..where((v) => v.id.equals(fixture.vaultId))).write(
          const VaultsCompanion(primeMod: Value('prime-mod')),
        );

        Future<void> addSlot0({required String payload, required String eventId}) {
          return repository.addShareToVault(
            fixture.vaultId,
            Share(
              payload: payload,
              threshold: 2,
              shareIndex: 0,
              totalShares: 3,
              scheme: null,
              creatorPubkey: TestHexPubkeys.alice,
              createdAt: 1700000000,
              vaultId: fixture.vaultId,
              distributionVersion: 7,
              nostrEventId: eventId,
            ),
          );
        }

        await addSlot0(payload: 'first-bytes', eventId: 'evt-aaa');
        var rows = await db.heldShareDao.forVault(fixture.vaultId);
        expect(rows, hasLength(1));
        expect(rows.single.sharePayload, 'first-bytes');
        expect(rows.single.nostrEventId, 'evt-aaa');

        await addSlot0(payload: 'second-bytes', eventId: 'evt-bbb');
        rows = await db.heldShareDao.forVault(fixture.vaultId);
        expect(rows, hasLength(1));
        expect(rows.single.sharePayload, 'second-bytes');
        expect(rows.single.nostrEventId, 'evt-bbb');

        await repository.addShareToVault(
          fixture.vaultId,
          Share(
            payload: 'slot1',
            threshold: 2,
            shareIndex: 1,
            totalShares: 3,
            scheme: null,
            creatorPubkey: TestHexPubkeys.alice,
            createdAt: 1700000000,
            vaultId: fixture.vaultId,
            distributionVersion: 7,
            nostrEventId: 'evt-ccc',
          ),
        );
        rows = await db.heldShareDao.forVault(fixture.vaultId);
        expect(rows, hasLength(2));
      },
    );

    test(
      'mergeVaultRowFromIncomingShare persists Shamir metadata when vault has '
      'no BackupConfig (steward bootstrap)',
      () async {
        const vaultId = 'bootstrap-steward-vault';

        await repository.addVault(
          Vault(
            id: vaultId,
            name: 'Stub',
            createdAt: DateTime.utc(2024, 1, 2),
            ownerPubkey: TestHexPubkeys.alice,
            pushEnabled: false,
          ),
        );

        const share = Share(
          payload: 'payload-bytes',
          threshold: 2,
          shareIndex: 1,
          totalShares: 4,
          scheme: null,
          creatorPubkey: TestHexPubkeys.alice,
          createdAt: 1704153600,
          vaultId: vaultId,
          distributionVersion: 3,
          nostrEventId: 'nostr-evt-bootstrap',
        );

        await repository.mergeVaultRowFromIncomingShare(vaultId, share);
        await repository.addShareToVault(vaultId, share);

        final shares = await repository.getSharesForVault(vaultId);
        expect(shares.single.isValid, isTrue);
        expect(shares.single.threshold, 2);
        expect(shares.single.totalShares, 4);
        expect(shares.single.scheme, 'gf256_v1');

        final json = shareToJson(shares.single);
        expect(json['threshold'], 2);
        expect(json['total_shards'], 4);
        expect(json['scheme'], 'gf256_v1');
      },
    );

    test('mergeVaultRowFromIncomingShare ignores stale distribution_version', () async {
      const vaultId = 'stale-dist-vault';

      await repository.addVault(
        Vault(
          id: vaultId,
          name: 'V',
          createdAt: DateTime.utc(2024, 1, 2),
          ownerPubkey: TestHexPubkeys.alice,
          pushEnabled: false,
        ),
      );

      const fresh = Share(
        payload: 'a',
        threshold: 3,
        shareIndex: 0,
        totalShares: 5,
        scheme: null,
        creatorPubkey: TestHexPubkeys.alice,
        createdAt: 1704153600,
        vaultId: vaultId,
        distributionVersion: 10,
        nostrEventId: 'evt-fresh',
      );
      await repository.mergeVaultRowFromIncomingShare(vaultId, fresh);

      final stale = fresh.copyWith(
        distributionVersion: 4,
        threshold: 1,
        totalShares: 2,
        scheme: null,
        nostrEventId: 'evt-stale',
      );
      await repository.mergeVaultRowFromIncomingShare(vaultId, stale);

      final row = await db.vaultDao.getById(vaultId);
      expect(row!.threshold, 3);
      expect(row.totalShares, 5);
      // primeMod column is no longer written; scheme lives in share.scheme
      expect(row.primeMod, equals(null));
      expect(row.currentDistributionVersion, 10);
    });

    test('clearAll deletes held_shares explicitly before vaults', () async {
      final fixture = await VaultFixture.stewarded(
        db,
        ownerPubkey: TestHexPubkeys.alice,
      );
      await HeldShareFixture.insert(
        db,
        vaultId: fixture.vaultId,
        shareIndex: 0,
        payload: 'payload',
        distributionVersion: 1,
      );
      expect(await db.heldShareDao.forVault(fixture.vaultId), hasLength(1));

      await repository.clearAll();

      expect(await db.select(db.heldShares).get(), isEmpty);
      expect(await db.vaultDao.getById(fixture.vaultId), equals(null));
    });
  });
}
