import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mockito/mockito.dart';
import 'package:horcrux/screens/consent_screen.dart';
import 'package:horcrux/services/horcrux_api_service.dart';
import '../helpers/golden_test_helpers.dart';

/// Mock that satisfies the [HorcruxApiService] interface for golden tests.
/// No methods are called during initial render of the onboarding consent
/// screen — the API is only read on Continue or in view-only mode.
class MockApiForGolden extends Mock implements HorcruxApiService {
  @override
  Future<void> acceptTermsOfService(int tosVersion) {
    return super.noSuchMethod(
          Invocation.method(#acceptTermsOfService, [tosVersion]),
        ) as Future<void>? ??
        Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    rootBundle.clear();
  });

  group('ConsentScreen Golden Tests', () {
    testGoldens('consent screen - onboarding mode', (tester) async {
      final mockApi = MockApiForGolden();

      final harness = await pumpGoldenWidget(
        tester,
        const ConsentScreen(),
        overrides: [horcruxApiServiceProvider.overrideWithValue(mockApi)],
        surfaceSize: const Size(375, 812), // iPhone X size
      );

      await screenMatchesGolden(tester, 'consent_screen_onboarding');

      await harness.dispose();
    });

    testGoldens('consent screen - view-only mode', (tester) async {
      final mockApi = MockApiForGolden();

      final harness = await pumpGoldenWidget(
        tester,
        const ConsentScreen(viewOnly: true),
        overrides: [horcruxApiServiceProvider.overrideWithValue(mockApi)],
        surfaceSize: const Size(375, 812), // iPhone X size
      );

      // View-only mode auto-accepts silently on load, then pops back.
      // The golden captures the transient state before auto-accept completes.
      // This is acceptable because the rendering is identical to the loading
      // state (no ConsentFormFields, no footer, just the ToS text).
      // The view-only screen is simple enough that a unit test covers it.
      await screenMatchesGolden(tester, 'consent_screen_view_only');

      await harness.dispose();
    });

    testGoldens('consent screen - multiple device sizes', (tester) async {
      final mockApi = MockApiForGolden();

      final harness = GoldenTestHarness.withOverrides([
        horcruxApiServiceProvider.overrideWithValue(mockApi),
      ]);

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: const ConsentScreen(),
          name: 'consent_screen',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: harness.container,
        ),
      );

      await screenMatchesGolden(tester, 'consent_screen_multiple_devices');

      await harness.dispose();
    });
  });
}
