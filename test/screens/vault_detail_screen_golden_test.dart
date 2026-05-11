import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/screens/vault_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/golden_test_helpers.dart';
import '../helpers/shared_preferences_mock.dart';
import '../helpers/vault_detail_golden_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sharedPreferencesMock = SharedPreferencesMock();

  setUpAll(() {
    sharedPreferencesMock.setUpAll();
  });

  tearDownAll(() {
    sharedPreferencesMock.tearDownAll();
  });
  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey
  final otherPubkey = 'b' * 64;
  final thirdPubkey = 'c' * 64;

  // Helper to create shard data
  Share createTestShard({
    required int shardIndex,
    required String recipientPubkey,
    required String vaultId,
    String vaultName = 'Test Vault',
  }) {
    return createShare(
      payload: 'test_shard_$shardIndex',
      threshold: 2,
      shareIndex: shardIndex,
      totalShares: 3,
      primeMod: 'test_prime_mod',
      creatorPubkey: testPubkey,
      vaultId: vaultId,
      vaultName: vaultName,
      stewards: [
        {'name': 'Peer 1', 'pubkey': otherPubkey},
        {'name': 'Peer 2', 'pubkey': thirdPubkey},
      ],
      recipientPubkey: recipientPubkey,
      isReceived: true,
      receivedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
  }

  // Helper to create recovery request
  RecoveryRequest createTestRecoveryRequest({
    required String vaultId,
    required String initiatorPubkey,
    RecoveryRequestStatus status = RecoveryRequestStatus.inProgress,
    Map<String, RecoveryResponse>? responses,
  }) {
    return RecoveryRequest(
      id: 'recovery-$vaultId',
      vaultId: vaultId,
      initiatorPubkey: initiatorPubkey,
      requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
      status: status,
      threshold: 2,
      stewardResponses: responses ?? {},
    );
  }

  // Helper to create recovery response
  RecoveryResponse createTestRecoveryResponse({
    required String pubkey,
    required bool approved,
    DateTime? respondedAt,
  }) {
    return RecoveryResponse(
      pubkey: pubkey,
      approved: approved,
      respondedAt: respondedAt ?? DateTime.now().subtract(const Duration(minutes: 30)),
      share: approved
          ? createTestShard(
              shardIndex: 0,
              recipientPubkey: pubkey,
              vaultId: 'test-vault',
            )
          : null,
    );
  }

  group('VaultDetailScreen Golden Tests', () {
    setUp(() async {
      sharedPreferencesMock.clear();
      SharedPreferences.setMockInitialValues({});
    });

    testGoldens('loading state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const VaultDetailScreen(vaultId: 'test-vault'),
        overrides: [
          // Mock the vault provider to return loading state
          vaultDetailProvider('test-vault').overrideWith(
            (ref) => Stream.value(null).asyncMap((_) async {
              await Future.delayed(
                const Duration(seconds: 10),
              ); // Never completes to simulate loading
              return null;
            }),
          ),
        ],

        surfaceSize: const Size(
          375,
          1200,
        ), // Further increased height to prevent overflow
        waitForSettle: false, // Loading state has infinite animations
      );

      await screenMatchesGolden(tester, 'vault_detail_screen_loading');

      await harness.dispose();
    });

    testGoldens('error state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const VaultDetailScreen(vaultId: 'test-vault'),
        overrides: [
          // Mock provider to throw an error
          vaultDetailProvider(
            'test-vault',
          ).overrideWith((ref) => Stream.error('Failed to load vault')),
        ],

        surfaceSize: const Size(
          375,
          1000,
        ), // Increased height to handle overflow
      );

      await screenMatchesGolden(tester, 'vault_detail_screen_error');

      await harness.dispose();
    });

    testGoldens('vault not found', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const VaultDetailScreen(vaultId: 'test-vault'),
        overrides: [
          // Mock provider to return null (vault not found)
          vaultDetailProvider('test-vault').overrideWith((ref) => Stream.value(null)),
        ],

        surfaceSize: const Size(
          375,
          1000,
        ), // Increased height to handle overflow
      );

      await screenMatchesGolden(tester, 'vault_detail_screen_not_found');

      await harness.dispose();
    });

    testGoldens('owner - no backup configured', (tester) async {
      final ownedVault = Vault(
        id: 'test-vault',
        name: 'My Private Keys',
        createdAt: DateTime(2024, 10, 1, 10, 30),
        ownerPubkey: testPubkey, // No shards yet - backup not configured
        recoveryRequests: [],
      );

      final harness = await pumpGoldenWidget(
        tester,
        const VaultDetailScreen(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith(
            (ref) => Stream.value(ownedVaultDetailFromVault(ownedVault)),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],

        surfaceSize: const Size(
          375,
          1000,
        ), // Increased height to handle overflow
      );

      await screenMatchesGolden(tester, 'vault_detail_screen_owner_no_backup');

      await harness.dispose();
    });

    testGoldens('owner - backup configured, not in recovery', (tester) async {
      final ownedVault = Vault(
        id: 'test-vault',
        name: 'My Private Keys',
        createdAt: DateTime(2024, 10, 1, 10, 30),
        ownerPubkey: testPubkey,
        recoveryRequests: [], // No active recovery
        backupConfig: createBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createSteward(pubkey: testPubkey, name: 'You', isOwner: true),
            createSteward(pubkey: otherPubkey, name: 'Bob'),
            createSteward(pubkey: thirdPubkey, name: 'Charlie'),
          ],
          relays: const ['wss://relay.example.com'],
        ),
      );

      final harness = await pumpGoldenWidget(
        tester,
        const VaultDetailScreen(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith(
            (ref) => Stream.value(ownedVaultDetailFromVault(ownedVault)),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock recovery status to show no active recovery
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

        surfaceSize: const Size(
          375,
          1000,
        ), // Increased height to handle overflow
      );

      await screenMatchesGolden(
        tester,
        'vault_detail_screen_owner_backup_no_recovery',
      );

      await harness.dispose();
    });

    testGoldens('owner - in recovery', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        vaultId: 'test-vault',
        initiatorPubkey: testPubkey,
        status: RecoveryRequestStatus.inProgress,
        responses: {
          otherPubkey: createTestRecoveryResponse(
            pubkey: otherPubkey,
            approved: true,
          ),
          thirdPubkey: createTestRecoveryResponse(
            pubkey: thirdPubkey,
            approved: false,
          ),
        },
      );

      final ownedVault = Vault(
        id: 'test-vault',
        name: 'My Private Keys',
        createdAt: DateTime(2024, 10, 1, 10, 30),
        ownerPubkey: testPubkey,
        recoveryRequests: [recoveryRequest],
        backupConfig: createBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createSteward(pubkey: testPubkey, name: 'You', isOwner: true),
            createSteward(pubkey: otherPubkey, name: 'Bob'),
            createSteward(pubkey: thirdPubkey, name: 'Charlie'),
          ],
          relays: const ['wss://relay.example.com'],
        ),
      );

      final harness = await pumpGoldenWidget(
        tester,
        const VaultDetailScreen(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith(
            (ref) => Stream.value(ownedVaultDetailFromVault(ownedVault)),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock recovery status to show active recovery
          recoveryStatusProvider.overrideWith((ref, vaultId) {
            return AsyncValue.data(
              RecoveryStatus(
                hasActiveRecovery: true,
                canRecover: true, // Has enough approvals
                activeRecoveryRequest: recoveryRequest,
                isInitiator: true, // testPubkey is the initiator
              ),
            );
          }),
        ],

        surfaceSize: const Size(
          375,
          1000,
        ), // Increased height to handle overflow
      );

      await screenMatchesGolden(
        tester,
        'vault_detail_screen_owner_in_recovery',
      );

      await harness.dispose();
    });

    testGoldens('shard holder - not in recovery', (tester) async {
      final shardHolderVault = Vault(
        id: 'test-vault',
        name: "Alice's Backup",
        createdAt: DateTime(2024, 9, 15, 14, 20),
        ownerPubkey: otherPubkey, // Different owner
        recoveryRequests: [], // No active recovery
      );

      final harness = await pumpGoldenWidget(
        tester,
        const VaultDetailScreen(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith(
            (ref) => Stream.value(
              stewardedVaultDetailFromVault(
                shardHolderVault,
                latestShare: createTestShard(
                  shardIndex: 0,
                  recipientPubkey: testPubkey,
                  vaultId: 'test-vault',
                ),
              ),
            ),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock recovery status to show no active recovery
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

        surfaceSize: const Size(
          375,
          1000,
        ), // Increased height to handle overflow
      );

      await screenMatchesGolden(
        tester,
        'vault_detail_screen_shard_holder_no_recovery',
      );

      await harness.dispose();
    });

    testGoldens('shard holder - in recovery', (tester) async {
      final recoveryRequest = createTestRecoveryRequest(
        vaultId: 'test-vault',
        initiatorPubkey: testPubkey, // testPubkey (shard holder) is the initiator
        status: RecoveryRequestStatus.inProgress,
        responses: {
          testPubkey: createTestRecoveryResponse(
            pubkey: testPubkey,
            approved: true,
          ),
          thirdPubkey: createTestRecoveryResponse(
            pubkey: thirdPubkey,
            approved: false,
          ),
        },
      );

      final shardHolderVault = Vault(
        id: 'test-vault',
        name: "Alice's Backup",
        createdAt: DateTime(2024, 9, 15, 14, 20),
        ownerPubkey: otherPubkey, // Different owner
        recoveryRequests: [recoveryRequest],
      );

      final harness = await pumpGoldenWidget(
        tester,
        const VaultDetailScreen(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith(
            (ref) => Stream.value(
              stewardedVaultDetailFromVault(
                shardHolderVault,
                latestShare: createTestShard(
                  shardIndex: 0,
                  recipientPubkey: testPubkey,
                  vaultId: 'test-vault',
                ),
              ),
            ),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock recovery status to show active recovery
          recoveryStatusProvider.overrideWith((ref, vaultId) {
            return AsyncValue.data(
              RecoveryStatus(
                hasActiveRecovery: true,
                canRecover: false, // Not enough approvals yet
                activeRecoveryRequest: recoveryRequest,
                isInitiator: true, // testPubkey is the initiator
              ),
            );
          }),
        ],

        surfaceSize: const Size(
          375,
          1000,
        ), // Increased height to handle overflow
      );

      await screenMatchesGolden(
        tester,
        'vault_detail_screen_shard_holder_in_recovery',
      );

      await harness.dispose();
    });

    testGoldens('awaiting key state - invitee waiting for shard', (
      tester,
    ) async {
      final awaitingKeyVault = Vault(
        id: 'test-vault',
        name: "Bob's Shared Vault",
        createdAt: DateTime(2024, 9, 25, 16, 45),
        ownerPubkey: otherPubkey, // Different owner // No shards yet - awaiting key distribution
        recoveryRequests: [],
      );

      final harness = await pumpGoldenWidget(
        tester,
        const VaultDetailScreen(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider(
            'test-vault',
          ).overrideWith(
            (ref) => Stream.value(
              stewardedVaultDetailFromVault(
                awaitingKeyVault,
                latestShare: null,
              ),
            ),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock recovery status to show no active recovery
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

        surfaceSize: const Size(
          375,
          1000,
        ), // Increased height to handle overflow
      );

      await screenMatchesGolden(tester, 'vault_detail_screen_awaiting_key');

      await harness.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final ownedVault = Vault(
        id: 'test-vault',
        name: 'My Private Keys',
        createdAt: DateTime(2024, 10, 1, 10, 30),
        ownerPubkey: testPubkey,
        recoveryRequests: [],
        backupConfig: createBackupConfig(
          vaultId: 'test-vault',
          threshold: 2,
          totalKeys: 3,
          stewards: [
            createSteward(pubkey: testPubkey, name: 'You', isOwner: true),
            createSteward(pubkey: otherPubkey, name: 'Bob'),
            createSteward(pubkey: thirdPubkey, name: 'Charlie'),
          ],
          relays: const ['wss://relay.example.com'],
        ),
      );

      final harness = GoldenTestHarness.withOverrides([
        vaultDetailProvider(
          'test-vault',
        ).overrideWith(
          (ref) => Stream.value(ownedVaultDetailFromVault(ownedVault)),
        ),
        currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        // Mock recovery status to show no active recovery
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
      ]);

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: const VaultDetailScreen(vaultId: 'test-vault'),
          name: 'owner_backup_no_recovery',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: harness.container,
        ),
      );

      await screenMatchesGolden(tester, 'vault_detail_screen_multiple_devices');

      await harness.dispose();
    });

    testGoldens('recovery notification', (tester) async {
      // Create a recovery request initiated by someone else (not testPubkey)
      final recoveryRequest = RecoveryRequest(
        id: 'recovery-1',
        vaultId: 'test-vault',
        initiatorPubkey: otherPubkey, // Different from testPubkey
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardResponses: {},
      );

      final ownedVault = Vault(
        id: 'test-vault',
        name: 'My Private Keys',
        createdAt: DateTime(2024, 10, 1, 10, 30),
        ownerPubkey: testPubkey,
        recoveryRequests: [],
      );

      final harness = await pumpGoldenWidget(
        tester,
        const VaultDetailScreen(vaultId: 'test-vault'),
        overrides: [
          vaultDetailProvider('test-vault').overrideWith(
            (ref) => Stream.value(ownedVaultDetailFromVault(ownedVault)),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
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
          // Mock pending recovery requests provider to return the request
          pendingRecoveryRequestsProvider.overrideWith(
            (ref) => Stream.value([recoveryRequest]),
          ),
        ],
        surfaceSize: const Size(375, 1000),
      );

      await screenMatchesGolden(
        tester,
        'vault_detail_screen_with_banner',
      );

      await harness.dispose();
    });
  });
}
