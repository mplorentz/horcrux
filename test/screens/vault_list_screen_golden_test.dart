import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault_detail.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/screens/vault_list_screen.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Sample test data
  final testPubkey = 'a' * 64; // 64-char hex pubkey
  final otherPubkey = 'b' * 64;

  final ownedVault = OwnedVaultDetail(
    id: 'vault-1',
    name: 'My Private Keys',
    ownerPubkey: testPubkey,
    ownerName: null,
    threshold: 0,
    totalShares: 0,
    stewards: const [],
    recoveryRequests: const [],
    pushEnabled: true,
    createdAt: DateTime(2024, 10, 1, 10, 30),
    archivedAt: null,
    archivedReason: null,
    backupConfig: null,
    content: 'ciphertext',
    selfHeldShare: null,
  );

  final keyHolderVault = StewardedVaultDetail(
    id: 'vault-2',
    name: "Alice's Backup",
    ownerPubkey: otherPubkey,
    ownerName: null,
    threshold: 2,
    totalShares: 3,
    stewards: const [],
    recoveryRequests: const [],
    pushEnabled: false,
    createdAt: DateTime(2024, 9, 15, 14, 20),
    archivedAt: null,
    archivedReason: null,
    backupConfig: null,
    latestShare: createShare(
      payload: 'test_shard_data',
      threshold: 2,
      shareIndex: 0,
      totalShares: 3,
      primeMod: 'test_prime_mod',
      creatorPubkey: otherPubkey,
    ),
  );

  final awaitingKeyVault = StewardedVaultDetail(
    id: 'vault-awaiting',
    name: "Bob's Shared Vault",
    ownerPubkey: otherPubkey,
    ownerName: null,
    threshold: 0,
    totalShares: 0,
    stewards: const [],
    recoveryRequests: const [],
    pushEnabled: false,
    createdAt: DateTime(2024, 9, 25, 16, 45),
    archivedAt: null,
    archivedReason: null,
    backupConfig: null,
    latestShare: null,
  );

  final multipleVaults = [
    ownedVault,
    keyHolderVault,
    awaitingKeyVault,
    OwnedVaultDetail(
      id: 'vault-3',
      name: 'Work Documents',
      ownerPubkey: testPubkey,
      ownerName: null,
      threshold: 0,
      totalShares: 0,
      stewards: const [],
      recoveryRequests: const [],
      pushEnabled: true,
      createdAt: DateTime(2024, 9, 20, 9, 15),
      archivedAt: null,
      archivedReason: null,
      backupConfig: null,
      content: 'ciphertext',
      selfHeldShare: null,
    ),
  ];

  group('VaultListScreen Golden Tests', () {
    setUp(() async {});

    testGoldens('empty state - no vaults', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        overrides: [
          // Mock the vault stream provider to return empty list
          vaultDetailListProvider.overrideWith((ref) => Stream.value([])),
          // Mock the current user's pubkey
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],

        surfaceSize: const Size(375, 667), // iPhone SE size
      );

      await screenMatchesGolden(tester, 'vault_list_screen_empty');

      await harness.dispose();
    });

    // Note: Loading state test is skipped as it's difficult to capture
    // without pumpAndSettle timing out. The loading state uses a simple
    // CircularProgressIndicator which is well-tested by Flutter itself.

    testGoldens('error state', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        overrides: [
          // Mock provider to throw an error
          vaultDetailListProvider.overrideWith(
            (ref) => Stream.error('Failed to load vaults'),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await screenMatchesGolden(tester, 'vault_list_screen_error');

      await harness.dispose();
    });

    testGoldens('single owned vault', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        overrides: [
          vaultDetailListProvider.overrideWith((ref) => Stream.value([ownedVault])),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await screenMatchesGolden(tester, 'vault_list_screen_single_owned');

      await harness.dispose();
    });

    testGoldens('single steward vault', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        overrides: [
          vaultDetailListProvider.overrideWith(
            (ref) => Stream.value([keyHolderVault]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await screenMatchesGolden(tester, 'vault_list_screen_single_key_holder');

      await harness.dispose();
    });

    testGoldens('single awaiting key vault', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        overrides: [
          vaultDetailListProvider.overrideWith(
            (ref) => Stream.value([awaitingKeyVault]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await screenMatchesGolden(
        tester,
        'vault_list_screen_single_awaiting_key',
      );

      await harness.dispose();
    });

    testGoldens('multiple vaults', (tester) async {
      final harness = await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        overrides: [
          vaultDetailListProvider.overrideWith((ref) => Stream.value(multipleVaults)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await screenMatchesGolden(tester, 'vault_list_screen_multiple');

      await harness.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final harness = GoldenTestHarness.withOverrides([
        vaultDetailListProvider.overrideWith((ref) => Stream.value(multipleVaults)),
        currentPublicKeyProvider.overrideWith((ref) => testPubkey),
      ]);

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(widget: const VaultListScreen(), name: 'multiple_vaults');

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: harness.container,
        ),
      );

      await screenMatchesGolden(tester, 'vault_list_screen_multiple_devices');

      await harness.dispose();
    });

    testGoldens('owner vault with no local content (holding shard)', (tester) async {
      // Vault owned by testPubkey but with no content, only a shard
      // This simulates the owner deleting local content while still holding a recovery shard
      final ownerHoldingShardVault = StewardedVaultDetail(
        id: 'vault-owner-holding-shard',
        name: 'Owner Without Content',
        ownerPubkey: testPubkey,
        ownerName: null,
        threshold: 2,
        totalShares: 3,
        stewards: const [],
        recoveryRequests: const [],
        pushEnabled: false,
        createdAt: DateTime(2024, 10, 5, 12, 0),
        archivedAt: null,
        archivedReason: null,
        backupConfig: null,
        latestShare: createShare(
          payload: 'owner_shard_data',
          threshold: 2,
          shareIndex: 1,
          totalShares: 3,
          primeMod: 'test_prime_mod',
          creatorPubkey: testPubkey,
        ),
      );

      final harness = await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        overrides: [
          vaultDetailListProvider.overrideWith(
            (ref) => Stream.value([ownerHoldingShardVault]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await screenMatchesGolden(
        tester,
        'vault_list_screen_owner_holding_shard',
      );

      await harness.dispose();
    });

    testGoldens('recovery notification', (tester) async {
      // Create a recovery request initiated by someone else (not testPubkey)
      final recoveryRequest = RecoveryRequest.makeFromParticipants(
        id: 'recovery-1',
        vaultId: 'vault-1',
        initiatorPubkey: otherPubkey, // Different from testPubkey
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardPubkeys: const [],
      );

      final harness = await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        overrides: [
          vaultDetailListProvider.overrideWith((ref) => Stream.value([ownedVault])),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock pending recovery requests provider to return the request
          pendingRecoveryRequestsProvider.overrideWith(
            (ref) => Stream.value([recoveryRequest]),
          ),
        ],
      );

      await screenMatchesGolden(tester, 'vault_list_screen_with_banner');

      await harness.dispose();
    });
  });
}
