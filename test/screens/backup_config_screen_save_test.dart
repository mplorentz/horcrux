import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/vault_detail.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/vault_detail_repository.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/backup_config_screen.dart';
import 'package:horcrux/services/backup_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:mockito/mockito.dart';
import '../helpers/secure_storage_mock.dart';

// Import mocks from backup_service_test
import '../services/backup_service_test.mocks.dart';

/// A VaultRepository that tracks calls for testing.
class _TrackingVaultRepository extends VaultRepository {
  BackupConfig? _config;
  final Vault? _vault;

  _TrackingVaultRepository({BackupConfig? config, Vault? vault})
      : _config = config,
        _vault = vault,
        super(LoginService());

  @override
  Future<BackupConfig?> getBackupConfig(String vaultId) async => _config;

  @override
  Future<Vault?> getVault(String vaultId) async => _vault;

  @override
  Future<void> updateBackupConfig(String vaultId, BackupConfig config) async {
    _config = config;
  }

  @override
  Future<void> setPushEnabled(String vaultId, bool enabled) async {}
}

/// A stub VaultDetailRepository that returns null for everything.
class _StubVaultDetailRepository extends VaultDetailRepository {
  _StubVaultDetailRepository() : super();

  @override
  Future<VaultDetail?> getVaultDetail(String vaultId) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStorageMock = SecureStorageMock();

  setUpAll(() {
    secureStorageMock.setUpAll();
  });

  tearDownAll(() {
    secureStorageMock.tearDownAll();
  });

  setUp(() async {
    secureStorageMock.clear();
  });

  group('BackupConfigScreen - Save with 0 stewards', () {
    /// Test: the Save button is visible even with 0 stewards.
    testWidgets('Save button is available when there are 0 stewards', (tester) async {
      final vault = Vault(
        id: 'test-vault',
        name: 'Test Vault',
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: 'a' * 64,
        pushEnabled: true,
      );
      final repo = _TrackingVaultRepository(config: null, vault: vault);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => repo),
          currentPublicKeyProvider.overrideWith((ref) async => 'a' * 64),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BackupConfigScreen(vaultId: 'test-vault'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The Save button should be visible even with 0 stewards.
      expect(find.text('Save'), findsOneWidget);

      // The Save button should be tappable (not disabled).
      final saveButton = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Save'),
          matching: find.byType(InkWell),
        ),
      );
      expect(saveButton.onTap, isNotNull);

      container.dispose();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    /// Test: tapping Save on a new vault with 0 stewards and a relay
    /// persists the relay. This is the bug: _handleSkip wraps the save
    /// in `if (existingConfig != null)`, so a new vault's config is lost.
    testWidgets('BUG: tapping Save on new vault persists relays with 0 stewards', (tester) async {
      final vault = Vault(
        id: 'test-vault',
        name: 'Test Vault',
        createdAt: DateTime(2024, 1, 1),
        ownerPubkey: 'a' * 64,
        pushEnabled: true,
      );
      final repo = _TrackingVaultRepository(config: null, vault: vault);

      // Create mocks for BackupService dependencies
      final mockRelayScan = MockRelayScanService();
      final mockLoginService = MockLoginService();
      final mockShareDistribution = MockShareDistributionService();
      final stubVaultDetailRepo = _StubVaultDetailRepository();

      // Stub RelayScanService methods that BackupService.saveBackupConfig calls
      when(mockRelayScan.syncRelaysFromUrls(any)).thenAnswer((_) async {});
      when(mockRelayScan.ensureScanningStarted()).thenAnswer((_) async {});
      when(mockLoginService.getStoredNostrKey()).thenAnswer((_) async => null);

      // Create a real BackupService with mock dependencies
      final backupService = BackupService(
        repo,
        stubVaultDetailRepo,
        mockShareDistribution,
        mockLoginService,
        mockRelayScan,
      );

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => repo),
          backupServiceProvider.overrideWith((ref) => backupService),
          currentPublicKeyProvider.overrideWith((ref) async => 'a' * 64),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BackupConfigScreen(vaultId: 'test-vault'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Save button is present
      expect(find.text('Save'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // After save, the config should have been persisted.
      // With the bug, the config is NOT saved because _handleSkip
      // checks `existingConfig != null` and skips the save for new vaults.
      final savedConfig = await repo.getBackupConfig('test-vault');
      expect(savedConfig, isNotNull,
          reason: 'BUG: Config was not saved for new vault with 0 stewards. '
              '_handleSkip wraps save in if (existingConfig != null).');

      container.dispose();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
