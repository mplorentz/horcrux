import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/widgets/steward_details_dialog.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  group('StewardDetailsDialog Golden Tests', () {
    testGoldens('owner steward with contact info', (tester) async {
      final pubkey = 'a' * 64; // 64-char hex pubkey

      await pumpGoldenWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => StewardDetailsDialog(
                  pubkey: pubkey,
                  displayName: 'Alice',
                  contactInfo: 'alice@example.com',
                  isOwner: true,
                ),
              );
            },
            child: const Text('Show Dialog'),
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'steward_details_dialog_owner_with_contact');
    });

    testGoldens('non-owner steward with contact info', (tester) async {
      final pubkey = 'b' * 64;

      await pumpGoldenWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => StewardDetailsDialog(
                  pubkey: pubkey,
                  displayName: 'Bob',
                  contactInfo: 'bob@example.com',
                  isOwner: false,
                ),
              );
            },
            child: const Text('Show Dialog'),
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'steward_details_dialog_steward_with_contact');
    });

    testGoldens('steward without contact info', (tester) async {
      final pubkey = 'c' * 64;

      await pumpGoldenWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => StewardDetailsDialog(
                  pubkey: pubkey,
                  displayName: 'Charlie',
                  contactInfo: null,
                  isOwner: false,
                ),
              );
            },
            child: const Text('Show Dialog'),
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'steward_details_dialog_no_contact');
    });

    testGoldens('steward with long contact info', (tester) async {
      final pubkey = 'd' * 64;
      const longContactInfo =
          '''This is a very long contact information field that spans multiple lines.
It contains important details about how to reach this steward.
You can contact them via email, phone, or other methods.
Please use this information responsibly.''';

      await pumpGoldenWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => StewardDetailsDialog(
                  pubkey: pubkey,
                  displayName: 'Diana',
                  contactInfo: longContactInfo,
                  isOwner: false,
                ),
              );
            },
            child: const Text('Show Dialog'),
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'steward_details_dialog_long_contact');
    });

    testGoldens('steward with no display name', (tester) async {
      final pubkey = 'e' * 64;

      await pumpGoldenWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => StewardDetailsDialog(
                  pubkey: pubkey,
                  displayName: null,
                  contactInfo: 'contact@example.com',
                  isOwner: false,
                ),
              );
            },
            child: const Text('Show Dialog'),
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'steward_details_dialog_no_display_name');
    });

    testGoldens('owner without contact info', (tester) async {
      final pubkey = 'f' * 64;

      await pumpGoldenWidget(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => StewardDetailsDialog(
                  pubkey: pubkey,
                  displayName: 'Frank',
                  contactInfo: null,
                  isOwner: true,
                ),
              );
            },
            child: const Text('Show Dialog'),
          ),
        ),
        surfaceSize: const Size(375, 667),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'steward_details_dialog_owner_no_contact');
    });
  });
}
