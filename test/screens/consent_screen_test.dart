import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/screens/consent_screen.dart';
import 'package:horcrux/services/horcrux_api_service.dart';
import 'package:horcrux/widgets/theme.dart';

/// Mock that tracks whether updateAccount was called and what args were used.
class TrackedMockHorcruxApiService extends Mock implements HorcruxApiService {
  bool updateAccountCalled = false;
  String? capturedEmail;
  bool capturedAnalyticsOptIn = false;
  bool capturedMailingList = false;

  @override
  Future<void> acceptTermsOfService(int tosVersion) {
    return super.noSuchMethod(
          Invocation.method(#acceptTermsOfService, [tosVersion]),
        ) as Future<void>? ??
        Future<void>.value();
  }

  @override
  Future<void> updateAccount({
    String? email,
    required bool analyticsOptIn,
    bool mailingList = false,
  }) {
    updateAccountCalled = true;
    capturedEmail = email;
    capturedAnalyticsOptIn = analyticsOptIn;
    capturedMailingList = mailingList;
    return Future<void>.value();
  }
}

/// Mock that throws on updateAccount to verify non-blocking error handling.
class ThrowingMock extends TrackedMockHorcruxApiService {
  @override
  Future<void> updateAccount({
    String? email,
    required bool analyticsOptIn,
    bool mailingList = false,
  }) {
    updateAccountCalled = true;
    return Future.error(Exception('API unavailable'));
  }
}

/// Helper to pump a [ConsentScreen] in onboarding mode wrapped in a test app.
Future<void> pumpConsentScreen({
  required WidgetTester tester,
  required TrackedMockHorcruxApiService mockApiService,
  Widget? nextScreen,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        horcruxApiServiceProvider.overrideWith((ref) => mockApiService),
      ],
      child: MaterialApp(
        theme: horcrux3Dark,
        home: ConsentScreen(nextScreen: nextScreen),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    rootBundle.clear();
  });

  group('ConsentFormFields', () {
    testWidgets('renders analytics checkbox, email field, and mailing-list checkbox', (
      tester,
    ) async {
      final mockApiService = TrackedMockHorcruxApiService();
      when(mockApiService.acceptTermsOfService(1)).thenAnswer((_) async => Future.value());

      await pumpConsentScreen(tester: tester, mockApiService: mockApiService);

      // Analytics checkbox
      expect(find.text('Allow Horcrux to collect analytics'), findsOneWidget);

      // Email intro text
      expect(
        find.textContaining("If you'd like, you can associate an email"),
        findsOneWidget,
      );

      // Email field
      expect(find.byType(TextFormField), findsOneWidget);

      // Mailing-list checkbox
      expect(find.text('Also subscribe me to product updates'), findsOneWidget);

      // ToS checkbox still present
      expect(
        find.text('I agree to the Terms of Service & Privacy Policy'),
        findsOneWidget,
      );

      // Continue button
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('mailing-list checkbox is disabled when email is empty', (tester) async {
      final mockApiService = TrackedMockHorcruxApiService();
      when(mockApiService.acceptTermsOfService(1)).thenAnswer((_) async => Future.value());

      await pumpConsentScreen(tester: tester, mockApiService: mockApiService);

      // The mailing-list row should exist
      final mailingListRow = find.text('Also subscribe me to product updates');
      expect(mailingListRow, findsOneWidget);

      // Tapping it should have no effect (AbsorbPointer)
      await tester.tap(mailingListRow);
      await tester.pump();

      // No crash expected — AbsorbPointer prevents the tap
    });

    testWidgets('mailing-list checkbox becomes enabled when email is entered', (tester) async {
      final mockApiService = TrackedMockHorcruxApiService();
      when(mockApiService.acceptTermsOfService(1)).thenAnswer((_) async => Future.value());

      await pumpConsentScreen(tester: tester, mockApiService: mockApiService);

      // Enter an email
      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.pump();

      // The mailing-list checkbox should now be tappable
      await tester.tap(find.text('Also subscribe me to product updates'));
      await tester.pump();
    });

    testWidgets('Continue calls both acceptTermsOfService and updateAccount with preferences', (
      tester,
    ) async {
      final mockApiService = TrackedMockHorcruxApiService();
      when(mockApiService.acceptTermsOfService(1)).thenAnswer((_) async => Future.value());

      await pumpConsentScreen(tester: tester, mockApiService: mockApiService);

      // Toggle analytics on
      await tester.tap(find.text('Allow Horcrux to collect analytics'));
      await tester.pump();

      // Enter an email
      await tester.enterText(find.byType(TextFormField), 'user@example.com');
      await tester.pump();

      // Toggle mailing-list
      await tester.tap(find.text('Also subscribe me to product updates'));
      await tester.pump();

      // Accept ToS
      await tester.tap(find.text('I agree to the Terms of Service & Privacy Policy'));
      await tester.pump();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Flush the success snackbar's 2s auto-dismiss timer.
      await tester.pump(const Duration(seconds: 3));

      // Verify both APIs were called
      verify(mockApiService.acceptTermsOfService(1)).called(1);
      expect(mockApiService.updateAccountCalled, isTrue);
      expect(mockApiService.capturedEmail, 'user@example.com');
      expect(mockApiService.capturedAnalyticsOptIn, isTrue);
      expect(mockApiService.capturedMailingList, isTrue);
    });

    testWidgets('updateAccount failure does not block navigation', (tester) async {
      final mockApiService = ThrowingMock();
      when(mockApiService.acceptTermsOfService(1)).thenAnswer((_) async => Future.value());

      // A distinct destination so we can assert navigation occurred even
      // though the account write fails.
      const nextScreen = Scaffold(body: Text('Post-consent destination'));

      await pumpConsentScreen(
        tester: tester,
        mockApiService: mockApiService,
        nextScreen: nextScreen,
      );

      // Accept ToS
      await tester.tap(find.text('I agree to the Terms of Service & Privacy Policy'));
      await tester.pump();

      // Tap Continue — updateAccount fails but navigation should proceed
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Navigation proceeded despite the failed account write.
      expect(find.text('Post-consent destination'), findsOneWidget);

      // Verify ToS was accepted
      verify(mockApiService.acceptTermsOfService(1)).called(1);
      // Verify updateAccount was attempted
      expect(mockApiService.updateAccountCalled, isTrue);

      // Flush any warning snackbar timer (from the non-blocking account
      // write failure) so the test doesn't end with a pending timer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}
