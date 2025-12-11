import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/account_management_screen.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/logout_service.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountManagementScreen Golden Tests', () {
    testGoldens('default state', (tester) async {
      final keyPair = KeyPair(
        'a' * 64,
        'b' * 64,
        'nsec1exampleprivatekeyvalue',
        'npub1examplepublickeyvalue',
      );

      final fakeLoginService = _FakeLoginService(keyPair);

      final container = ProviderContainer(
        overrides: [
          loginServiceProvider.overrideWithValue(fakeLoginService),
          logoutServiceProvider.overrideWithValue(_FakeLogoutService()),
          currentPublicKeyProvider.overrideWith(
            (ref) async => keyPair.publicKey,
          ),
          currentPublicKeyBech32Provider.overrideWith(
            (ref) async => keyPair.publicKeyBech32,
          ),
          isLoggedInProvider.overrideWith((ref) async => true),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const AccountManagementScreen(),
        container: container,
        surfaceSize: const Size(375, 667),
      );

      await screenMatchesGolden(tester, 'account_management_screen_default');

      container.dispose();
    });
  });
}

class _FakeLoginService extends LoginService {
  _FakeLoginService(this._keyPair);

  final KeyPair _keyPair;

  @override
  Future<KeyPair?> getStoredNostrKey() async => _keyPair;
}

class _FakeLogoutService implements LogoutService {
  @override
  Future<void> logout() async {}
}
