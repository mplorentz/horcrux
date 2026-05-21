import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/utils/snackbar_helper.dart';

// Allow small timing tolerance in auto-dismiss tests.
// Flutter's fake clock advances in pump() increments, so exact timing
// depends on pump granularity.
const _successDuration = Duration(seconds: 2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HorcruxSnackBar', () {
    late Widget testApp;

    setUp(() {
      testApp = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  ElevatedButton(
                    key: const Key('show_a'),
                    onPressed: () => context.showHorcruxSnackBar(
                      'Toast A',
                      kind: HorcruxSnackKind.success,
                    ),
                    child: const Text('Show A'),
                  ),
                  ElevatedButton(
                    key: const Key('show_b'),
                    onPressed: () => context.showHorcruxSnackBar(
                      'Toast B',
                      kind: HorcruxSnackKind.success,
                    ),
                    child: const Text('Show B'),
                  ),
                ],
              );
            },
          ),
        ),
      );
    });

    testWidgets('single toast auto-dismisses after duration', (tester) async {
      await tester.pumpWidget(testApp);
      await tester.tap(find.byKey(const Key('show_a')));
      await tester.pump();

      // Toast should be visible
      expect(find.text('Toast A'), findsOneWidget);

      // Advance to just before dismiss — toast should still be visible
      await tester.pump(_successDuration - const Duration(milliseconds: 100));
      expect(find.text('Toast A'), findsOneWidget);

      // Advance past dismiss — toast should animate out
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(find.text('Toast A'), findsNothing);
    });

    testWidgets('second toast replaces first toast', (tester) async {
      await tester.pumpWidget(testApp);
      await tester.tap(find.byKey(const Key('show_a')));
      await tester.pump();
      expect(find.text('Toast A'), findsOneWidget);

      // Show second toast — should replace the first
      await tester.tap(find.byKey(const Key('show_b')));
      await tester.pump();
      expect(find.text('Toast B'), findsOneWidget);
      expect(find.text('Toast A'), findsNothing);

      // Wait for toast B to auto-dismiss so no pending timers
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Toast B'), findsNothing);
    });

    testWidgets('replaced toast entry does not leak in overlay', (tester) async {
      await tester.pumpWidget(testApp);

      // Show toast A, then immediately show toast B
      await tester.tap(find.byKey(const Key('show_a')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('show_b')));
      await tester.pump();

      // Only toast B should be visible
      expect(find.text('Toast B'), findsOneWidget);
      expect(find.text('Toast A'), findsNothing);

      // Wait for toast B's auto-dismiss
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Both toasts should be gone — no leaked entries
      expect(find.text('Toast A'), findsNothing);
      expect(find.text('Toast B'), findsNothing);
    });

    testWidgets('rapid succession: three toasts, only last remains', (tester) async {
      await tester.pumpWidget(testApp);

      // Rapidly show three toasts
      await tester.tap(find.byKey(const Key('show_a')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('show_b')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('show_a')));
      await tester.pump();

      // Only the last toast (A again) should be visible
      expect(find.text('Toast A'), findsOneWidget);

      // Wait for auto-dismiss
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Toast A'), findsNothing);
      expect(find.text('Toast B'), findsNothing);
    });

    testWidgets('toast auto-dismiss timer fires after first toast replaced',
        (tester) async {
      // This is the core bug scenario:
      // 1. Toast A shown, timer A scheduled (2s)
      // 2. Toast B shown before timer A fires
      //    → _finishImmediate removes entry A, cancels timer A
      //    → entry B inserted, timer B scheduled
      // 3. Timer B fires after 2s → entry B auto-dismisses
      // 4. No leaked overlay entries from toast A
      await tester.pumpWidget(testApp);

      await tester.tap(find.byKey(const Key('show_a')));
      await tester.pump();

      // Let half the timer pass, then replace with toast B
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('show_b')));
      await tester.pump();

      expect(find.text('Toast B'), findsOneWidget);

      // Wait for toast B's full duration
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Toast B'), findsNothing);
      expect(find.text('Toast A'), findsNothing);
    });

    testWidgets('error toast auto-dismisses after 2.5 seconds', (tester) async {
      late Widget errorApp;
      errorApp = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('show_error'),
                onPressed: () => context.showHorcruxSnackBar(
                  'Error occurred',
                  kind: HorcruxSnackKind.error,
                ),
                child: const Text('Show Error'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(errorApp);
      await tester.tap(find.byKey(const Key('show_error')));
      await tester.pump();
      expect(find.text('Error occurred'), findsOneWidget);

      // At 2s (success duration) — error toast should still be visible
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.text('Error occurred'),
        findsOneWidget,
        reason: 'Error toast (2.5s duration) should still be visible at 2s',
      );

      // At 2.5s+ — error toast should start dismissing
      await tester.pumpAndSettle(const Duration(milliseconds: 600));
      expect(find.text('Error occurred'), findsNothing);
    });

    testWidgets('custom duration is respected', (tester) async {
      late Widget customApp;
      customApp = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                key: const Key('show_custom'),
                onPressed: () => context.showHorcruxSnackBar(
                  'Custom duration',
                  kind: HorcruxSnackKind.info,
                  duration: const Duration(seconds: 5),
                ),
                child: const Text('Show Custom'),
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(customApp);
      await tester.tap(find.byKey(const Key('show_custom')));
      await tester.pump();
      expect(find.text('Custom duration'), findsOneWidget);

      // At 2s — custom toast should still be visible
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.text('Custom duration'),
        findsOneWidget,
        reason: 'Custom 5s toast should still be visible at 2s',
      );

      // At 3s — still visible
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Custom duration'), findsOneWidget);

      // At 5s+ — should dismiss
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Custom duration'), findsNothing);
    });
  });
}
