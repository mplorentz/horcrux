import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/screens/import_success_screen.dart';
import 'package:horcrux/screens/login_relay_config_screen.dart';
import 'package:horcrux/screens/vault_list_screen.dart';
import 'package:horcrux/widgets/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const nsec = 'nsec1test0000000000000000000000000000000000000000000000000000000001';

  final emptyVaultListOverride = vaultDetailListProvider.overrideWith(
    (ref) => Stream.value([]),
  );

  testWidgets('Skip with key backup offers ImportSuccessScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [emptyVaultListOverride],
        child: MaterialApp(
          theme: horcrux3Dark,
          home: const LoginRelayConfigScreen(nsec: nsec),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(ImportSuccessScreen), findsOneWidget);
    expect(find.byType(VaultListScreen), findsNothing);
  });

  testWidgets('Skip without key backup goes to VaultListScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [emptyVaultListOverride],
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

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(VaultListScreen), findsOneWidget);
    expect(find.byType(ImportSuccessScreen), findsNothing);
  });
}
