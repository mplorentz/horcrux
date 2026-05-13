import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/database/app_database_provider.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/widgets/theme.dart';

import 'test_database.dart';

/// In-memory database override for widget / golden tests. Uses
/// `closeStreamsSynchronously: true` (the pattern recommended by the Drift
/// docs) so stream teardown is synchronous and does not leave pending timers
/// after a test disposes its widget tree.
Override goldenAppDatabaseOverride() =>
    appDatabaseProvider.overrideWithValue(newWidgetTestDatabase());

/// Replaces the recovery banner stream with an empty one so
/// [RecoveryService.initialize] is never called.
///
/// This override exists because [RecoveryService.initialize] has three
/// hardcoded platform-channel calls with no injection points:
///   1. [ProcessedNostrEventStore.ensureLoaded] → `path_provider`
///   2. `_loadViewedNotificationIds` → [SharedPreferences.getInstance]
///   3. [getFirstAppOpenUtc] → [SharedPreferences.getInstance]
///
/// The right long-term fix is to inject those dependencies so tests can
/// swap them for in-memory doubles (bead 8lk). Until then, overriding at the
/// [pendingRecoveryRequestsProvider] boundary is the narrowest cut that
/// prevents the entire chain from initialising.
final Override goldenPendingRecoveryEmptyOverride = pendingRecoveryRequestsProvider.overrideWith(
  (ref) => Stream<List<RecoveryRequest>>.value(const []),
);

/// Prepends shared golden overrides before [overrides]. Later entries win when
/// the same provider is overridden twice.
///
/// Includes an in-memory database override (via [goldenAppDatabaseOverride])
/// and an empty recovery-request stream (via [goldenPendingRecoveryEmptyOverride])
/// so widget / golden tests never touch platform channels for storage or
/// secure-key access.
List<Override> goldenOverrides(List<Override> overrides) => [
      goldenAppDatabaseOverride(),
      goldenPendingRecoveryEmptyOverride,
      ...overrides,
    ];

/// Riverpod scope for golden / widget tests: in-memory DB, empty recovery
/// stream, and async [dispose] that closes Drift after the container is disposed.
final class GoldenTestHarness {
  GoldenTestHarness._(this.container);

  /// The [ProviderContainer] passed to [goldenMaterialAppWrapperWithProviders]
  /// or [goldenMaterialAppWrapperWithProvidersAndScaffold].
  final ProviderContainer container;

  /// Same override stack as [pumpGoldenWidget], without pumping. Use with
  /// [DeviceBuilder] / custom [pumpWidgetBuilder] and call [dispose] when done.
  factory GoldenTestHarness.withOverrides([List<Override> overrides = const []]) {
    return GoldenTestHarness._(
      ProviderContainer(overrides: goldenOverrides(overrides)),
    );
  }

