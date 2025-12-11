import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/login_screen.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/golden_test_helpers.dart';
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

  group('LoginScreen Golden Tests', () {
    setUp(() async {
      secureStorageMock.clear();
      SharedPreferences.setMockInitialValues({});
    });

    testGoldens('login screen - empty state', (tester) async {
      final loginService = LoginService();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();

      final container = ProviderContainer(
        overrides: [loginServiceProvider.overrideWithValue(loginService)],
      );

      await pumpGoldenWidget(
        tester,
        const LoginScreen(),
        container: container,
        surfaceSize: const Size(375, 667), // iPhone SE size
      );

      await screenMatchesGolden(tester, 'login_screen_empty');

      container.dispose();
    });

    testGoldens('login screen - with error text', (tester) async {
      final loginService = LoginService();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();

      final container = ProviderContainer(
        overrides: [loginServiceProvider.overrideWithValue(loginService)],
      );

      await pumpGoldenWidget(
        tester,
        const LoginScreen(),
        container: container,
        surfaceSize: const Size(375, 667), // iPhone SE size
      );

      // Enter invalid text to trigger error
      await tester.enterText(find.byType(TextField), 'invalid_key');
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'login_screen_with_error');

      container.dispose();
    });

    testGoldens('login screen - multiple device sizes', (tester) async {
      final loginService = LoginService();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();

      final container = ProviderContainer(
        overrides: [loginServiceProvider.overrideWithValue(loginService)],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(widget: const LoginScreen(), name: 'login_empty');

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: container,
        ),
      );

      await screenMatchesGolden(tester, 'login_screen_multiple_devices');

      container.dispose();
    });
  });
}
