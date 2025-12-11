import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/account_choice_screen.dart';
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

  group('AccountChoiceScreen Golden Tests', () {
    setUp(() async {
      secureStorageMock.clear();
      SharedPreferences.setMockInitialValues({});
    });

    testGoldens('account choice screen - default state', (tester) async {
      final loginService = LoginService();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();

      final container = ProviderContainer(
        overrides: [loginServiceProvider.overrideWithValue(loginService)],
      );

      await pumpGoldenWidget(
        tester,
        const AccountChoiceScreen(),
        container: container,
        surfaceSize: const Size(375, 667), // iPhone SE size
      );

      await screenMatchesGolden(tester, 'account_choice_screen_default');

      container.dispose();
    });

    testGoldens('account choice screen - multiple device sizes', (
      tester,
    ) async {
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
        ..addScenario(
          widget: const AccountChoiceScreen(),
          name: 'account_choice',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: container,
        ),
      );

      await screenMatchesGolden(
        tester,
        'account_choice_screen_multiple_devices',
      );

      container.dispose();
    });
  });
}
