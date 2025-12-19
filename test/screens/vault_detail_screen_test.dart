import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/shard_data.dart';
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
}
