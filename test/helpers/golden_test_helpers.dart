import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/widgets/theme.dart';

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
  await expectLater(
    find.byType(T),
    matchesGoldenFile('goldens/$goldenName.png'),
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
  await expectLater(finder, matchesGoldenFile('goldens/$goldenName.png'));
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
/// final container = ProviderContainer(overrides: [...]);
/// await tester.pumpWidgetBuilder(
///   const MyWidget(),
///   wrapper: (child) => goldenMaterialAppWrapperWithProviders(
///     child: child,
///     container: container,
///   ),
/// );
/// container.dispose();
/// ```
///
/// Parameters:
/// - [child] - The widget to wrap
/// - [container] - The ProviderContainer with any necessary overrides
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
/// final container = ProviderContainer(overrides: [...]);
/// await tester.pumpWidgetBuilder(
///   const MyWidget(),
///   wrapper: (child) => goldenMaterialAppWrapperWithProvidersAndScaffold(
///     child: child,
///     container: container,
///   ),
/// );
/// container.dispose();
/// ```
///
/// Parameters:
/// - [child] - The widget to wrap
/// - [container] - The ProviderContainer with any necessary overrides
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
/// This is a high-level helper that wraps `pumpWidgetBuilder` and automatically
/// handles MaterialApp wrapping with the horcrux3Dark theme. It simplifies common
/// golden test setup by abstracting away the wrapper creation.
///
/// Usage without providers:
/// ```dart
/// await pumpGoldenWidget(
///   tester,
///   const MyWidget(),
///   surfaceSize: Size(375, 667),
/// );
/// ```
///
/// Usage with providers:
/// ```dart
/// final container = ProviderContainer(overrides: [...]);
/// await pumpGoldenWidget(
///   tester,
///   const MyWidget(),
///   container: container,
///   surfaceSize: Size(375, 667),
/// );
/// container.dispose();
/// ```
///
/// Usage for loading states (without waiting for settle):
/// ```dart
/// await pumpGoldenWidget(
///   tester,
///   const MyWidget(),
///   waitForSettle: false,
/// );
/// await screenMatchesGoldenWithoutSettle<MyWidget>(tester, 'my_widget_loading');
/// ```
///
/// Parameters:
/// - [tester] - The widget tester instance
/// - [widget] - The widget to test
/// - [container] - Optional ProviderContainer for Riverpod providers
/// - [surfaceSize] - Optional surface size (defaults to iPhone SE: 375x667)
/// - [useScaffold] - Whether to wrap widget in Scaffold (defaults to false)
/// - [waitForSettle] - Whether to wait for animations to settle (defaults to true).
///   Set to false for loading states with infinite animations like CircularProgressIndicator.
Future<void> pumpGoldenWidget(
  WidgetTester tester,
  Widget widget, {
  ProviderContainer? container,
  Size? surfaceSize,
  bool useScaffold = false,
  bool waitForSettle = true,
}) async {
  const defaultSize = Size(375, 667); // iPhone SE size
  final effectiveSize = surfaceSize ?? defaultSize;

  Widget Function(Widget) wrapper;
  if (container != null) {
    if (useScaffold) {
      wrapper = (child) => goldenMaterialAppWrapperWithProvidersAndScaffold(
            child: child,
            container: container,
          );
    } else {
      wrapper = (child) => goldenMaterialAppWrapperWithProviders(
            child: child,
            container: container,
          );
    }
  } else {
    wrapper = goldenMaterialAppWrapper;
  }

  await tester.pumpWidgetBuilder(
    widget,
    wrapper: wrapper,
    surfaceSize: effectiveSize,
  );

  // Wait for animations to settle, or just pump once for loading states
  if (waitForSettle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}
