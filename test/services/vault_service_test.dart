import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:horcrux/models/vault.dart';
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

  test(
    'add/get/update/delete vault persists via encrypted SharedPreferences',
    () async {
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
    },
  );
}
