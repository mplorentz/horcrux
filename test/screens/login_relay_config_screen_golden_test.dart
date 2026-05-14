import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/screens/login_relay_config_screen.dart';
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

  group('LoginRelayConfigScreen Golden Tests', () {
    setUp(() async {
      secureStorageMock.clear();
      SharedPreferences.setMockInitialValues({});
    });

    testGoldens('editing state – default relay pre-populated', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const LoginRelayConfigScreen(
            nsec: 'nsec1test0000000000000000000000000000000000000000000000000000000001'),
        overrides: [emptyVaultListOverride],
        surfaceSize: const Size(375, 667),
      );

      await screenMatchesGolden(tester, 'login_relay_config_editing_default');

      await harness.dispose();
    });

    testGoldens('editing state – with extra relay added', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const LoginRelayConfigScreen(
            nsec: 'nsec1test0000000000000000000000000000000000000000000000000000000001'),
        overrides: [emptyVaultListOverride],
        surfaceSize: const Size(375, 667),
      );

      // Tap "Add Relay" to open dialog
      await tester.tap(find.text('Add Relay'));
      await tester.pumpAndSettle();

      // Type a relay URL
      await tester.enterText(
        find.byType(TextFormField),
        'wss://relay.damus.io',
      );
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'login_relay_config_editing_with_extra');

      await harness.dispose();
    });
  });
}
