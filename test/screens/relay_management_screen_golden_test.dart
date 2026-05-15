import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
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

  group('RelayManagementScreen Golden Tests', () {
    setUp(() async {
      secureStorageMock.clear();
      SharedPreferences.setMockInitialValues({});
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
  });
}
