import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/onboarding_screen.dart';
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

  group('OnboardingScreen Golden Tests', () {
    setUp(() async {
      secureStorageMock.clear();
      SharedPreferences.setMockInitialValues({});
    });

    testGoldens('onboarding screen - default state', (tester) async {
      // Create a LoginService with no stored key (user not logged in)
      final loginService = LoginService();
      await loginService.clearStoredKeys();
      LoginService.resetCache();

      // Only override loginServiceProvider - other providers won't be accessed
      // during build, only when "Get Started" button is pressed
      final harness = await pumpGoldenWidget(
        tester,
        const OnboardingScreen(),
        overrides: [loginServiceProvider.overrideWithValue(loginService)],
        surfaceSize: const Size(375, 667), // iPhone SE size
      );

      await screenMatchesGolden(tester, 'onboarding_screen_default');

      await harness.dispose();
    });

    testGoldens('onboarding screen - multiple device sizes', (tester) async {
      // Create a LoginService with no stored key (user not logged in)
      final loginService = LoginService();
      await loginService.clearStoredKeys();
      LoginService.resetCache();

      final harness = GoldenTestHarness.withOverrides([
        loginServiceProvider.overrideWithValue(loginService),
      ]);

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(widget: const OnboardingScreen(), name: 'onboarding');

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: harness.container,
        ),
      );

      await screenMatchesGolden(tester, 'onboarding_screen_multiple_devices');

      await harness.dispose();
    });
  });
}
