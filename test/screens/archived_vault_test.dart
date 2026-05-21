import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/vault_detail.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/vault_detail_screen.dart';
import 'package:horcrux/widgets/vault_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testPubkey = 'a' * 64;

  StewardedVaultDetail archivedVault({
    String? archivedReason,
    String name = 'Test Vault',
  }) {
    return StewardedVaultDetail(
      id: 'test-vault',
      name: name,
      ownerPubkey: testPubkey,
      ownerName: null,
      threshold: 2,
      totalShares: 2,
      stewards: const [],
      recoveryRequests: const [],
      pushEnabled: false,
      createdAt: DateTime(2024, 1, 1),
      archivedAt: DateTime(2024, 6, 1),
      archivedReason: archivedReason,
      backupConfig: null,
      latestShare: null,
    );
  }

  group('Archived vault - VaultDetailScreen', () {
    testWidgets('shows tombstone for vault deleted by owner', (tester) async {
      final vaultDetail = archivedVault(archivedReason: 'Vault deleted');

      final container = ProviderContainer(
        overrides: [
          vaultDetailProvider(vaultDetail.id)
              .overrideWith((ref) => Stream.value(vaultDetail)),
          currentPublicKeyProvider
              .overrideWith((ref) async => testPubkey),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
              home: VaultDetailScreen(vaultId: 'test-vault')),
        ),
      );
      await tester.pumpAndSettle();

      // Should show vault deleted message
      expect(find.text('This vault has been deleted by the owner.'),
          findsOneWidget);
      expect(find.text('Vault deleted'), findsOneWidget);
      expect(find.text('Remove from my device'), findsOneWidget);

      // Should NOT show normal vault UI
      expect(find.text('Initiate Recovery'), findsNothing);
      expect(find.text('Change Vault Contents'), findsNothing);

      container.dispose();
    });

    testWidgets('shows tombstone for steward removed from vault',
        (tester) async {
      final vaultDetail =
          archivedVault(archivedReason: 'steward_removed');

      final container = ProviderContainer(
        overrides: [
          vaultDetailProvider(vaultDetail.id)
              .overrideWith((ref) => Stream.value(vaultDetail)),
          currentPublicKeyProvider
              .overrideWith((ref) async => testPubkey),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
              home: VaultDetailScreen(vaultId: 'test-vault')),
        ),
      );
      await tester.pumpAndSettle();

      // Should show "removed from vault" message (not "deleted")
      expect(
          find.text('You have been removed from this vault.'), findsOneWidget);
      expect(find.text('steward_removed'), findsOneWidget);
      expect(find.text('Remove from my device'), findsOneWidget);

      container.dispose();
    });

    testWidgets(
        'shows tombstone with default reason when archivedReason is null',
        (tester) async {
      final vaultDetail = archivedVault(archivedReason: null);

      final container = ProviderContainer(
        overrides: [
          vaultDetailProvider(vaultDetail.id)
              .overrideWith((ref) => Stream.value(vaultDetail)),
          currentPublicKeyProvider
              .overrideWith((ref) async => testPubkey),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
              home: VaultDetailScreen(vaultId: 'test-vault')),
        ),
      );
      await tester.pumpAndSettle();

      // Should show "removed" message with default reason
      expect(
          find.text('You have been removed from this vault.'), findsOneWidget);
      expect(find.text('Removed by owner'), findsOneWidget);

      container.dispose();
    });
  });

  group('Archived vault - VaultCard', () {
    testWidgets('shows tombstone card for archived vault', (tester) async {
      final vaultDetail =
          archivedVault(archivedReason: 'Vault deleted', name: 'My Vault');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultDetailProvider(vaultDetail.id)
                .overrideWith((ref) => Stream.value(vaultDetail)),
            currentPublicKeyProvider
                .overrideWith((ref) async => testPubkey),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VaultCard(vault: vaultDetail),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show vault name
      expect(find.text('My Vault'), findsOneWidget);

      // Should show reason text
      expect(find.text('Vault deleted'), findsOneWidget);

      // Should show archive icon
      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    });

    testWidgets('shows default reason on card when archivedReason is null',
        (tester) async {
      final vaultDetail = archivedVault(archivedReason: null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vaultDetailProvider(vaultDetail.id)
                .overrideWith((ref) => Stream.value(vaultDetail)),
            currentPublicKeyProvider
                .overrideWith((ref) async => testPubkey),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VaultCard(vault: vaultDetail),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Removed by owner'), findsOneWidget);
    });
  });
}
