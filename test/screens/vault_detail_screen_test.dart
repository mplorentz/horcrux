import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/vault_detail.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/screens/vault_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testPubkey = 'a' * 64;
  final otherPubkey = 'b' * 64;

  /// Minimal provider overrides shared across most tests.
  List<Override> baseOverrides({
    required VaultDetail vault,
    required String currentPubkey,
    RecoveryStatus recoveryStatus = const RecoveryStatus(
      hasActiveRecovery: false,
      canRecover: false,
      activeRecoveryRequest: null,
      isInitiator: false,
    ),
  }) =>
      [
        vaultDetailProvider(vault.id).overrideWith((ref) => Stream.value(vault)),
        currentPublicKeyProvider.overrideWith((ref) async => currentPubkey),
        recoveryStatusProvider.overrideWith((ref, vaultId) => AsyncValue.data(recoveryStatus)),
      ];

  // T030: Widget test for owner-steward vault detail buttons
  group('Owner-steward vault detail buttons', () {
    testWidgets('shows Initiate Recovery and Change Vault Contents for owner-steward state', (
      tester,
    ) async {
      // Owner-steward state: isOwner, no owned_vaults row, has self-shard
      final ownerShard = createShare(
        payload: 'owner-shard-data',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        primeMod: 'test-prime-mod',
        creatorPubkey: testPubkey,
        vaultId: 'test-vault',
        vaultName: 'Test Vault',
        distributionVersion: 1,
      );

      final ownerSteward = createOwnerSteward(pubkey: testPubkey);
      final otherSteward = createSteward(pubkey: otherPubkey, name: 'Alice');

      final backupConfig = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        totalKeys: 2,
        stewards: [ownerSteward, otherSteward],
        relays: ['wss://relay.example.com'],
      );

      // No owned_vaults row → StewardedVaultDetail (owner-steward carve-out)
      final vaultDetail = StewardedVaultDetail(
        id: 'test-vault',
        name: 'Test Vault',
        ownerPubkey: testPubkey,
        ownerName: null,
        threshold: 2,
        totalShares: 2,
        stewards: const [],
        recoveryRequests: const [],
        pushEnabled: false,
        createdAt: DateTime(2024, 1, 1),
        archivedAt: null,
        archivedReason: null,
        backupConfig: backupConfig,
        latestShare: ownerShard,
      );

      final container = ProviderContainer(
        overrides: baseOverrides(vault: vaultDetail, currentPubkey: testPubkey),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VaultDetailScreen(vaultId: 'test-vault')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Initiate Recovery'), findsOneWidget);
      expect(find.text('Change Vault Contents'), findsOneWidget);

      container.dispose();
    });

    testWidgets(
      'shows Travel Mode button when owner has content and owner steward configured',
      (tester) async {
        final ownerSteward = createOwnerSteward(pubkey: testPubkey);
        final otherSteward = createSteward(pubkey: otherPubkey, name: 'Alice');

        final backupConfig = createBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 2,
          stewards: [ownerSteward, otherSteward],
          relays: ['wss://relay.example.com'],
        ).copyWith(distributionVersion: 1);

        final vaultDetail = OwnedVaultDetail(
          id: 'test-vault',
          name: 'Test Vault',
          ownerPubkey: testPubkey,
          ownerName: null,
          threshold: 2,
          totalShares: 2,
          stewards: const [],
          recoveryRequests: const [],
          pushEnabled: false,
          createdAt: DateTime(2024, 1, 1),
          archivedAt: null,
          archivedReason: null,
          backupConfig: backupConfig,
          content: 'ciphertext',
          selfHeldShare: null,
        );

        final container = ProviderContainer(
          overrides: baseOverrides(vault: vaultDetail, currentPubkey: testPubkey),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: VaultDetailScreen(vaultId: 'test-vault')),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Travel Mode'), findsOneWidget);

        container.dispose();
      },
    );

    testWidgets('shows Travel Mode after distribution even without owner steward', (
      tester,
    ) async {
      final steward1 = createSteward(pubkey: otherPubkey, name: 'Alice');

      final backupConfig = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 1,
        totalKeys: 1,
        stewards: [steward1],
        relays: ['wss://relay.example.com'],
      ).copyWith(distributionVersion: 1);

      final vaultDetail = OwnedVaultDetail(
        id: 'test-vault',
        name: 'Test Vault',
        ownerPubkey: testPubkey,
        ownerName: null,
        threshold: 1,
        totalShares: 1,
        stewards: const [],
        recoveryRequests: const [],
        pushEnabled: false,
        createdAt: DateTime(2024, 1, 1),
        archivedAt: null,
        archivedReason: null,
        backupConfig: backupConfig,
        content: 'ciphertext',
        selfHeldShare: null,
      );

      final container = ProviderContainer(
        overrides: baseOverrides(vault: vaultDetail, currentPubkey: testPubkey),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VaultDetailScreen(vaultId: 'test-vault')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Travel Mode'), findsOneWidget);

      container.dispose();
    });
  });

  group('Steward vault detail buttons with concurrent multi-initiator recoveries', () {
    testWidgets(
      'shows Manage Recovery for the current user when another user has a newer active recovery',
      (tester) async {
        final stewardShard = createShare(
          payload: 'steward-shard-data',
          threshold: 1,
          shareIndex: 0,
          totalShares: 2,
          primeMod: 'test-prime-mod',
          creatorPubkey: otherPubkey,
          vaultId: 'test-vault',
          vaultName: 'Test Vault',
          distributionVersion: 1,
        );

        final myRequest = RecoveryRequest(
          id: 'my-request',
          vaultId: 'test-vault',
          initiatorPubkey: testPubkey,
          requestedAt: DateTime(2024, 1, 1, 10),
          status: RecoveryRequestStatus.inProgress,
          threshold: 1,
        );
        final otherRequest = RecoveryRequest(
          id: 'other-request',
          vaultId: 'test-vault',
          initiatorPubkey: otherPubkey,
          requestedAt: DateTime(2024, 1, 1, 12),
          status: RecoveryRequestStatus.inProgress,
          threshold: 1,
        );

        final vaultDetail = StewardedVaultDetail(
          id: 'test-vault',
          name: 'Test Vault',
          ownerPubkey: otherPubkey,
          ownerName: null,
          threshold: 1,
          totalShares: 2,
          stewards: const [],
          recoveryRequests: [myRequest, otherRequest],
          pushEnabled: false,
          createdAt: DateTime(2024, 1, 1),
          archivedAt: null,
          archivedReason: null,
          backupConfig: null,
          latestShare: stewardShard,
        );

        final container = ProviderContainer(
          overrides: [
            vaultDetailProvider('test-vault').overrideWith((ref) => Stream.value(vaultDetail)),
            currentPublicKeyProvider.overrideWith((ref) async => testPubkey),
            recoveryStatusProvider.overrideWith((ref, vaultId) {
              return AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: true,
                  canRecover: false,
                  activeRecoveryRequest: otherRequest,
                  isInitiator: false,
                ),
              );
            }),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: VaultDetailScreen(vaultId: 'test-vault')),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Manage Recovery'), findsOneWidget);
        expect(find.text('Initiate Recovery'), findsNothing);

        container.dispose();
      },
    );

    testWidgets(
      'shows Manage Recovery for an owner with content and an active real recovery',
      (tester) async {
        final myRequest = RecoveryRequest(
          id: 'my-request',
          vaultId: 'test-vault',
          initiatorPubkey: testPubkey,
          requestedAt: DateTime(2024, 1, 1, 10),
          status: RecoveryRequestStatus.inProgress,
          threshold: 2,
        );

        // Owner restored content; still has an in-flight recovery.
        final vaultDetail = OwnedVaultDetail(
          id: 'test-vault',
          name: 'Test Vault',
          ownerPubkey: testPubkey,
          ownerName: null,
          threshold: 0,
          totalShares: 0,
          stewards: const [],
          recoveryRequests: [myRequest],
          pushEnabled: false,
          createdAt: DateTime(2024, 1, 1),
          archivedAt: null,
          archivedReason: null,
          backupConfig: null,
          content: 'ciphertext',
          selfHeldShare: null,
        );

        final container = ProviderContainer(
          overrides: [
            vaultDetailProvider('test-vault').overrideWith((ref) => Stream.value(vaultDetail)),
            currentPublicKeyProvider.overrideWith((ref) async => testPubkey),
            recoveryStatusProvider.overrideWith((ref, vaultId) {
              return AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: true,
                  canRecover: false,
                  activeRecoveryRequest: myRequest,
                  isInitiator: true,
                ),
              );
            }),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: VaultDetailScreen(vaultId: 'test-vault')),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Manage Recovery'), findsOneWidget);
        expect(find.text('Initiate Recovery'), findsNothing);

        container.dispose();
      },
    );

    testWidgets(
      'shows Manage Recovery when the current user\'s own request is completed',
      (tester) async {
        final stewardShard = createShare(
          payload: 'steward-shard-data',
          threshold: 1,
          shareIndex: 0,
          totalShares: 2,
          primeMod: 'test-prime-mod',
          creatorPubkey: otherPubkey,
          vaultId: 'test-vault',
          vaultName: 'Test Vault',
          distributionVersion: 1,
        );

        final myCompletedRequest = RecoveryRequest(
          id: 'my-completed-request',
          vaultId: 'test-vault',
          initiatorPubkey: testPubkey,
          requestedAt: DateTime(2024, 1, 1, 10),
          status: RecoveryRequestStatus.completed,
          threshold: 1,
        );

        final vaultDetail = StewardedVaultDetail(
          id: 'test-vault',
          name: 'Test Vault',
          ownerPubkey: otherPubkey,
          ownerName: null,
          threshold: 1,
          totalShares: 2,
          stewards: const [],
          recoveryRequests: [myCompletedRequest],
          pushEnabled: false,
          createdAt: DateTime(2024, 1, 1),
          archivedAt: null,
          archivedReason: null,
          backupConfig: null,
          latestShare: stewardShard,
        );

        final container = ProviderContainer(
          overrides: [
            vaultDetailProvider('test-vault').overrideWith((ref) => Stream.value(vaultDetail)),
            currentPublicKeyProvider.overrideWith((ref) async => testPubkey),
            recoveryStatusProvider.overrideWith((ref, vaultId) {
              return AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: true,
                  canRecover: true,
                  activeRecoveryRequest: myCompletedRequest,
                  isInitiator: true,
                ),
              );
            }),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: VaultDetailScreen(vaultId: 'test-vault')),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Manage Recovery'), findsOneWidget);
        expect(find.text('Initiate Recovery'), findsNothing);

        container.dispose();
      },
    );
  });
}
