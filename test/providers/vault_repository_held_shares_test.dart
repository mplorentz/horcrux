import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/share.dart';
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
  });
}
