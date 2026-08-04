import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/account_management_screen.dart';
import 'package:horcrux/services/deep_link_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/logout_service.dart';
import 'package:horcrux/widgets/theme.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'account_management_screen_test.mocks.dart';

/// Regression coverage for horcrux_app-gqvi: logging out invalidates
/// [deepLinkServiceProvider] (to drop the closed-database-bound instance),
/// but nothing used to restart deep link handling afterward. That left the
/// onboarding session that follows logout with a dead `app_links` listener —
/// an invitation link tapped there was silently dropped until the user
/// created a new account. [initializePreLoginDeepLinking] fixes this; these
/// tests fail if that call is ever removed from `_handleLogout`.
@GenerateNiceMocks([
  MockSpec<DeepLinkService>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final keyPair = KeyPair(
    'a' * 64,
    'b' * 64,
    'nsec1exampleprivatekeyvalue',
    'npub1examplepublickeyvalue',
  );

  late MockDeepLinkService deepLinkService;

  setUp(() {
    deepLinkService = MockDeepLinkService();
    when(deepLinkService.initializeDeepLinking()).thenAnswer((_) async {});
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        loginServiceProvider.overrideWithValue(_FakeLoginService(keyPair)),
        logoutServiceProvider.overrideWithValue(_FakeLogoutService()),
        currentPublicKeyProvider.overrideWith((ref) async => keyPair.publicKey),
        currentPublicKeyBech32Provider.overrideWith((ref) async => keyPair.publicKeyBech32),
        isLoggedInProvider.overrideWith((ref) async => true),
        deepLinkServiceProvider.overrideWithValue(deepLinkService),
      ],
      child: MaterialApp(
        theme: horcrux3Dark,
        home: const AccountManagementScreen(),
      ),
    );
  }

  testWidgets(
    'logging out restarts deep link handling (navigator key + live listener)',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Confirm the "Logging out will delete..." dialog.
      await tester.tap(find.text('My key is backed up'));
      await tester.pumpAndSettle();

      verify(deepLinkService.setNavigatorKey(any)).called(1);
      verify(deepLinkService.initializeDeepLinking()).called(1);

      // Let the "Logged out..." toast's auto-dismiss timer fire so no
      // pending Timer trips the test framework's teardown assertion.
      await tester.pump(const Duration(seconds: 3));
    },
  );

  testWidgets(
    'canceling the logout dialog does not restart deep link handling',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(deepLinkService.initializeDeepLinking());
    },
  );
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

  @override
  Future<void> resetDatabase() async {}
}
