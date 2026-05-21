import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/utils/snackbar_helper.dart';

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

      // Wait for auto-dismiss duration (2 seconds for success)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Toast should be gone
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
  });
}
