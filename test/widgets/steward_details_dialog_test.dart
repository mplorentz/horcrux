import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/widgets/steward_details_dialog.dart';

void main() {
  group('StewardDetailsDialog', () {
    testWidgets('displays owner badge when isOwner is true', (tester) async {
      final pubkey = 'a' * 64;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StewardDetailsDialog(
              pubkey: pubkey,
              displayName: 'Test Owner',
              contactInfo: 'owner@example.com',
              isOwner: true,
              status: StewardStatus.holdingKey,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Test Owner'), findsOneWidget);
    });

    testWidgets('displays Nostr ID in npub format', (tester) async {
      final pubkey = 'a' * 64;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StewardDetailsDialog(
              pubkey: pubkey,
              displayName: 'Test User',
              contactInfo: 'test@example.com',
              isOwner: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should display Nostr ID label
      expect(find.text('Nostr ID'), findsOneWidget);
      // Should encode pubkey as npub (starts with npub1)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SelectableText && widget.data != null && widget.data!.startsWith('npub1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays contact information as selectable text', (tester) async {
      const contactInfo = 'contact@example.com';
      final pubkey = 'b' * 64;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StewardDetailsDialog(
              pubkey: pubkey,
              displayName: 'Test User',
              contactInfo: contactInfo,
              isOwner: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contact Information'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SelectableText && widget.data == contactInfo,
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays status when provided', (tester) async {
      final pubkey = 'c' * 64;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StewardDetailsDialog(
              pubkey: pubkey,
              displayName: 'Test User',
              contactInfo: 'test@example.com',
              isOwner: false,
              status: StewardStatus.invited,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Status'), findsOneWidget);
      expect(find.text(StewardStatus.invited.label), findsOneWidget);
    });

    testWidgets('displays no contact info message when not provided', (tester) async {
      final pubkey = 'd' * 64;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StewardDetailsDialog(
              pubkey: pubkey,
              displayName: 'Test User',
              contactInfo: null,
              isOwner: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Contact Information'), findsOneWidget);
      expect(find.text('No contact information provided.'), findsOneWidget);
    });

    testWidgets('close button dismisses dialog', (tester) async {
      final pubkey = 'e' * 64;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => StewardDetailsDialog(
                      pubkey: pubkey,
                      displayName: 'Test User',
                      isOwner: false,
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('Test User'), findsOneWidget);

      // Tap close button
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Test User'), findsNothing);
    });

    testWidgets('can be opened via show static method', (tester) async {
      final pubkey = 'f' * 64;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  StewardDetailsDialog.show(
                    context,
                    pubkey: pubkey,
                    displayName: 'Static Method User',
                    contactInfo: 'static@example.com',
                    isOwner: true,
                    status: StewardStatus.holdingKey,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog via static method
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Static Method User'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('static@example.com'), findsOneWidget);
    });
  });
}
