import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/screens/backup_config_screen.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/golden_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel sharedPreferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );
  final Map<String, dynamic> sharedPreferencesStore = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sharedPreferencesChannel, (call) async {
          final args = call.arguments as Map? ?? {};
          if (call.method == 'getAll') {
            return Map<String, dynamic>.from(sharedPreferencesStore);
          } else if (call.method == 'setString') {
            sharedPreferencesStore[args['key']] = args['value'];
            return true;
          } else if (call.method == 'getString') {
            return sharedPreferencesStore[args['key']];
          } else if (call.method == 'remove') {
            sharedPreferencesStore.remove(args['key']);
            return true;
          } else if (call.method == 'getStringList') {
            final value = sharedPreferencesStore[args['key']];
            return value is List ? value : null;
          } else if (call.method == 'setStringList') {
            sharedPreferencesStore[args['key']] = args['value'];
            return true;
          } else if (call.method == 'clear') {
            sharedPreferencesStore.clear();
            return true;
          }
          return null;
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sharedPreferencesChannel, null);
  });

  // Sample test data
  final steward1Pubkey = 'b' * 64;
  final steward2Pubkey = 'c' * 64;

  // Helper to create stewards
  Steward createTestSteward({
    required String pubkey,
    String? name,
    StewardStatus status = StewardStatus.awaitingKey,
  }) {
    return createSteward(pubkey: pubkey, name: name);
  }

  Steward createTestInvitedSteward({
    required String name,
    required String inviteCode,
  }) {
    return createInvitedSteward(name: name, inviteCode: inviteCode);
  }

  // Helper to create backup config
  BackupConfig createTestBackupConfig({
    required String vaultId,
    required int threshold,
    required List<Steward> stewards,
    required List<String> relays,
  }) {
    return createBackupConfig(
      vaultId: vaultId,
      threshold: threshold,
      totalKeys: stewards.length,
      stewards: stewards,
      relays: relays,
    );
  }

  group('BackupConfigScreen Golden Tests', () {
    setUp(() async {
      sharedPreferencesStore.clear();
      SharedPreferences.setMockInitialValues({});
    });

    testGoldens('loading state', (tester) async {
      // Create a repository that never completes loading
      final mockRepository = _MockVaultRepository(null, neverCompletes: true);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(vaultId: 'test-vault'),
        container: container,
        waitForSettle: false, // Loading state
      );

      await screenMatchesGoldenWithoutSettle<BackupConfigScreen>(
        tester,
        'backup_config_screen_loading',
      );

      container.dispose();
    });

    testGoldens('empty state - no existing config', (tester) async {
      // Create a repository that returns null (no existing config)
      final mockRepository = _MockVaultRepository(null);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 1000), // Taller to show full form
      );

      await screenMatchesGolden(tester, 'backup_config_screen_empty');

      container.dispose();
    });

    testGoldens('with existing config - manual stewards', (tester) async {
      final stewards = [
        createTestSteward(
          pubkey: steward1Pubkey,
          name: 'Alice',
          status: StewardStatus.awaitingKey,
        ),
        createTestSteward(
          pubkey: steward2Pubkey,
          name: 'Bob',
          status: StewardStatus.awaitingKey,
        ),
      ];

      final backupConfig = createTestBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        stewards: stewards,
        relays: ['wss://relay1.example.com', 'wss://relay2.example.com'],
      );

      final mockRepository = _MockVaultRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 1200), // Taller to show all stewards
      );

      await screenMatchesGolden(
        tester,
        'backup_config_screen_manual_key_holders',
      );

      container.dispose();
    });

    testGoldens('with existing config - invited stewards', (tester) async {
      final stewards = [
        createTestInvitedSteward(
          name: 'Charlie',
          inviteCode: 'invite-code-123',
        ),
        createTestInvitedSteward(name: 'Diana', inviteCode: 'invite-code-456'),
      ];

      final backupConfig = createTestBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        stewards: stewards,
        relays: ['wss://relay.example.com'],
      );

      final mockRepository = _MockVaultRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(
        tester,
        'backup_config_screen_invited_key_holders',
      );

      container.dispose();
    });

    testGoldens('with existing config - mixed stewards', (tester) async {
      final stewards = [
        createTestSteward(
          pubkey: steward1Pubkey,
          name: 'Eve',
          status: StewardStatus.holdingKey,
        ),
        createTestInvitedSteward(name: 'Frank', inviteCode: 'invite-code-789'),
      ];

      final backupConfig = createTestBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        stewards: stewards,
        relays: [
          'wss://relay1.example.com',
          'wss://relay2.example.com',
          'wss://relay3.example.com',
        ],
      );

      final mockRepository = _MockVaultRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 1200),
      );

      await screenMatchesGolden(
        tester,
        'backup_config_screen_mixed_key_holders',
      );

      container.dispose();
    });

    testGoldens('with existing config - multiple relays', (tester) async {
      final stewards = [
        createTestSteward(pubkey: steward1Pubkey, name: 'Grace'),
      ];

      final backupConfig = createTestBackupConfig(
        vaultId: 'test-vault',
        threshold: 1,
        stewards: stewards,
        relays: [
          'wss://relay1.example.com',
          'wss://relay2.example.com',
          'wss://relay3.example.com',
        ],
      );

      final mockRepository = _MockVaultRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      await pumpGoldenWidget(
        tester,
        const BackupConfigScreen(vaultId: 'test-vault'),
        container: container,
        surfaceSize: const Size(375, 1000),
      );

      await screenMatchesGolden(tester, 'backup_config_screen_multiple_relays');

      container.dispose();
    });

    testGoldens('multiple device sizes', (tester) async {
      final stewards = [
        createTestSteward(pubkey: steward1Pubkey, name: 'Henry'),
        createTestSteward(pubkey: steward2Pubkey, name: 'Iris'),
      ];

      final backupConfig = createTestBackupConfig(
        vaultId: 'test-vault',
        threshold: 2,
        stewards: stewards,
        relays: ['wss://relay.example.com'],
      );

      final mockRepository = _MockVaultRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(
          devices: [Device.phone, Device.iphone11, Device.tabletPortrait],
        )
        ..addScenario(
          widget: const BackupConfigScreen(vaultId: 'test-vault'),
          name: 'with_key_holders',
        );

      await tester.pumpDeviceBuilder(
        builder,
        wrapper: (child) => goldenMaterialAppWrapperWithProviders(
          child: child,
          container: container,
        ),
      );

      await screenMatchesGolden(
        tester,
        'backup_config_screen_multiple_devices',
      );

      container.dispose();
    });
  });
}

/// Mock VaultRepository for testing
class _MockVaultRepository extends VaultRepository {
  final BackupConfig? _backupConfig;
  final bool _neverCompletes;

  _MockVaultRepository(this._backupConfig, {bool neverCompletes = false})
    : _neverCompletes = neverCompletes,
      super(LoginService());

  @override
  Future<BackupConfig?> getBackupConfig(String vaultId) async {
    if (_neverCompletes) {
      // Use a Completer that never completes to simulate loading state
      final completer = Completer<BackupConfig?>();
      return completer.future; // This will never complete
    }
    return _backupConfig;
  }
}
