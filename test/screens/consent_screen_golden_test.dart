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
        waitForSettle: false, // Don't pumpAndSettle — we need controlled pumps
      );

      // Pump once to flush the initial build.
      await tester.pump();

      // Pump a short duration to flush the async ToS load + auto-accept
      // (mock returns immediately). The auto-accept sets _viewOnlyAccepted = true
      // and then waits 600ms before popping. By pumping only 100ms, we capture
      // the screen WITH the "Terms accepted" banner visible, before the pop.
      await tester.pump(const Duration(milliseconds: 100));

      // Capture the golden — the ConsentScreen is still on the route with
      // the "Terms accepted" indicator visible.
      await expectLater(
        find.byType(ConsentScreen),
        matchesGoldenFile('goldens/consent_screen_view_only.png'),
        skip: GoldenToolkit.configuration.skipGoldenAssertion(),
      );

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
