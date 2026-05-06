import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/screens/account_created_screen.dart';
import 'package:horcrux/screens/onboarding_screen.dart';
import 'package:horcrux/widgets/row_button.dart';
import 'package:horcrux/widgets/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/secure_storage_mock.dart';

/// Pumps [child] with a MediaQuery that simulates an iPhone with a home
/// indicator (34pt bottom view padding).
Future<void> pumpWithIPhoneHomeIndicator(
  WidgetTester tester,
  Widget child,
) async {
  // iPhone 14 logical size with 34pt bottom safe area (home indicator).
  const screenSize = Size(390, 844);
  const homeIndicatorInset = 34.0;

  await tester.binding.setSurfaceSize(screenSize);
  tester.view.physicalSize = screenSize * tester.view.devicePixelRatio;
  tester.view.padding = FakeViewPadding(
    bottom: homeIndicatorInset * tester.view.devicePixelRatio,
  );
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetPadding();
    tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(
        size: screenSize,
        padding: EdgeInsets.only(bottom: homeIndicatorInset),
      ),
      child: MaterialApp(
        theme: horcrux3Dark.copyWith(platform: TargetPlatform.iOS),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStorageMock = SecureStorageMock();

  setUpAll(() {
    secureStorageMock.setUpAll();
  });

  tearDownAll(() {
    secureStorageMock.tearDownAll();
  });

  setUp(() {
    secureStorageMock.clear();
    SharedPreferences.setMockInitialValues({});
  });

  group('Bottom RowButton clears iPhone home indicator', () {
    const homeIndicatorInset = 34.0;
    const screenHeight = 844.0;
    // The bottom edge of the *visible* button rectangle must sit at or above
    // the home-indicator boundary. Allow 1px tolerance for layout rounding.
    const tolerance = 1.0;

    Future<void> expectBottomRowButtonClearsHomeIndicator(
      WidgetTester tester,
    ) async {
      final rowButtons = find.byType(RowButton);
      expect(rowButtons, findsWidgets);

      // The visible button rectangle is the InkWell inside RowButton; the
      // RowButton itself may wrap an external Padding for safe area.
      final lastInkWell =
          find.descendant(of: rowButtons.last, matching: find.byType(InkWell)).evaluate().first;
      final renderBox = lastInkWell.renderObject! as RenderBox;
      final bottomLeft = renderBox.localToGlobal(
        Offset(0, renderBox.size.height),
      );
      final distanceFromScreenBottom = screenHeight - bottomLeft.dy;

      expect(
        distanceFromScreenBottom,
        greaterThanOrEqualTo(homeIndicatorInset - tolerance),
        reason: 'Bottom RowButton sits ${distanceFromScreenBottom.toStringAsFixed(1)}pt '
            'above the screen bottom but should sit at or above '
            'the ${homeIndicatorInset}pt home indicator inset.',
      );
    }

    testWidgets(
      'AccountCreatedScreen on iOS leaves room for home indicator',
      (tester) async {
        const testNsec = 'nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5';

        final container = ProviderContainer();
        addTearDown(container.dispose);

        await pumpWithIPhoneHomeIndicator(
          tester,
          UncontrolledProviderScope(
            container: container,
            child: const AccountCreatedScreen(nsec: testNsec),
          ),
        );

        await expectBottomRowButtonClearsHomeIndicator(tester);
      },
    );

    testWidgets(
      'OnboardingScreen on iOS leaves room for home indicator',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await pumpWithIPhoneHomeIndicator(
          tester,
          UncontrolledProviderScope(
            container: container,
            child: const OnboardingScreen(),
          ),
        );

        await expectBottomRowButtonClearsHomeIndicator(tester);
      },
    );
  });
}
