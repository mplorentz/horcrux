import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/screens/consent_screen.dart';
import 'package:horcrux/screens/import_success_screen.dart';
import 'package:horcrux/screens/login_relay_config_screen.dart';
import 'package:horcrux/screens/vault_list_screen.dart';
import 'package:horcrux/services/horcrux_api_service.dart';
import 'package:horcrux/widgets/theme.dart';

/// Mock HorcruxApiService that properly handles Future<void> return types.
class MockHorcruxApiService extends Mock implements HorcruxApiService {
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
    return super.noSuchMethod(
          Invocation.method(#updateAccount, [email, analyticsOptIn, mailingList]),
        ) as Future<void>? ??
        Future<void>.value();
  }
}

/// A test asset bundle that returns empty strings for any asset path.
/// ConsentScreen uses DefaultAssetBundle.of(context) to load the ToS and
/// Privacy Policy markdown, so this makes loading instant in tests.
class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    return ByteData(0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const nsec = 'nsec1test0000000000000000000000000000000000000000000000000000000001';

  setUp(() {
    // The ConsentScreen that _skip()/_continue() push is above the testApp's
    // DefaultAssetBundle, so it loads its ToS from the global rootBundle, which
    // caches the load Future. That Future is created inside one test's
    // fake-async zone; awaiting the cached Future from the next test's zone
    // never completes, leaving ConsentScreen stuck on its CircularProgress
    // spinner — whose endless animation makes pumpAndSettle() time out.
    // Clearing the cache makes each test load the ToS fresh in its own zone.
    rootBundle.clear();
  });

  Widget testApp({
    required MockHorcruxApiService mockApiService,
    required bool skipOffersKeyBackup,
  }) {
    return ProviderScope(
      overrides: [
        vaultDetailListProvider.overrideWith((ref) => Stream.value([])),
        horcruxApiServiceProvider.overrideWith((ref) => mockApiService),
      ],
      child: MaterialApp(
        theme: horcrux3Dark,
        home: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: LoginRelayConfigScreen(
            nsec: nsec,
            skipOffersKeyBackup: skipOffersKeyBackup,
          ),
        ),
      ),
    );
  }

  testWidgets('Skip with key backup shows ConsentScreen then ImportSuccessScreen', (tester) async {
    final mockApiService = MockHorcruxApiService();

    await tester.pumpWidget(testApp(mockApiService: mockApiService, skipOffersKeyBackup: true));
    await tester.pumpAndSettle();

    when(mockApiService.acceptTermsOfService(1)).thenAnswer((_) async => Future.value());

    // Tap Skip — now shows ConsentScreen first (routed through ConsentScreen)
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // ConsentScreen should be shown
    expect(find.byType(ConsentScreen), findsOneWidget);

    // Check the 'I agree' checkbox (ToS checkbox) — tap the label text
    await tester.tap(find.text('I agree to the Terms of Service & Privacy Policy'));
    await tester.pumpAndSettle();

    // Tap 'Continue' to accept terms
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // After accepting, ImportSuccessScreen should be shown
    expect(find.byType(ImportSuccessScreen), findsOneWidget);
    expect(find.byType(VaultListScreen), findsNothing);

    // ConsentScreen must have actually submitted terms acceptance.
    verify(mockApiService.acceptTermsOfService(1)).called(1);
  });

  testWidgets('Skip without key backup shows ConsentScreen then VaultListScreen', (tester) async {
    final mockApiService = MockHorcruxApiService();

    await tester.pumpWidget(testApp(mockApiService: mockApiService, skipOffersKeyBackup: false));
    await tester.pumpAndSettle();

    when(mockApiService.acceptTermsOfService(1)).thenAnswer((_) async => Future.value());

    // Tap Skip — routes through ConsentScreen, then to VaultListScreen.
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Should be at ConsentScreen (from _continue())
    expect(find.byType(ConsentScreen), findsOneWidget);

    // Accept the ToS by tapping the 'I agree' label text
    await tester.tap(find.text('I agree to the Terms of Service & Privacy Policy'));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Continue'));
    // Use pump() instead of pumpAndSettle() because VaultListScreen may have
    // infinite animations (timers, periodic refresh from vaultDetailListProvider).
    await tester.pump();
    // Accepting with no nextScreen shows a success snackbar with a 2s
    // auto-dismiss timer before popping back to _continue(). Advance past that
    // timer so it isn't left pending when the widget tree is disposed.
    await tester.pump(const Duration(seconds: 3));

    // After acceptance, ConsentScreen pops, _continue() resumes, and
    // routeToVaultListOrStagedInvitation pushes VaultListScreen.
    expect(find.byType(VaultListScreen), findsOneWidget);
    expect(find.byType(ImportSuccessScreen), findsNothing);

    // ConsentScreen must have actually submitted terms acceptance.
    verify(mockApiService.acceptTermsOfService(1)).called(1);
  });
}
