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
