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

/// Mock HorcruxApiService that accepts ToS without network calls.
class MockHorcruxApiService extends Mock implements HorcruxApiService {}

final mockApiService = MockHorcruxApiService();

final mockApiServiceOverride = horcruxApiServiceProvider.overrideWith((ref) => mockApiService);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const nsec = 'nsec1test0000000000000000000000000000000000000000000000000000000001';

  final emptyVaultListOverride = vaultDetailListProvider.overrideWith(
    (ref) => Stream.value([]),
  );

  testWidgets('Skip with key backup shows ConsentScreen then ImportSuccessScreen', (tester) async {
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
    await tester.pumpAndSettle();

    // ConsentScreen should be shown
    expect(find.byType(ConsentScreen), findsOneWidget);

    // Tap 'Agree & Continue' to accept terms
    await tester.tap(find.text('Agree & Continue'));
    await tester.pumpAndSettle();

    // After accepting, ImportSuccessScreen should be shown
    expect(find.byType(ImportSuccessScreen), findsOneWidget);
    expect(find.byType(VaultListScreen), findsNothing);
  });

  testWidgets('Skip without key backup shows ConsentScreen then VaultListScreen', (tester) async {
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
    await tester.pumpAndSettle();

    // ConsentScreen should be shown
    expect(find.byType(ConsentScreen), findsOneWidget);

    // Tap 'Agree & Continue' to accept terms
    await tester.tap(find.text('Agree & Continue'));
    // Use pump() with a fixed duration instead of pumpAndSettle() because
    // VaultListScreen may have infinite animations (timers, periodic refresh).
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // After accepting, should navigate to vault list
    expect(find.byType(VaultListScreen), findsOneWidget);
    expect(find.byType(ImportSuccessScreen), findsNothing);
  });
}