import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/shard_data.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/screens/vault_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testPubkey = 'a' * 64;
  final otherPubkey = 'b' * 64;

  // T030: Widget test for owner-steward vault detail buttons
  group('Owner-steward vault detail buttons', () {
    testWidgets('shows Initiate Recovery and Change Vault Contents for owner-steward state', (
      tester,
    ) async {
      // Owner-steward state: isOwner, content == null, shards.isNotEmpty
      final ownerShard = createShardData(
        shard: 'owner-shard-data',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
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

      // Vault with no content but has shards (owner-steward state)
      final vault = Vault(
        id: 'test-vault',
        name: 'Test Vault',
        content: null, // Content deleted
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: testPubkey, // Current user is owner
        shards: [ownerShard], // Has owner shard
        backupConfig: backupConfig,
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider('test-vault').overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith((ref) async => testPubkey),
          recoveryStatusProvider.overrideWith((ref, vaultId) {
            return const AsyncValue.data(
              RecoveryStatus(
                hasActiveRecovery: false,
                canRecover: false,
                activeRecoveryRequest: null,
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

      // Verify owner-steward buttons are shown
      expect(find.text('Initiate Recovery'), findsOneWidget);
      expect(find.text('Change Vault Contents'), findsOneWidget);

      container.dispose();
    });

    testWidgets(
      'shows Delete Local Copy button when owner has content and owner steward configured',
      (tester) async {
        final ownerSteward = createOwnerSteward(pubkey: testPubkey);
        final otherSteward = createSteward(pubkey: otherPubkey, name: 'Alice');

        final lastRedistributionTime = DateTime.now().subtract(const Duration(hours: 1));
        final backupConfig = copyBackupConfig(
          createBackupConfig(
            vaultId: 'test-vault',
            threshold: 2,
            totalKeys: 2,
            stewards: [ownerSteward, otherSteward],
            relays: ['wss://relay.example.com'],
          ),
          lastRedistribution: lastRedistributionTime,
          lastUpdated:
              lastRedistributionTime, // Set lastUpdated to same time to prevent needsRedistribution
        );

        // Vault with content and owner steward configured (after distribution)
        final vault = Vault(
          id: 'test-vault',
          name: 'Test Vault',
          content: 'Secret content', // Has content
          createdAt: DateTime(2024, 1, 1),
          ownerPubkey: testPubkey, // Current user is owner
          shards: [],
          backupConfig: backupConfig,
        );

        final container = ProviderContainer(
          overrides: [
            vaultProvider('test-vault').overrideWith((ref) => Stream.value(vault)),
            currentPublicKeyProvider.overrideWith((ref) async => testPubkey),
            recoveryStatusProvider.overrideWith((ref, vaultId) {
              return const AsyncValue.data(
                RecoveryStatus(
                  hasActiveRecovery: false,
                  canRecover: false,
                  activeRecoveryRequest: null,
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

        // Verify Delete Local Copy button is shown
        expect(find.text('Delete Local Copy'), findsOneWidget);

        container.dispose();
      },
    );

    testWidgets('shows Delete Local Copy after distribution even without owner steward', (
      tester,
    ) async {
      // Only regular stewards, no owner steward
      final steward1 = createSteward(pubkey: otherPubkey, name: 'Alice');

      final lastRedistributionTime = DateTime.now().subtract(const Duration(hours: 1));
      final backupConfig = copyBackupConfig(
        createBackupConfig(
          vaultId: 'test-vault',
          threshold: 1,
          totalKeys: 1,
          stewards: [steward1],
          relays: ['wss://relay.example.com'],
        ),
        lastRedistribution: lastRedistributionTime,
        lastUpdated:
            lastRedistributionTime, // Set lastUpdated to same time to prevent needsRedistribution
      );

      // Vault with content but no owner steward
      final vault = Vault(
        id: 'test-vault',
        name: 'Test Vault',
        content: 'Secret content',
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: testPubkey,
        shards: [],
        backupConfig: backupConfig,
      );

      final container = ProviderContainer(
        overrides: [
          vaultProvider('test-vault').overrideWith((ref) => Stream.value(vault)),
          currentPublicKeyProvider.overrideWith((ref) async => testPubkey),
          recoveryStatusProvider.overrideWith((ref, vaultId) {
            return const AsyncValue.data(
              RecoveryStatus(
                hasActiveRecovery: false,
                canRecover: false,
                activeRecoveryRequest: null,
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

      // Verify Delete Local Copy button IS shown after distribution (owner steward not required)
      expect(find.text('Delete Local Copy'), findsOneWidget);

      container.dispose();
    });
  });

  // Concurrent multi-initiator scenario: per-user exclusivity allows two
  // distinct users to each hold an active real recovery on the same vault.
  // The current user must still see "Manage Recovery" pointing at THEIR own
  // request, even when another user's request is the most-recent one
  // recoveryStatusProvider would surface as `activeRecoveryRequest`.
  group('Steward vault detail buttons with concurrent multi-initiator recoveries', () {
    testWidgets(
      'shows Manage Recovery for the current user when another user has a newer active recovery',
      (tester) async {
        final stewardShard = createShardData(
          shard: 'steward-shard-data',
          threshold: 1,
          shardIndex: 0,
          totalShards: 2,
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

        // Vault is owned by `otherPubkey`; current user holds a shard, so they
        // are a (non-owner) steward. Both active recoveries live on the vault.
        final vault = Vault(
          id: 'test-vault',
          name: 'Test Vault',
          content: null,
          createdAt: DateTime(2024, 1, 1),
          ownerPubkey: otherPubkey,
          shards: [stewardShard],
          recoveryRequests: [myRequest, otherRequest],
        );

        final container = ProviderContainer(
          overrides: [
            vaultProvider('test-vault').overrideWith((ref) => Stream.value(vault)),
            currentPublicKeyProvider.overrideWith((ref) async => testPubkey),
            // Mirror what the real recoveryStatusProvider does: pick the
            // most-recent request, regardless of initiator. With per-user
            // exclusivity that representative can be someone else's, and
            // `isInitiator` reflects only that single representative.
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

        // The user must be able to manage their own active recovery.
        expect(find.text('Manage Recovery'), findsOneWidget);
        // They should NOT be offered Initiate (per-user exclusivity).
        expect(find.text('Initiate Recovery'), findsNothing);

        container.dispose();
      },
    );

    // Regression: once enough stewards approve, the user's request transitions
    // to `RecoveryRequestStatus.completed` but is still manageable -- the user
    // finalizes the recovery from the same Manage screen by tapping "Recover
    // Vault". If the widget filters by `isActive` only, that path disappears
    // and the user is incorrectly offered "Initiate Recovery" again.
    testWidgets(
      'shows Manage Recovery when the current user\'s own request is completed',
      (tester) async {
        final stewardShard = createShardData(
          shard: 'steward-shard-data',
          threshold: 1,
          shardIndex: 0,
          totalShards: 2,
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

        final vault = Vault(
          id: 'test-vault',
          name: 'Test Vault',
          content: null,
          createdAt: DateTime(2024, 1, 1),
          ownerPubkey: otherPubkey,
          shards: [stewardShard],
          recoveryRequests: [myCompletedRequest],
        );

        final container = ProviderContainer(
          overrides: [
            vaultProvider('test-vault').overrideWith((ref) => Stream.value(vault)),
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
