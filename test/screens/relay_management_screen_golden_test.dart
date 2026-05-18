import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/relay_configuration.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/screens/relay_management_screen.dart';
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

  final emptyVaultListOverride = vaultDetailListProvider.overrideWith(
    (ref) => Stream.value([]),
  );

  // A default relay fixture as it would be stored by RelayScanService.initialize().
  // The relay configs key matches RelayScanService._relayConfigsKey.
  const String relayConfigsKey = 'relay_configurations';
  final String seededRelayJson = json.encode([
    const RelayConfiguration(
      id: 'horcrux-default',
      url: 'wss://dev.horcruxbackup.com',
      name: 'Horcrux Relay',
      isEnabled: true,
      isTrusted: false,
    ).toJson(),
  ]);

  group('RelayManagementScreen Golden Tests', () {
    setUp(() async {
      secureStorageMock.clear();
      SharedPreferences.setMockInitialValues({
        relayConfigsKey: seededRelayJson,
      });
    });

    testGoldens('editing state – relays loaded', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const RelayManagementScreen(),
        overrides: [emptyVaultListOverride],
        surfaceSize: const Size(375, 667),
      );

      await screenMatchesGolden(tester, 'relay_management_editing_default');

      await harness.dispose();
    });

    testGoldens('editing state – with extra relay added', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const RelayManagementScreen(),
        overrides: [emptyVaultListOverride],
        surfaceSize: const Size(375, 667),
      );

      await tester.tap(find.text('Add Relay'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        'wss://relay.damus.io',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'relay_management_editing_with_extra');

      // Success toast schedules a 2s auto-dismiss timer; flush before dispose.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await harness.dispose();
    });

    testGoldens('scanning state - Cancel button visible', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const RelayManagementScreen(),
        overrides: [emptyVaultListOverride],
        surfaceSize: const Size(375, 667),
      );

      // Wait for relay loading to complete
      await tester.pumpAndSettle();

      // Tap "Scan for Vaults" to enter scanning state
      await tester.tap(find.text('Scan for Vaults'));

      // Pump a few frames so the widget settles into scanning layout
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await screenMatchesGolden(tester, 'relay_management_scanning');

      // Flush pending timers before dispose.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await harness.dispose();
    });

    testGoldens('results state - Go Back button visible', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const RelayManagementScreen(),
        overrides: [emptyVaultListOverride],
        surfaceSize: const Size(375, 667),
      );

      // Wait for relay loading to complete
      await tester.pumpAndSettle();

      // Tap "Scan for Vaults" to enter scanning state
      await tester.tap(find.text('Scan for Vaults'));

      // Advance the 10-second progress timer to completion so we reach results state.
      // The timer fires every 100ms; pumping by 11s guarantees the transition.
      await tester.pump(const Duration(seconds: 11));

      await screenMatchesGolden(tester, 'relay_management_results');

      // Flush pending timers before dispose.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await harness.dispose();
    });
  });
}
