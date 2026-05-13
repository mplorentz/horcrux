import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/screens/vault_create_screen.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  group('VaultCreateScreen Golden Tests', () {
    testGoldens('empty state - no input', (tester) async {
      final harness = await pumpGoldenWidget(tester, const VaultCreateScreen());

      await screenMatchesGolden(tester, 'vault_create_screen_empty');

      await harness.dispose();
    });

    testGoldens('filled state - with content', (tester) async {
      final harness = await pumpGoldenWidget(tester, const VaultCreateScreen());

      // Fill in the name field (first TextFormField)
      await tester.enterText(
        find.byType(TextFormField).first,
        'My Private Keys',
      );

      // Fill in the content field (second TextFormField)
      await tester.enterText(
        find.byType(TextFormField).last,
        'This is my secret content that will be encrypted and stored securely.',
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'vault_create_screen_filled');

      await harness.dispose();
    });

    testGoldens('validation errors - empty name', (tester) async {
      final harness = await pumpGoldenWidget(tester, const VaultCreateScreen());

      // Tap the Next button without entering any data
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'vault_create_screen_validation_empty_name',
      );

      await harness.dispose();
    });

    testGoldens('validation errors - content too long', (tester) async {
      final harness = await pumpGoldenWidget(tester, const VaultCreateScreen());

      // Fill in the name field (first TextFormField)
      await tester.enterText(find.byType(TextFormField).first, 'Test Vault');

      // Fill in content that exceeds 4000 characters
      final longContent = 'a' * 4100;
      await tester.enterText(find.byType(TextFormField).last, longContent);

      await tester.pumpAndSettle();

      // Tap Next to trigger validation
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(
        tester,
        'vault_create_screen_validation_content_too_long',
      );

      await harness.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final harness = GoldenTestHarness.withOverrides(const []);

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(widget: const VaultCreateScreen(), name: 'empty');

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: harness.container,
        ),
      );

      await screenMatchesGolden(tester, 'vault_create_screen_multiple_devices');

      await harness.dispose();
    });

    testGoldens('filled content with character count', (tester) async {
      final harness = await pumpGoldenWidget(tester, const VaultCreateScreen());

      // Fill in the name field (first TextFormField)
      await tester.enterText(
        find.byType(TextFormField).first,
        'My Private Keys',
      );

      // Fill in content with a specific length to show character count
      final content = 'This is a test content. ' * 50; // ~1200 characters
      await tester.enterText(find.byType(TextFormField).last, content);

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'vault_create_screen_with_char_count');

      await harness.dispose();
    });
  });
}
