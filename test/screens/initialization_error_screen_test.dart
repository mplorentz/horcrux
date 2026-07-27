import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/screens/feedback_screen.dart';
import 'package:horcrux/screens/initialization_error_screen.dart';
import 'package:horcrux/services/feedback_service.dart';
import 'package:horcrux/widgets/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InitializationErrorScreen', () {
    testWidgets('shows error and actions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWith(
              (ref) => _FakeFeedbackService(),
            ),
          ],
          child: MaterialApp(
            theme: horcrux3Dark,
            home: const InitializationErrorScreen(
              error: 'SQLiteException: database is locked',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Initialization Failed'), findsOneWidget);
      expect(find.text('SQLiteException: database is locked'), findsOneWidget);
      expect(find.text('Send Feedback'), findsOneWidget);
      expect(find.text('Restart App'), findsOneWidget);
    });

    testWidgets('Send Feedback opens form with error pre-filled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWith(
              (ref) => _FakeFeedbackService(),
            ),
          ],
          child: MaterialApp(
            theme: horcrux3Dark,
            home: const InitializationErrorScreen(
              error: 'SQLiteException: database is locked',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Send Feedback'));
      await tester.pumpAndSettle();

      expect(find.text('Feedback'), findsOneWidget);
      expect(
        find.textContaining('App failed to initialize'),
        findsOneWidget,
      );
      expect(
        find.textContaining('SQLiteException: database is locked'),
        findsOneWidget,
      );
    });

    testWidgets('hides Reset Database when no callback is provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWith(
              (ref) => _FakeFeedbackService(),
            ),
          ],
          child: const MaterialApp(
            home: InitializationErrorScreen(error: 'boom'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Database'), findsNothing);
    });

    testWidgets('Reset Database confirms then invokes callback', (tester) async {
      var resetCalls = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackServiceProvider.overrideWith(
              (ref) => _FakeFeedbackService(),
            ),
          ],
          child: MaterialApp(
            theme: horcrux3Dark,
            home: InitializationErrorScreen(
              error: 'boom',
              onResetDatabase: () async {
                resetCalls++;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Button visible when callback provided.
      expect(find.text('Reset Database'), findsOneWidget);

      // Tapping opens a confirmation dialog; nothing happens yet.
      await tester.tap(find.text('Reset Database'));
      await tester.pumpAndSettle();
      expect(find.text('Reset Database?'), findsOneWidget);
      expect(resetCalls, 0);

      // Cancel does not invoke the callback.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(resetCalls, 0);

      // Confirming invokes the callback once.
      await tester.tap(find.text('Reset Database'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Reset Database'));
      await tester.pumpAndSettle();
      expect(resetCalls, 1);
    });
  });
}

class _FakeFeedbackService extends FeedbackService {
  _FakeFeedbackService() : super(formspreeFormId: 'fake');

  @override
  Future<bool> submitFeedback({
    required String message,
    String email = '',
    bool includeDiagnostics = true,
  }) async {
    return true;
  }
}
