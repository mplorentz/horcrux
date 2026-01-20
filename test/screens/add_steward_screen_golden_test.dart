import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final container = ProviderContainer();

      await pumpGoldenWidget(
        tester,
        const AddStewardScreen(
          relays: ['wss://relay.example.com'],
        ),
        container: container,
        useScaffold: true, // Modal bottom sheet needs Scaffold context
        surfaceSize: const Size(375, 800), // Taller for modal bottom sheet
      );

      await screenMatchesGolden(tester, 'add_steward_screen_empty');

      container.dispose();
    });

    testGoldens('add steward - no relays warning', (tester) async {
      final container = ProviderContainer();

      await pumpGoldenWidget(
        tester,
        const AddStewardScreen(
          relays: [], // No relays
        ),
        container: container,
        useScaffold: true,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'add_steward_screen_no_relays');

      container.dispose();
    });

    testGoldens('edit steward - with name only', (tester) async {
      final container = ProviderContainer();
      final steward = createTestSteward(
        pubkey: testPubkey,
        name: 'Alice',
        contactInfo: null,
      );

      await pumpGoldenWidget(
        tester,
        AddStewardScreen(
          steward: steward,
          relays: const ['wss://relay.example.com'],
        ),
        container: container,
        useScaffold: true,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'add_steward_screen_edit_name_only');

      container.dispose();
    });

    testGoldens('edit steward - with name and contact info', (tester) async {
      final container = ProviderContainer();
      final steward = createTestSteward(
        pubkey: testPubkey,
        name: 'Alice',
        contactInfo: 'alice@example.com',
      );

      await pumpGoldenWidget(
        tester,
        AddStewardScreen(
          steward: steward,
          relays: const ['wss://relay.example.com'],
        ),
        container: container,
        useScaffold: true,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'add_steward_screen_edit');

      container.dispose();
    });

    testGoldens('edit steward - long contact info', (tester) async {
      final container = ProviderContainer();
      final steward = createTestSteward(
        pubkey: testPubkey,
        name: 'Bob',
        contactInfo: 'bob@example.com\nPhone: +1-555-123-4567\nSignal: bob_signal',
      );

      await pumpGoldenWidget(
        tester,
        AddStewardScreen(
          steward: steward,
          relays: const ['wss://relay.example.com'],
        ),
        container: container,
        useScaffold: true,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'add_steward_screen_edit_long_contact');

      container.dispose();
    });

    testGoldens('edit steward - contact info near limit', (tester) async {
      final container = ProviderContainer();
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

      await pumpGoldenWidget(
        tester,
        AddStewardScreen(
          steward: steward,
          relays: const ['wss://relay.example.com'],
        ),
        container: container,
        useScaffold: true,
        surfaceSize: const Size(375, 800),
      );

      await screenMatchesGolden(tester, 'add_steward_screen_edit_long_contact_limit');

      container.dispose();
    });
  });
}
