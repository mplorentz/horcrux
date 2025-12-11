import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/screens/account_created_screen.dart';
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

  group('AccountCreatedScreen Golden Tests', () {
    setUp(() async {
      secureStorageMock.clear();
      SharedPreferences.setMockInitialValues({});
    });

    testGoldens('account created screen - default', (tester) async {
      const testNsec = 'nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5';

      final container = ProviderContainer();

      await pumpGoldenWidget(
        tester,
        const AccountCreatedScreen(nsec: testNsec),
        container: container,
        surfaceSize: const Size(375, 667), // iPhone SE size
      );

      await screenMatchesGolden(tester, 'account_created_screen_default');

      container.dispose();
    });

    testGoldens('account created screen - multiple device sizes', (
      tester,
    ) async {
      const testNsec = 'nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5';

      final container = ProviderContainer();

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: const AccountCreatedScreen(nsec: testNsec),
          name: 'account_created',
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
        'account_created_screen_multiple_devices',
      );

      container.dispose();
    });
  });
}
