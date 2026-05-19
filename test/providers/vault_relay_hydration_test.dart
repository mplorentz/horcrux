import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/login_service.dart';

import '../helpers/test_database.dart';

class _MockLoginService extends Mock implements LoginService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ownerPubkey = 'a0a1ffb8761b974cec4a3be8cbcb2e96a7090dcf465ffeac839aa4ca20c9a59e';

  group('VaultRepository relay hydration', () {
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

    // ---------------------------------------------------------------------------
    // Test 1: _hydrate only returns owner-role relay URLs
    // ---------------------------------------------------------------------------
    test('_hydrate excludes steward-role relays from backup config', () async {
      // Arrange: insert vault with relays [A, B] as owner and [A, B, C] as steward.
      const vaultId = 'vault-relay-hydrate-1';
      final vault = Vault(
        id: vaultId,
        name: 'Relay Hydrate Test',
        createdAt: DateTime.utc(2026, 5, 18),
        ownerPubkey: ownerPubkey,
      );
      await repository.addVault(vault);

      // Insert owner-role relays [A, B]
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-owner-a',
            vaultId: vaultId,
            url: 'wss://relay-a.example.com',
            role: 'owner',
            addedAt: DateTime.now().millisecondsSinceEpoch,
          ));
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-owner-b',
            vaultId: vaultId,
            url: 'wss://relay-b.example.com',
            role: 'owner',
            addedAt: DateTime.now().millisecondsSinceEpoch,
          ));

      // Insert steward-role relays [A, B, C] (simulates mergeVaultRowFromIncomingShare)
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-a',
            vaultId: vaultId,
            url: 'wss://relay-a.example.com',
            role: 'steward',
            addedAt: DateTime.now().millisecondsSinceEpoch,
          ));
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-b',
            vaultId: vaultId,
            url: 'wss://relay-b.example.com',
            role: 'steward',
            addedAt: DateTime.now().millisecondsSinceEpoch,
          ));
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-c',
            vaultId: vaultId,
            url: 'wss://relay-c.example.com',
            role: 'steward',
            addedAt: DateTime.now().millisecondsSinceEpoch,
          ));

      // Act: persist a backup config with only relays [A, B] as owner
      final steward = createSteward(pubkey: 'b' * 64, name: 'Steward');
      final config = createBackupConfig(
        vaultId: vaultId,
        threshold: 1,
        totalKeys: 1,
        stewards: [steward],
        relays: const ['wss://relay-a.example.com', 'wss://relay-b.example.com'],
      );
      await repository.updateBackupConfig(vaultId, config);

      // Assert: hydrated config should have only [A, B], not C
      final loaded = await repository.getVault(vaultId);
      final hydratedConfig = loaded!.backupConfig;
      expect(hydratedConfig, isNotNull);
      expect(hydratedConfig!.relays, hasLength(2));
      expect(hydratedConfig.relays, contains('wss://relay-a.example.com'));
      expect(hydratedConfig.relays, contains('wss://relay-b.example.com'));
      expect(hydratedConfig.relays, isNot(contains('wss://relay-c.example.com')));

      // Verify that steward-role rows still exist in the DB (they're just not surfaced)
      final allRelays = await db.vaultRelayDao.forVault(vaultId);
      expect(allRelays, hasLength(5), reason: 'steward-role rows should remain in the DB');
    });

    // ---------------------------------------------------------------------------
    // Test 2: removed relay does not reappear after updateBackupConfig
    // ---------------------------------------------------------------------------
    test('removed relay does not reappear after updateBackupConfig', () async {
      // Arrange: vault with relays [A, B, C] as both owner and steward rows.
      const vaultId = 'vault-relay-hydrate-2';
      final steward = createSteward(pubkey: 'b' * 64, name: 'Steward');
      final configWithC = createBackupConfig(
        vaultId: vaultId,
        threshold: 1,
        totalKeys: 1,
        stewards: [steward],
        relays: const [
          'wss://relay-a.example.com',
          'wss://relay-b.example.com',
          'wss://relay-c.example.com',
        ],
      );
      await repository.addVault(
        Vault(
          id: vaultId,
          name: 'Relay Remove Test',
          createdAt: DateTime.utc(2026, 5, 18),
          ownerPubkey: ownerPubkey,
          backupConfig: configWithC,
        ),
      );

      // Also insert steward-role rows for [A, B, C] (as mergeVaultRowFromIncomingShare would)
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-c',
            vaultId: vaultId,
            url: 'wss://relay-c.example.com',
            role: 'steward',
            addedAt: DateTime.now().millisecondsSinceEpoch,
          ));

      // Act: user removes relay C and saves
      final configWithoutC = createBackupConfig(
        vaultId: vaultId,
        threshold: 1,
        totalKeys: 1,
        stewards: [steward],
        relays: const [
          'wss://relay-a.example.com',
          'wss://relay-b.example.com',
        ],
      );
      await repository.updateBackupConfig(vaultId, configWithoutC);

      // Assert: C should not reappear
      final loaded = await repository.getVault(vaultId);
      final hydratedConfig = loaded!.backupConfig;
      expect(hydratedConfig, isNotNull);
      expect(hydratedConfig!.relays, hasLength(2));
      expect(hydratedConfig.relays, contains('wss://relay-a.example.com'));
      expect(hydratedConfig.relays, contains('wss://relay-b.example.com'));
      expect(hydratedConfig.relays, isNot(contains('wss://relay-c.example.com')));
    });

    // ---------------------------------------------------------------------------
    // Test 3: re-read-and-save cycle does not reintroduce removed relays
    // ---------------------------------------------------------------------------
    test('re-read-and-save cycle does not reintroduce removed relays from steward rows', () async {
      // Arrange: vault with relays [A, B, C], distribution already done
      // (steward rows exist).
      const vaultId = 'vault-relay-hydrate-3';
      final steward = createSteward(pubkey: 'b' * 64, name: 'Steward');
      final configWithC = createBackupConfig(
        vaultId: vaultId,
        threshold: 1,
        totalKeys: 1,
        stewards: [steward],
        relays: const [
          'wss://relay-a.example.com',
          'wss://relay-b.example.com',
          'wss://relay-c.example.com',
        ],
      );
      await repository.addVault(
        Vault(
          id: vaultId,
          name: 'Re-read Cycle Test',
          createdAt: DateTime.utc(2026, 5, 18),
          ownerPubkey: ownerPubkey,
          backupConfig: configWithC,
        ),
      );

      // Insert steward-role rows (simulates distribution/message processing)
      await db.into(db.vaultRelays).insert(VaultRelaysCompanion.insert(
            id: '$vaultId-steward-c',
            vaultId: vaultId,
            url: 'wss://relay-c.example.com',
            role: 'steward',
            addedAt: DateTime.now().millisecondsSinceEpoch,
          ));

      // Simulate: user removes relay C and saves
      final configWithoutC = createBackupConfig(
        vaultId: vaultId,
        threshold: 1,
        totalKeys: 1,
        stewards: [steward],
        relays: const [
          'wss://relay-a.example.com',
          'wss://relay-b.example.com',
        ],
      );
      await repository.updateBackupConfig(vaultId, configWithoutC);

      // Act: simulate createAndDistributeBackup step 7 re-read-and-save cycle
      final reReadConfig = await repository.getBackupConfig(vaultId);
      expect(reReadConfig, isNotNull);
      await repository.updateBackupConfig(vaultId, reReadConfig!);

      // Assert: C should still be gone
      final loaded = await repository.getVault(vaultId);
      final hydratedConfig = loaded!.backupConfig;
      expect(hydratedConfig, isNotNull);
      expect(hydratedConfig!.relays, hasLength(2));
      expect(hydratedConfig.relays, contains('wss://relay-a.example.com'));
      expect(hydratedConfig.relays, contains('wss://relay-b.example.com'));
      expect(hydratedConfig.relays, isNot(contains('wss://relay-c.example.com')));
    });
  });
}
