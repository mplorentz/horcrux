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

      // Advance to just before dismiss — toast should still be visible
      await tester.pump(const Duration(seconds: 1, milliseconds: 900));
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

    testWidgets('toast auto-dismiss timer fires after first toast replaced', (tester) async {
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

  group('HorcruxSnackBar screen pop scenario', () {
    testWidgets('toast auto-dismisses after Navigator.pop rebuilds overlay', (tester) async {
      // Simulates the recovery-plan save flow:
      // 1. Show toast on screen B
      // 2. Pop back to screen A (overlay rebuilds)
      // 3. Toast should auto-dismiss after 2s
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: Text('Screen A')),
      ));

      // Push screen B
      navKey.currentState!.push(MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('save_and_pop'),
              onPressed: () {
                // Show toast, then pop in next frame (like backup_config_screen)
                context.showHorcruxSnackBar(
                  'Backup configuration saved successfully!',
                  kind: HorcruxSnackKind.success,
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pop();
                });
              },
              child: const Text('Save & Pop'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap save — shows toast, then pops back to Screen A
      await tester.tap(find.byKey(const Key('save_and_pop')));
      await tester.pumpAndSettle();

      // We should be back on Screen A
      expect(find.text('Screen A'), findsOneWidget);

      // Toast should still be visible (it's in the overlay, not the route)
      expect(find.text('Backup configuration saved successfully!'), findsOneWidget);

      // Wait for auto-dismiss (2s for success)
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Toast should be gone
      expect(
        find.text('Backup configuration saved successfully!'),
        findsNothing,
        reason: 'Toast should auto-dismiss after screen pop',
      );
    });

    testWidgets(
        'toast auto-dismisses after replacement + screen pop '
        '(push-permission scenario)', (tester) async {
      // Simulates the exact recovery-plan save flow identified by the reviewer:
      // 1. Show success toast ("Backup configuration saved")
      // 2. Show error toast ("Push permission not granted") — replaces success
      // 3. Navigator.pop back to screen A (overlay rebuilds)
      // 4. Error toast (2.5s) should auto-dismiss
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: Text('Screen A')),
      ));

      navKey.currentState!.push(MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('save_with_push_prompt'),
              onPressed: () {
                // Step 1: Show success toast
                context.showHorcruxSnackBar(
                  'Backup configuration saved successfully!',
                  kind: HorcruxSnackKind.success,
                );
                // Step 2: Push permission check shows error toast
                // (simulating maybePromptOwnerForVaultPush)
                context.showHorcruxSnackBar(
                  'Push permission was not granted.',
                  kind: HorcruxSnackKind.error,
                );
                // Step 3: Pop in next frame (like _popWithOwnerPushPrompt)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pop();
                });
              },
              child: const Text('Save & Prompt Push'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap the button
      await tester.tap(find.byKey(const Key('save_with_push_prompt')));
      await tester.pumpAndSettle();

      // Back on Screen A
      expect(find.text('Screen A'), findsOneWidget);

      // The error toast (last shown) should be visible, success toast replaced
      expect(find.text('Push permission was not granted.'), findsOneWidget);
      expect(find.text('Backup configuration saved successfully!'), findsNothing);

      // At 2s (success duration) — error toast should STILL be visible
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.text('Push permission was not granted.'),
        findsOneWidget,
        reason: 'Error toast (2.5s) should still be visible at 2s',
      );

      // At 2.5s+ — error toast should dismiss
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(
        find.text('Push permission was not granted.'),
        findsNothing,
        reason: 'Error toast should auto-dismiss after 2.5s even after replacement + screen pop',
      );
    });
  });
}
