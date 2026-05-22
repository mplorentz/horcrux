import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/screens/feedback_screen.dart';
import 'package:horcrux/services/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeedbackScreen', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWith((ref) => _FakeFeedbackService()),
          ],
          child: const MaterialApp(home: FeedbackScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar
      expect(find.text('Feedback'), findsOneWidget);

      // Verify info text
      expect(
        find.textContaining('Have feedback'),
        findsOneWidget,
      );

      // Verify email field
      expect(find.text('Email (optional)'), findsOneWidget);

      // Verify message field
      expect(find.text('Message'), findsOneWidget);

      // Verify diagnostics toggle
      expect(find.text('Include app diagnostics'), findsOneWidget);
      expect(find.textContaining('Appends version, OS, and recent logs'), findsOneWidget);

      // Verify submit button
      expect(find.text('Send Feedback'), findsOneWidget);

      // Verify diagnostics toggle defaults to ON
      final switchWidget = find.byType(Switch);
      expect(switchWidget, findsOneWidget);
      final switchElement = tester.widget<Switch>(switchWidget);
      expect(switchElement.value, isTrue);
    });

    testWidgets('message field is required', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWith((ref) => _FakeFeedbackService()),
          ],
          child: const MaterialApp(home: FeedbackScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Tap submit without entering a message
      await tester.tap(find.text('Send Feedback'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a message'), findsOneWidget);
    });

    testWidgets('can enter email and message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWith((ref) => _FakeFeedbackService()),
          ],
          child: const MaterialApp(home: FeedbackScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Enter email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email (optional)'),
        'test@example.com',
      );

      // Enter message
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Message'),
        'This is my feedback',
      );

      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('This is my feedback'), findsOneWidget);
    });

    testWidgets('diagnostics toggle can be toggled off', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWith((ref) => _FakeFeedbackService()),
          ],
          child: const MaterialApp(home: FeedbackScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Find and toggle the switch
      final switchWidget = find.byType(Switch);
      expect(tester.widget<Switch>(switchWidget).value, isTrue);

      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchWidget).value, isFalse);
    });

    testWidgets('submit button completes submission flow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWith(
              (ref) => _FakeFeedbackService(shouldSucceed: true),
            ),
          ],
          child: const MaterialApp(home: FeedbackScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Enter a message
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Message'),
        'Test feedback',
      );

      // Submit — fake service succeeds instantly, screen pops
      await tester.tap(find.text('Send Feedback'));
      await tester.pump(); // Show toast
      // Verify snackbar appears before auto-dismiss
      expect(find.textContaining('Feedback sent'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 5)); // Let toast dismiss
    });

    testWidgets('successful submission shows success snackbar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWith(
              (ref) => _FakeFeedbackService(shouldSucceed: true),
            ),
          ],
          child: const MaterialApp(home: FeedbackScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Enter a message and submit
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Message'),
        'Great app!',
      );

      await tester.tap(find.text('Send Feedback'));
      await tester.pump(); // Show toast
      expect(find.textContaining('Feedback sent'), findsOneWidget);
      // Pump enough for the auto-dismiss timer to fire
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('failed submission shows error snackbar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWith(
              (ref) => _FakeFeedbackService(shouldSucceed: false),
            ),
          ],
          child: const MaterialApp(home: FeedbackScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Enter a message and submit
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Message'),
        'Great app!',
      );

      await tester.tap(find.text('Send Feedback'));
      await tester.pump(); // Show toast
      expect(find.textContaining('Failed to send'), findsOneWidget);
      // Let auto-dismiss timer fire
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}

/// A fake FeedbackService that returns a configurable result.
class _FakeFeedbackService extends FeedbackService {
  final bool shouldSucceed;

  _FakeFeedbackService({this.shouldSucceed = true}) : super(formspreeFormId: 'fake');

  @override
  Future<bool> submitFeedback({
    required String message,
    String email = '',
    bool includeDiagnostics = true,
  }) async {
    return shouldSucceed;
  }
}
