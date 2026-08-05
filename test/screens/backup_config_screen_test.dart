import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/backup_config_screen.dart';
import 'package:horcrux/services/login_service.dart';
import '../helpers/secure_storage_mock.dart';

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

  // T029: Widget test for self-shard toggle in backup config
  group('Self-shard toggle', () {
    testWidgets('toggle is displayed', (tester) async {
      final mockRepository = _MockVaultRepository(null);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
          currentPublicKeyProvider.overrideWith((ref) async => 'a' * 64),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BackupConfigScreen(vaultId: 'test-vault')),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the self-steward toggle is displayed
      expect(find.text('Include yourself?'), findsOneWidget);
      expect(
        find.text(
          'You\'ll receive a key like your stewards, allowing you to participate in recovery.',
        ),
        findsOneWidget,
      );
      expect(find.text('Enable push notifications'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(2));

      container.dispose();
      // Drift schedules a short timer when stream query subscriptions cancel
      // (e.g. [VaultDetailRepository.dispose]); flush it before the binding
      // asserts no pending timers.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('toggle starts disabled for new config', (tester) async {
      final mockRepository = _MockVaultRepository(null);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
          currentPublicKeyProvider.overrideWith((ref) async => 'a' * 64),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BackupConfigScreen(vaultId: 'test-vault')),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the "Include yourself" toggle starts disabled
      final switchWidget = tester.widget<Switch>(find.byKey(const ValueKey('self_steward_switch')));
      expect(switchWidget.value, isFalse);

      container.dispose();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('toggle enabled when config has owner steward', (tester) async {
      final ownerPubkey = 'a' * 64;
      final ownerSteward = createOwnerSteward(pubkey: ownerPubkey);
      final backupConfig = createBackupConfig(
        vaultId: 'test-vault',
        threshold: 1,
        totalKeys: 1,
        stewards: [ownerSteward],
        relays: ['wss://relay.example.com'],
      );

      final mockRepository = _MockVaultRepository(backupConfig);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
          currentPublicKeyProvider.overrideWith((ref) async => ownerPubkey),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BackupConfigScreen(vaultId: 'test-vault')),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the "Include yourself" toggle is on when owner steward exists
      final switchWidget = tester.widget<Switch>(find.byKey(const ValueKey('self_steward_switch')));
      expect(switchWidget.value, isTrue);

      container.dispose();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  // horcrux_app-7ss4: a plan with no stewards is incomplete, not unsaveable.
  // It still carries relays and instructions, and Save must persist them.
  group('Zero-steward save', () {
    testWidgets('the discard-changes dialog offers Save with no stewards', (tester) async {
      final mockRepository = _MockVaultRepository(null);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
          currentPublicKeyProvider.overrideWith((ref) async => 'a' * 64),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BackupConfigScreen(vaultId: 'test-vault')),
        ),
      );

      await tester.pumpAndSettle();

      // Make an edit without adding any stewards.
      await tester.enterText(
        find.byKey(const ValueKey('recovery_instructions_field')),
        'Call my sister first.',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // The dialog previously hid Save behind a steward-count check, leaving
      // "Go Back" and "Discard" as the only exits — the edit could not be kept.
      expect(find.text('Discard Changes?'), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Save')),
        findsOneWidget,
      );

      container.dispose();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('saving a new vault with no stewards persists the relays', (tester) async {
      final mockRepository = _MockVaultRepository(null);

      final container = ProviderContainer(
        overrides: [
          vaultRepositoryProvider.overrideWith((ref) => mockRepository),
          currentPublicKeyProvider.overrideWith((ref) async => 'a' * 64),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BackupConfigScreen(vaultId: 'test-vault')),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // The regression: on a brand-new vault getBackupConfig() returns null,
      // and the old zero-steward path skipped the save entirely, silently
      // discarding relays and instructions.
      expect(
        mockRepository.savedConfigs,
        isNotEmpty,
        reason: 'zero-steward save must persist a config',
      );
      final saved = mockRepository.savedConfigs.last;
      expect(saved.stewards, isEmpty);
      expect(saved.relays, isNotEmpty);

      container.dispose();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}

/// Mock VaultRepository for testing
class _MockVaultRepository extends VaultRepository {
  BackupConfig? _backupConfig;

  /// Every config handed to [updateBackupConfig], in call order.
  final List<BackupConfig> savedConfigs = [];

  _MockVaultRepository(this._backupConfig) : super(LoginService());

  @override
  Future<BackupConfig?> getBackupConfig(String vaultId) async {
    return _backupConfig;
  }

  @override
  Future<void> updateBackupConfig(String vaultId, BackupConfig config) async {
    savedConfigs.add(config);
    _backupConfig = config;
  }

  @override
  Future<void> setPushEnabled(String vaultId, bool enabled) async {}

  @override
  Future<Vault?> getVault(String vaultId) async {
    if (vaultId != 'test-vault') return null;
    return Vault(
      id: 'test-vault',
      name: 'Test',
      createdAt: DateTime(2024, 1, 1),
      ownerPubkey: 'a' * 64,
      pushEnabled: true,
    );
  }
}
