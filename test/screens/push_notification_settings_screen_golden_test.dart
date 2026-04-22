import 'package:flutter/material.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/screens/push_notification_settings_screen.dart';
import 'package:horcrux/services/horcrux_notification_service.dart';
import 'package:horcrux/services/push_notification_receiver.dart';
import 'package:mockito/mockito.dart';

import '../helpers/golden_test_helpers.dart';
import '../services/vault_share_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testPubkey = 'a' * 64;
  final otherPubkey = 'b' * 64;

  /// Tall enough to include global toggle, server URL, and a short vault list
  /// without mid-scroll capture.
  const surface = Size(375, 1000);

  List<Override> buildOverrides({
    required MockPushNotificationReceiver mockPush,
    required MockHorcruxNotificationService mockNotifier,
    required bool optedIn,
    required List<Vault> vaults,
  }) {
    when(mockPush.isOptedIn()).thenAnswer((_) async => optedIn);
    when(mockNotifier.getBaseUrl())
        .thenAnswer((_) async => HorcruxNotificationService.defaultBaseUrl);

    return [
      pushNotificationReceiverProvider.overrideWith((ref) => mockPush),
      horcruxNotificationServiceProvider.overrideWith((ref) => mockNotifier),
      vaultListProvider.overrideWith((ref) => Stream.value(vaults)),
      currentPublicKeyProvider.overrideWith((ref) => testPubkey),
    ];
  }

  final ownedOn = Vault(
    id: 'v-push-on',
    name: 'Family Photos',
    content: 'x',
    createdAt: DateTime(2024, 6, 1, 9),
    ownerPubkey: testPubkey,
    shards: [],
    pushEnabled: true,
  );

  final ownedOff = Vault(
    id: 'v-push-off',
    name: 'Work Notes',
    content: 'y',
    createdAt: DateTime(2024, 5, 15, 14),
    ownerPubkey: testPubkey,
    shards: [],
    pushEnabled: false,
  );

  final stewardOnly = Vault(
    id: 'v-other',
    name: "Alice's Vault",
    content: null,
    createdAt: DateTime(2024, 4, 1),
    ownerPubkey: otherPubkey,
    shards: [],
    pushEnabled: true,
  );

  group('PushNotificationSettingsScreen golden tests', () {
    testGoldens('default: push off, two owned vaults, default notifier URL', (tester) async {
      final mockPush = MockPushNotificationReceiver();
      final mockNotifier = MockHorcruxNotificationService();
      final container = ProviderContainer(
        overrides: buildOverrides(
          mockPush: mockPush,
          mockNotifier: mockNotifier,
          optedIn: false,
          vaults: [ownedOn, ownedOff],
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
          vaults: [ownedOn, ownedOff],
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

    testGoldens('no owned vaults', (tester) async {
      final mockPush = MockPushNotificationReceiver();
      final mockNotifier = MockHorcruxNotificationService();
      final container = ProviderContainer(
        overrides: buildOverrides(
          mockPush: mockPush,
          mockNotifier: mockNotifier,
          optedIn: false,
          vaults: [stewardOnly],
        ),
      );

      await pumpGoldenWidget(
        tester,
        const PushNotificationSettingsScreen(),
        container: container,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(
        tester,
        'push_notification_settings_screen_no_owned',
      );
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
          vaults: [ownedOn, ownedOff],
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
