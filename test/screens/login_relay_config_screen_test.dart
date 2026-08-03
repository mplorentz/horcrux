import 'dart:async';

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
    // Override to ensure a valid Future<void> is returned when when() calls
    // this method to record the invocation. Mock.noSuchMethod returns null
    // for unstubbed Future<void> methods, which causes a type error.
    return super.noSuchMethod(
      Invocation.method(#acceptTermsOfService, [tosVersion]),
    ) as Future<void>? ?? Future<void>.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const nsec = 'nsec1test0000000000000000000000000000000000000000000000000000000001';

  /// Pump enough to let ConsentScreen finish loading ToS from assets.
  /// Can't use pumpAndSettle because the CircularProgressIndicator (shown
  /// while _isLoading is true) has an infinite animation. We pump multiple
  /// times to process the async _loadTermsOfService() -> setState cycle.
  Future<void> _pumpUntilConsentScreenLoaded(WidgetTester tester) async {
    // Let the ConsentScreen load ToS from assets. pump() alone may not
    // complete rootBundle.loadString() in the test environment, so we
    // use runAsync() to let real async I/O complete, then pump to update
    // the widget tree. We loop until the loading indicator is gone.
    for (int i = 0; i < 10; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      await tester.pump();
      final isLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      if (!isLoading) break;
    }
  }

  testWidgets('Skip with key backup shows ConsentScreen then ImportSuccessScreen', (tester) async {
    final mockApiService = MockHorcruxApiService();
    final mockApiServiceOverride = horcruxApiServiceProvider.overrideWith((ref) => mockApiService);
    final emptyVaultListOverride = vaultDetailListProvider.overrideWith(
      (ref) => Stream.value([]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyVaultListOverride,
          mockApiServiceOverride,
        ],
        child: MaterialApp(
          theme: horcrux3Dark,
          home: const LoginRelayConfigScreen(nsec: nsec),
        ),
      ),
    );
    await tester.pumpAndSettle();

    when(mockApiService.acceptTermsOfService(1)).thenAnswer((_) async => Future.value());

    // Tap Skip — now shows ConsentScreen first (routed through ConsentScreen)
    await tester.tap(find.text('Skip'));
    await _pumpUntilConsentScreenLoaded(tester);

    // ConsentScreen should be shown
    expect(find.byType(ConsentScreen), findsOneWidget);

    // Check the 'I agree' checkbox first (ConsentScreen requires it)
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    // Tap 'Agree & Continue' to accept terms
    await tester.tap(find.text('Agree & Continue'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // After accepting, ImportSuccessScreen should be shown
    expect(find.byType(ImportSuccessScreen), findsOneWidget);
    expect(find.byType(VaultListScreen), findsNothing);
  });

  testWidgets('Skip without key backup shows ConsentScreen then VaultListScreen', (tester) async {
    final mockApiService = MockHorcruxApiService();
    final mockApiServiceOverride = horcruxApiServiceProvider.overrideWith((ref) => mockApiService);
    final emptyVaultListOverride = vaultDetailListProvider.overrideWith(
      (ref) => Stream.value([]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          emptyVaultListOverride,
          mockApiServiceOverride,
        ],
        child: MaterialApp(
          theme: horcrux3Dark,
          home: const LoginRelayConfigScreen(
            nsec: nsec,
            skipOffersKeyBackup: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    when(mockApiService.acceptTermsOfService(1)).thenAnswer((_) async => Future.value());

    // Tap Skip — now shows ConsentScreen first
    await tester.tap(find.text('Skip'));
    await _pumpUntilConsentScreenLoaded(tester);

    // ConsentScreen should be shown
    expect(find.byType(ConsentScreen), findsOneWidget);

    // Check the 'I agree' checkbox first (ConsentScreen requires it)
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    // Tap 'Agree & Continue' to accept terms
    await tester.tap(find.text('Agree & Continue'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // After accepting, should navigate to vault list.
    // Use pumpAndSettle to let any pending timers (e.g. from VaultListScreen)
    // settle before the test ends, avoiding invariant failures.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byType(VaultListScreen), findsOneWidget);
    expect(find.byType(ImportSuccessScreen), findsNothing);
  });
}