  /// Pumps [widget] with MaterialApp, theme, and [goldenOverrides] applied.
  static Future<GoldenTestHarness> pumpWidget(
    WidgetTester tester,
    Widget widget, {
    List<Override> overrides = const [],
    Size? surfaceSize,
    bool useScaffold = false,
    bool waitForSettle = true,
  }) async {
    const defaultSize = Size(375, 667); // iPhone SE size
    final effectiveSize = surfaceSize ?? defaultSize;
    final harness = GoldenTestHarness.withOverrides(overrides);
    final container = harness.container;

    final Widget Function(Widget) wrapper = useScaffold
        ? (child) => goldenMaterialAppWrapperWithProvidersAndScaffold(
              child: child,
              container: container,
            )
        : (child) => goldenMaterialAppWrapperWithProviders(
              child: child,
              container: container,
            );

    await tester.pumpWidgetBuilder(
      widget,
      wrapper: wrapper,
      surfaceSize: effectiveSize,
    );

    if (waitForSettle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return harness;
  }

  /// Disposes the container and closes the in-memory test database.
  Future<void> dispose() async {
    final db = container.read(appDatabaseProvider);
    container.dispose();
    await db.close();
  }
}

/// Matches a golden file without calling `pumpAndSettle()`.
///
/// This helper is specifically designed for cases where `screenMatchesGolden`
/// would timeout because it calls `pumpAndSettle()` internally, which never
/// completes for widgets with infinite animations like `CircularProgressIndicator`.
///
/// Instead, this function:
/// 1. Pumps the widget tree to ensure layout is complete
/// 2. Uses `expectLater` with `matchesGoldenFile` directly, avoiding
///    the `pumpAndSettle` call that causes timeouts
///
/// Usage:
/// ```dart
/// await tester.pumpWidgetBuilder(...);
/// await tester.pump();
/// await screenMatchesGoldenWithoutSettle<MyWidget>(tester, 'my_widget_loading');
/// ```
///
/// Parameters:
/// - [tester] - The widget tester instance
/// - [goldenName] - The name of the golden file (without path/extension)
Future<void> screenMatchesGoldenWithoutSettle<T extends Widget>(
  WidgetTester tester,
  String goldenName,
) async {
  // Use pump instead of pumpAndSettle to avoid timeout
  await tester.pump();

  // Manually capture the golden without pumpAndSettle
  // Respect the global skipGoldenAssertion (skips on non-macOS platforms)
  await expectLater(
    find.byType(T),
    matchesGoldenFile('goldens/$goldenName.png'),
    skip: GoldenToolkit.configuration.skipGoldenAssertion(),
  );
}

/// Matches a golden file without calling `pumpAndSettle()`, using a custom finder.
///
/// This is useful when you need to match a specific widget instance
/// rather than just finding by type.
///
/// Usage:
/// ```dart
/// await tester.pumpWidgetBuilder(...);
/// await tester.pump();
/// await screenMatchesGoldenWithoutSettleWithFinder(
///   tester,
///   'my_widget_loading',
///   find.byKey(myKey),
/// );
/// ```
Future<void> screenMatchesGoldenWithoutSettleWithFinder(
  WidgetTester tester,
  String goldenName,
  Finder finder,
) async {
  // Use pump instead of pumpAndSettle to avoid timeout
  await tester.pump();

  // Manually capture the golden without pumpAndSettle
  // Respect the global skipGoldenAssertion (skips on non-macOS platforms)
  await expectLater(
    finder,
    matchesGoldenFile('goldens/$goldenName.png'),
    skip: GoldenToolkit.configuration.skipGoldenAssertion(),
  );
}

/// Creates a MaterialApp wrapper with horcrux3Dark theme for golden tests.
///
/// This is the standard wrapper for golden tests that don't need Riverpod providers.
/// It wraps the child widget in a MaterialApp with the horcrux3Dark theme applied.
///
/// Usage:
/// ```dart
/// await tester.pumpWidgetBuilder(
///   const MyWidget(),
///   wrapper: goldenMaterialAppWrapper,
/// );
/// ```
Widget Function(Widget) get goldenMaterialAppWrapper =>
    (Widget child) => MaterialApp(theme: horcrux3Dark, home: child);

/// Creates a MaterialApp wrapper with horcrux3Dark theme and ProviderContainer for golden tests.
///
/// This wrapper includes Riverpod provider support via UncontrolledProviderScope.
/// Use this when your widget needs access to Riverpod providers.
///
/// Usage:
/// ```dart
/// final harness = GoldenTestHarness.withOverrides([...]);
/// await tester.pumpWidgetBuilder(
///   const MyWidget(),
///   wrapper: (child) => goldenMaterialAppWrapperWithProviders(
///     child: child,
///     container: harness.container,
///   ),
/// );
/// await harness.dispose();
/// ```
///
/// Parameters:
/// - [child] - The widget to wrap
/// - [container] - The [ProviderContainer] (for example [GoldenTestHarness.container])
Widget goldenMaterialAppWrapperWithProviders({
  required Widget child,
  required ProviderContainer container,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: horcrux3Dark, home: child),
  );
}

/// Creates a MaterialApp wrapper with horcrux3Dark theme, ProviderContainer, and Scaffold for golden tests.
///
/// This wrapper includes Riverpod provider support and wraps the child in a Scaffold.
/// Use this when your widget needs providers and should be displayed in a Scaffold context.
///
/// Usage:
/// ```dart
/// final harness = GoldenTestHarness.withOverrides([...]);
/// await tester.pumpWidgetBuilder(
///   const MyWidget(),
///   wrapper: (child) => goldenMaterialAppWrapperWithProvidersAndScaffold(
///     child: child,
///     container: harness.container,
///   ),
/// );
/// await harness.dispose();
/// ```
///
/// Parameters:
/// - [child] - The widget to wrap
/// - [container] - The [ProviderContainer] (for example [GoldenTestHarness.container])
Widget goldenMaterialAppWrapperWithProvidersAndScaffold({
  required Widget child,
  required ProviderContainer container,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: horcrux3Dark,
      home: Scaffold(body: child),
    ),
  );
}

/// Pumps a widget for golden testing with automatic MaterialApp and theme setup.
///
/// Same behavior as [GoldenTestHarness.pumpWidget]; kept as a short name for
/// call sites. Always applies [goldenOverrides] (in-memory DB + empty recovery
/// stream) so widgets never resolve [appDatabaseProvider] to production
/// SQLCipher / path_provider.
///
/// Usage:
/// ```dart
/// final harness = await pumpGoldenWidget(
///   tester,
///   const MyWidget(),
///   surfaceSize: Size(375, 667),
/// );
/// await screenMatchesGolden(tester, 'my_widget');
/// await harness.dispose();
/// ```
Future<GoldenTestHarness> pumpGoldenWidget(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
  Size? surfaceSize,
  bool useScaffold = false,
  bool waitForSettle = true,
}) =>
    GoldenTestHarness.pumpWidget(
      tester,
      widget,
      overrides: overrides,
      surfaceSize: surfaceSize,
      useScaffold: useScaffold,
      waitForSettle: waitForSettle,
    );
