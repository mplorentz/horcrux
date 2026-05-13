import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/screens/settings_screen.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Golden Tests', () {
    testGoldens('default state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const SettingsScreen(),
      );

      await screenMatchesGolden(tester, 'settings_screen_default');

      await harness.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final harness = GoldenTestHarness.withOverrides(const []);

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(widget: const SettingsScreen(), name: 'default');

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: harness.container,
        ),
      );

      await screenMatchesGolden(tester, 'settings_screen_multiple_devices');

      await harness.dispose();
    });
  });
}
