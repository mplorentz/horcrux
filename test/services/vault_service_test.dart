import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/shard_data.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/providers/vault_provider.dart';
import '../helpers/secure_storage_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStorageMock = SecureStorageMock();

  setUpAll(() {
    secureStorageMock.setUpAll();
  });

  tearDownAll(() {
    secureStorageMock.tearDownAll();
  });

  setUp(() async {
    secureStorageMock.clear();
    SharedPreferences.setMockInitialValues({});

    final loginService = LoginService();
    await loginService.clearStoredKeys();
    loginService.resetCacheForTest();

    final repository = VaultRepository(loginService);
    await repository.clearAll();
  });

  tearDown(() async {
    final loginService = LoginService();
    final repository = VaultRepository(loginService);
    await repository.clearAll();
    await loginService.clearStoredKeys();
    loginService.resetCacheForTest();
  });

  test('add/get/update/delete vault persists via encrypted SharedPreferences', () async {
    // Initialize key so encrypt/decrypt works
    final loginService = LoginService();
    final keyPair = await loginService.generateAndStoreNostrKey();
    final ownerPubkey = keyPair.publicKey;

    // Create repository instance
    final repository = VaultRepository(loginService);

    // Start with empty list
    final startList = await repository.getAllVaults();
    expect(startList, isEmpty);

    final vault = Vault(
      id: 'abc',
      name: 'Secret',
      content: 'Top secret content',
      createdAt: DateTime(2024, 1, 1),
      ownerPubkey: ownerPubkey,
    );

    await repository.addVault(vault);

    // Verify ciphertext stored, not plaintext
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString('encrypted_vaults');
    expect(encrypted, isNotNull);
    expect(encrypted!.isNotEmpty, isTrue);
    expect(encrypted.contains('Top secret content'), isFalse);
    expect(encrypted.contains('Secret'), isFalse); // name is inside JSON

    // Now load and ensure we can read back decrypted content via service
    final listAfterAdd = await repository.getAllVaults();
    expect(listAfterAdd.length, 1);
    final fetched = await repository.getVault('abc');
    expect(fetched, isNotNull);
    expect(fetched!.name, 'Secret');
    expect(fetched.content, 'Top secret content');

    // Update
    await repository.updateVault('abc', 'Renamed', 'Still hidden');

    final fetched2 = await repository.getVault('abc');
    expect(fetched2, isNotNull);
    expect(fetched2!.name, 'Renamed');
    expect(fetched2.content, 'Still hidden');

    // Ensure on disk string does not contain plaintext after update
    final encrypted2 = prefs.getString('encrypted_vaults');
    expect(encrypted2, isNotNull);
    expect(encrypted2!.contains('Still hidden'), isFalse);
    expect(encrypted2.contains('Renamed'), isFalse);

    // Delete
    await repository.deleteVault('abc');
    final afterDelete = await repository.getVault('abc');
    expect(afterDelete, isNull);
  });

  // T028: Test that deleteVaultContent preserves shards and backup config
  group('deleteVaultContent', () {
    test('preserves shards when deleting content', () async {
      // Initialize key so encrypt/decrypt works
      final loginService = LoginService();
      final keyPair = await loginService.generateAndStoreNostrKey();
      final ownerPubkey = keyPair.publicKey;

      final repository = VaultRepository(loginService);

      // Create a shard for testing
      final testShard = createShardData(
        shard: 'encrypted-shard-content',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
        primeMod: 'test-prime-mod',
        creatorPubkey: ownerPubkey,
        vaultId: 'vault-with-shard',
        vaultName: 'Test Vault',
        distributionVersion: 1,
      );

      // Create vault with content and shards
      final vault = Vault(
        id: 'vault-with-shard',
        name: 'Test Vault',
        content: 'Secret content to delete',
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: ownerPubkey,
        shards: [testShard],
      );

      await repository.addVault(vault);

      // Verify initial state
      final beforeDelete = await repository.getVault('vault-with-shard');
      expect(beforeDelete, isNotNull);
      expect(beforeDelete!.content, 'Secret content to delete');
      expect(beforeDelete.shards.length, 1);
      expect(beforeDelete.shards.first.shard, 'encrypted-shard-content');

      // Delete content
      await repository.deleteVaultContent('vault-with-shard');

      // Verify content is deleted but shards are preserved
      final afterDelete = await repository.getVault('vault-with-shard');
      expect(afterDelete, isNotNull);
      expect(afterDelete!.content, isNull); // Content should be null
      expect(afterDelete.shards.length, 1); // Shard should still exist
      expect(afterDelete.shards.first.shard, 'encrypted-shard-content');
      expect(afterDelete.name, 'Test Vault'); // Name should be preserved
      expect(afterDelete.ownerPubkey, ownerPubkey); // Owner should be preserved
    });

    test('preserves backup config when deleting content', () async {
      // Initialize key so encrypt/decrypt works
      final loginService = LoginService();
      final keyPair = await loginService.generateAndStoreNostrKey();
      final ownerPubkey = keyPair.publicKey;

      final repository = VaultRepository(loginService);

      // Create backup config with owner steward
      final ownerSteward = createOwnerSteward(pubkey: ownerPubkey);
      final backupConfig = createBackupConfig(
        vaultId: 'vault-with-config',
        threshold: 1,
        totalKeys: 1,
        stewards: [ownerSteward],
        relays: ['wss://relay.example.com'],
      );

      // Create vault with content and backup config
      final vault = Vault(
        id: 'vault-with-config',
        name: 'Config Test Vault',
        content: 'Content to delete',
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: ownerPubkey,
        backupConfig: backupConfig,
      );

      await repository.addVault(vault);

      // Verify initial state
      final beforeDelete = await repository.getVault('vault-with-config');
      expect(beforeDelete, isNotNull);
      expect(beforeDelete!.content, 'Content to delete');
      expect(beforeDelete.backupConfig, isNotNull);
      expect(beforeDelete.backupConfig!.threshold, 1);

      // Delete content
      await repository.deleteVaultContent('vault-with-config');

      // Verify content is deleted but backup config is preserved
      final afterDelete = await repository.getVault('vault-with-config');
      expect(afterDelete, isNotNull);
      expect(afterDelete!.content, isNull);
      expect(afterDelete.backupConfig, isNotNull);
      expect(afterDelete.backupConfig!.threshold, 1);
      expect(afterDelete.backupConfig!.stewards.length, 1);
      expect(afterDelete.backupConfig!.stewards.first.isOwner, isTrue);
    });

    test('throws when vault not found', () async {
      final loginService = LoginService();
      await loginService.generateAndStoreNostrKey();

      final repository = VaultRepository(loginService);

      expect(
        () => repository.deleteVaultContent('non-existent-vault'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
