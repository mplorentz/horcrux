import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/providers/key_provider.dart';
import 'package:horcrux/screens/backup_config_screen.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/secure_storage_mock.dart';
import '../helpers/shared_preferences_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStorageMock = SecureStorageMock();
  final sharedPreferencesMock = SharedPreferencesMock();

  setUpAll(() {
    secureStorageMock.setUpAll();
    sharedPreferencesMock.setUpAll();
  });

  tearDownAll(() {
    secureStorageMock.tearDownAll();
    sharedPreferencesMock.tearDownAll();
  });

  setUp(() async {
    sharedPreferencesMock.clear();
    secureStorageMock.clear();
    SharedPreferences.setMockInitialValues({});
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
      expect(find.byType(Switch), findsOneWidget);

      container.dispose();
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

      // Verify the toggle starts disabled
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);

      container.dispose();
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

      // Verify the toggle is enabled when owner steward exists
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);

      container.dispose();
    });
  });
}

/// Mock VaultRepository for testing
class _MockVaultRepository extends VaultRepository {
  final BackupConfig? _backupConfig;

  _MockVaultRepository(this._backupConfig) : super(LoginService());

  @override
  Future<BackupConfig?> getBackupConfig(String vaultId) async {
    return _backupConfig;
  }
}
