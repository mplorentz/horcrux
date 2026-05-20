import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  // VaultDetailList provider that emits immediately — simulating the real
  // case where vaults are already loaded when the user navigates here.
  final loadedVaultListOverride = vaultDetailListProvider.overrideWith(
    (ref) => Stream.value([]),
  );

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

  group('RelayManagementScreen', () {
    setUp(() async {
      secureStorageMock.clear();
      SharedPreferences.setMockInitialValues({
        relayConfigsKey: seededRelayJson,
      });
    });

    testWidgets('delete button is enabled when vault data is already loaded', (tester) async {
      final harness = GoldenTestHarness.withOverrides(
        [loadedVaultListOverride],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: goldenOverrides([loadedVaultListOverride]),
            child: const RelayManagementScreen(),
          ),
        ),
      );

      // Wait for relay loading to complete
      await tester.pumpAndSettle();

      // The close (X) buttons should have a non-null onPressed
      final closeButtons = find.byIcon(Icons.close);
      expect(closeButtons, findsOneWidget);

      // Pump a frame after find to ensure build() has run with listen
      await tester.pump();

      // Navigate up from Icon to IconButton
      final button = tester.widget<IconButton>(
        find.ancestor(of: find.byIcon(Icons.close), matching: find.byType(IconButton)).first,
      );
      expect(button.onPressed, isNotNull,
          reason: 'Delete buttons should be enabled when vault data is already loaded. '
              'If this fails, ref.listen is not firing for the initial provider value.');

      harness.container.dispose();
    });
  });
}
