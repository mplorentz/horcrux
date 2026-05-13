import 'package:flutter_test/flutter_test.dart';

import 'package:horcrux/database/app_database.dart';

import '../helpers/test_database.dart';

void main() {
  group('AppDatabase (in-memory, no SQLCipher)', () {
    late AppDatabase db;

    setUp(() {
      db = newTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('opens at schema version 5', () {
      expect(db.schemaVersion, 5);
    });

    test('VaultFixture.owned inserts vault + owned_vaults rows', () async {
      final f = await VaultFixture.owned(
        db,
        ownerPubkey: 'a' * 64,
        threshold: 2,
        totalShares: 3,
      );
      final vault = await db.vaultDao.getById(f.vaultId);
      expect(vault, isNotNull);
      expect(vault!.threshold, 2);
      expect(vault.totalShares, 3);

      final owned = await db.ownedVaultDao.getByVaultId(f.vaultId);
      expect(owned, isNotNull);
      expect(owned!.content, 'placeholder-ciphertext');
    });

    test('partial unique index allows replacement at same share index', () async {
      final f = await VaultFixture.owned(
        db,
        ownerPubkey: 'a' * 64,
      );
      await f.withSteward(shareIndex: 1, pubkey: 'b' * 64, name: 'Old');
      await db.stewardDao.replaceAtPosition(
        vaultId: f.vaultId,
        shareIndex: 1,
        leftAt: DateTime.now().millisecondsSinceEpoch,
        removalReason: 'rotated',
        replacement: StewardsCompanion.insert(
          id: 'replacement-1',
          vaultId: f.vaultId,
          shareIndex: 1,
          joinedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final active = await db.stewardDao.activeForVault(f.vaultId);
      expect(active, hasLength(1));
      expect(active.single.id, 'replacement-1');

      final history = await db.stewardDao.historyForVaultPosition(
        vaultId: f.vaultId,
        shareIndex: 1,
      );
      expect(history, hasLength(2));
    });
  });
}
