import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:horcrux/services/login_service.dart';
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
    LoginService.resetCache();
  });

  tearDown(() async {
    final loginService = LoginService();
    await loginService.clearStoredKeys();
    LoginService.resetCache();
  });

  test(
    'generateAndStoreNostrKey persists private key and can reload it',
    () async {
      final loginService = LoginService();

      // Generate and store
      final keyPair1 = await loginService.generateAndStoreNostrKey();
      expect(keyPair1.privateKey, isNotNull);
      expect(keyPair1.publicKey, isNotNull);

      // Ensure underlying secure storage contains the value
      // The service uses 'nostr_private_key' as the key
      expect(secureStorageMock.store.containsKey('nostr_private_key'), isTrue);
      expect(secureStorageMock.store['nostr_private_key']!.isNotEmpty, isTrue);

      // Reset cache to force a storage read path
      LoginService.resetCache();

      final keyPair2 = await loginService.getStoredNostrKey();
      expect(keyPair2, isNotNull);
      expect(keyPair2!.publicKey, equals(keyPair1.publicKey));
      expect(keyPair2.privateKey, equals(keyPair1.privateKey));
    },
  );
}
