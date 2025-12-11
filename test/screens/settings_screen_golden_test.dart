import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/screens/settings_screen.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Golden Tests', () {
    testGoldens('default state', (tester) async {
      final container = ProviderContainer();

      await pumpGoldenWidget(
        tester,
        const SettingsScreen(),
        container: container,
      );

      await screenMatchesGolden(tester, 'settings_screen_default');

      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final container = ProviderContainer();

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(widget: const SettingsScreen(), name: 'default');

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: container,
        ),
      );

      await screenMatchesGolden(tester, 'settings_screen_multiple_devices');

      container.dispose();
    });
  });
}
