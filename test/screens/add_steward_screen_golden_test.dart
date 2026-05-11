import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/screens/add_steward_screen.dart';
import '../fixtures/test_keys.dart';
import '../helpers/golden_test_helpers.dart';
import '../helpers/steward_test_helpers.dart';

void main() {
  // Use test fixtures for consistent test data
  const testPubkey = TestHexPubkeys.alice;

  group('AddStewardScreen Golden Tests', () {
    testGoldens('add steward - empty state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const AddStewardScreen(
          relays: ['wss://relay.example.com'],
        ),
        useScaffold: true, // Modal bottom sheet needs Scaffold context
        surfaceSize: const Size(375, 800), // Taller for modal bottom sheet
      );

      await screenMatchesGolden(tester, 'add_steward_screen_empty');

      await harness.dispose();
    });

    testGoldens('add steward - no relays warning', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const AddStewardScreen(
          relays: [], // No relays
        ),
        useScaffold: true,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'add_steward_screen_no_relays');

      await harness.dispose();
    });

    testGoldens('edit steward - with name only', (tester) async {
      final steward = createTestSteward(
        pubkey: testPubkey,
        name: 'Alice',
        contactInfo: null,
      );

      final harness = await pumpGoldenWidget(
        tester,
        AddStewardScreen(
          steward: steward,
          relays: const ['wss://relay.example.com'],
        ),
        useScaffold: true,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'add_steward_screen_edit_name_only');

      await harness.dispose();
    });

    testGoldens('edit steward - with name and contact info', (tester) async {
      final steward = createTestSteward(
        pubkey: testPubkey,
        name: 'Alice',
        contactInfo: 'alice@example.com',
      );

      final harness = await pumpGoldenWidget(
        tester,
        AddStewardScreen(
          steward: steward,
          relays: const ['wss://relay.example.com'],
        ),
        useScaffold: true,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'add_steward_screen_edit');

      await harness.dispose();
    });

    testGoldens('edit steward - long contact info', (tester) async {
      final steward = createTestSteward(
        pubkey: testPubkey,
        name: 'Bob',
        contactInfo: 'bob@example.com\nPhone: +1-555-123-4567\nSignal: bob_signal',
      );

      final harness = await pumpGoldenWidget(
        tester,
        AddStewardScreen(
          steward: steward,
          relays: const ['wss://relay.example.com'],
        ),
        useScaffold: true,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'add_steward_screen_edit_long_contact');

      await harness.dispose();
    });

    testGoldens('edit steward - contact info near limit', (tester) async {
      // Create contact info close to the 500 character limit (but not exceeding)
      final longContactInfo = 'email: verylongemail@example.com\n'
          'phone: +1-555-123-4567\n'
          'signal: very_long_signal_username\n'
          'notes: '
          '${'x' * 420}'; // Fill to near limit (total should be < 500)

      final steward = createTestSteward(
        pubkey: testPubkey,
        name: 'Charlie',
        contactInfo: longContactInfo,
      );

      final harness = await pumpGoldenWidget(
        tester,
        AddStewardScreen(
          steward: steward,
          relays: const ['wss://relay.example.com'],
        ),
        useScaffold: true,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'add_steward_screen_edit_long_contact_limit');

      await harness.dispose();
    });
  });
}
