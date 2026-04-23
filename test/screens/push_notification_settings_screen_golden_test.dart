import 'package:flutter/material.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/screens/push_notification_settings_screen.dart';
import 'package:horcrux/services/horcrux_notification_service.dart';
import 'package:horcrux/services/push_notification_receiver.dart';
import 'package:mockito/mockito.dart';

import '../helpers/golden_test_helpers.dart';
import '../services/vault_share_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Surface tall enough for global toggle and server URL section.
  const surface = Size(375, 700);

  List<Override> buildOverrides({
    required MockPushNotificationReceiver mockPush,
    required MockHorcruxNotificationService mockNotifier,
    required bool optedIn,
  }) {
    when(mockPush.isOptedIn()).thenAnswer((_) async => optedIn);
    when(mockNotifier.getBaseUrl())
        .thenAnswer((_) async => HorcruxNotificationService.defaultBaseUrl);

    return [
      pushNotificationReceiverProvider.overrideWith((ref) => mockPush),
      horcruxNotificationServiceProvider.overrideWith((ref) => mockNotifier),
    ];
  }

  group('PushNotificationSettingsScreen golden tests', () {
    testGoldens('default: push off, default notifier URL', (tester) async {
      final mockPush = MockPushNotificationReceiver();
      final mockNotifier = MockHorcruxNotificationService();
      final container = ProviderContainer(
        overrides: buildOverrides(
          mockPush: mockPush,
          mockNotifier: mockNotifier,
          optedIn: false,
        ),
      );

      await pumpGoldenWidget(
        tester,
        const PushNotificationSettingsScreen(),
        container: container,
        surfaceSize: surface,
      );

      await screenMatchesGolden(tester, 'push_notification_settings_screen_default');
      container.dispose();
    });

    testGoldens('opted in: global push on', (tester) async {
      final mockPush = MockPushNotificationReceiver();
      final mockNotifier = MockHorcruxNotificationService();
      final container = ProviderContainer(
        overrides: buildOverrides(
          mockPush: mockPush,
          mockNotifier: mockNotifier,
          optedIn: true,
        ),
      );

      await pumpGoldenWidget(
        tester,
        const PushNotificationSettingsScreen(),
        container: container,
        surfaceSize: surface,
      );

      await screenMatchesGolden(tester, 'push_notification_settings_screen_opted_in');
      container.dispose();
    });

    testGoldens('multiple device sizes (default state)', (tester) async {
      final mockPush = MockPushNotificationReceiver();
      final mockNotifier = MockHorcruxNotificationService();
      final container = ProviderContainer(
        overrides: buildOverrides(
          mockPush: mockPush,
          mockNotifier: mockNotifier,
          optedIn: false,
        ),
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: const PushNotificationSettingsScreen(),
          name: 'default',
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
        'push_notification_settings_screen_multiple_devices',
      );
      container.dispose();
    });
  });
}
