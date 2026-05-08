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
        primeMod: 'prime-mod',
        creatorPubkey: TestHexPubkeys.alice,
        vaultId: fixture.vaultId,
        // Wrong units on purpose — hydration must derive seconds from the vault row.
        createdAt: createdAtMs,
      );

      await repository.addShareToVault(fixture.vaultId, share);

      final loaded = await repository.getVault(fixture.vaultId);
      expect(loaded, isNotNull);
      expect(loaded!.shares, hasLength(1));

      final expectedSeconds = createdAtMs ~/ 1000;
      expect(loaded.shares.single.createdAt, expectedSeconds);

      final json = shareToJson(loaded.shares.single);
      expect(json['created_at'], expectedSeconds);
    });

    test(
      'mergeVaultRowFromIncomingShare persists Shamir metadata when vault has '
      'no BackupConfig (steward bootstrap)',
      () async {
        const vaultId = 'bootstrap-steward-vault';

        await repository.addVault(
          Vault(
            id: vaultId,
            name: 'Stub',
            content: null,
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
          primeMod: 'prime-mod-bootstrap',
          creatorPubkey: TestHexPubkeys.alice,
          createdAt: 1704153600,
          vaultId: vaultId,
          distributionVersion: 3,
          nostrEventId: 'nostr-evt-bootstrap',
        );

        await repository.mergeVaultRowFromIncomingShare(vaultId, share);
        await repository.addShareToVault(vaultId, share);

        final loaded = await repository.getVault(vaultId);
        expect(loaded!.shares.single.isValid, isTrue);
        expect(loaded.shares.single.threshold, 2);
        expect(loaded.shares.single.totalShares, 4);
        expect(loaded.shares.single.primeMod, 'prime-mod-bootstrap');

        final json = shareToJson(loaded.shares.single);
        expect(json['threshold'], 2);
        expect(json['total_shards'], 4);
        expect(json['prime_mod'], 'prime-mod-bootstrap');
      },
    );

    test('mergeVaultRowFromIncomingShare ignores stale distribution_version', () async {
      const vaultId = 'stale-dist-vault';

      await repository.addVault(
        Vault(
          id: vaultId,
          name: 'V',
          content: null,
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
        primeMod: 'prime-good',
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
        primeMod: 'prime-bad',
        nostrEventId: 'evt-stale',
      );
      await repository.mergeVaultRowFromIncomingShare(vaultId, stale);

      final row = await db.vaultDao.getById(vaultId);
      expect(row!.threshold, 3);
      expect(row.totalShares, 5);
      expect(row.primeMod, 'prime-good');
      expect(row.currentDistributionVersion, 10);
    });
  });
}
