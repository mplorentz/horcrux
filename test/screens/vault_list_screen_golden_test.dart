import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/shard_data.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/recovery_provider.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/screens/vault_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/golden_test_helpers.dart';
import '../helpers/shared_preferences_mock.dart';

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

  final ownedVault = Vault(
    id: 'vault-1',
    name: 'My Private Keys',
    content: 'nsec1...',
    createdAt: DateTime(2024, 10, 1, 10, 30),
    ownerPubkey: testPubkey,
    shards: [],
    recoveryRequests: [],
  );

  final keyHolderVault = Vault(
    id: 'vault-2',
    name: "Alice's Backup",
    content: null,
    createdAt: DateTime(2024, 9, 15, 14, 20),
    ownerPubkey: otherPubkey,
    shards: [
      createShardData(
        shard: 'test_shard_data',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
        primeMod: 'test_prime_mod',
        creatorPubkey: otherPubkey,
      ),
    ],
    recoveryRequests: [],
  );

  final awaitingKeyVault = Vault(
    id: 'vault-awaiting',
    name: "Bob's Shared Vault",
    content: null,
    createdAt: DateTime(2024, 9, 25, 16, 45),
    ownerPubkey: otherPubkey,
    shards: [], // No shards yet - awaiting key distribution
    recoveryRequests: [],
  );

  final multipleVaults = [
    ownedVault,
    keyHolderVault,
    awaitingKeyVault,
    Vault(
      id: 'vault-3',
      name: 'Work Documents',
      content: null,
      createdAt: DateTime(2024, 9, 20, 9, 15),
      ownerPubkey: testPubkey,
      shards: [],
      recoveryRequests: [],
    ),
  ];

  group('VaultListScreen Golden Tests', () {
    setUp(() async {
      sharedPreferencesMock.clear();
      SharedPreferences.setMockInitialValues({});
    });

    testGoldens('empty state - no vaults', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // Mock the vault stream provider to return empty list
          vaultListProvider.overrideWith((ref) => Stream.value([])),
          // Mock the current user's pubkey
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        container: container,
        surfaceSize: const Size(375, 667), // iPhone SE size
      );

      await screenMatchesGolden(tester, 'vault_list_screen_empty');

      container.dispose();
    });

    // Note: Loading state test is skipped as it's difficult to capture
    // without pumpAndSettle timing out. The loading state uses a simple
    // CircularProgressIndicator which is well-tested by Flutter itself.

    testGoldens('error state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // Mock provider to throw an error
          vaultListProvider.overrideWith(
            (ref) => Stream.error('Failed to load vaults'),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        container: container,
      );

      await screenMatchesGolden(tester, 'vault_list_screen_error');

      container.dispose();
    });

    testGoldens('single owned vault', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vaultListProvider.overrideWith((ref) => Stream.value([ownedVault])),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        container: container,
      );

      await screenMatchesGolden(tester, 'vault_list_screen_single_owned');

      container.dispose();
    });

    testGoldens('single steward vault', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vaultListProvider.overrideWith(
            (ref) => Stream.value([keyHolderVault]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        container: container,
      );

      await screenMatchesGolden(tester, 'vault_list_screen_single_key_holder');

      container.dispose();
    });

    testGoldens('single awaiting key vault', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vaultListProvider.overrideWith(
            (ref) => Stream.value([awaitingKeyVault]),
          ),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        container: container,
      );

      await screenMatchesGolden(
        tester,
        'vault_list_screen_single_awaiting_key',
      );

      container.dispose();
    });

    testGoldens('multiple vaults', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vaultListProvider.overrideWith((ref) => Stream.value(multipleVaults)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        container: container,
      );

      await screenMatchesGolden(tester, 'vault_list_screen_multiple');

      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final container = ProviderContainer(
        overrides: [
          vaultListProvider.overrideWith((ref) => Stream.value(multipleVaults)),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(widget: const VaultListScreen(), name: 'multiple_vaults');

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: container,
        ),
      );

      await screenMatchesGolden(tester, 'vault_list_screen_multiple_devices');

      container.dispose();
    });

    testGoldens('recovery notification', (tester) async {
      // Create a recovery request initiated by someone else (not testPubkey)
      final recoveryRequest = RecoveryRequest(
        id: 'recovery-1',
        vaultId: 'vault-1',
        initiatorPubkey: otherPubkey, // Different from testPubkey
        requestedAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RecoveryRequestStatus.inProgress,
        threshold: 2,
        stewardResponses: {},
      );

      final container = ProviderContainer(
        overrides: [
          vaultListProvider.overrideWith((ref) => Stream.value([ownedVault])),
          currentPublicKeyProvider.overrideWith((ref) => testPubkey),
          // Mock pending recovery requests provider to return the request
          pendingRecoveryRequestsProvider.overrideWith(
            (ref) => Stream.value([recoveryRequest]),
          ),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const VaultListScreen(),
        container: container,
      );

      await screenMatchesGolden(tester, 'vault_list_screen_with_banner');

      container.dispose();
    });
  });
}
