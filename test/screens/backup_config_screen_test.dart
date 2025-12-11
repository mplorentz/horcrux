import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStorageMock = SecureStorageMock();

  const MethodChannel sharedPreferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );
  final Map<String, dynamic> sharedPreferencesStore = {};

  setUpAll(() {
    secureStorageMock.setUpAll();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      sharedPreferencesChannel,
      (call) async {
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
      },
    );
  });

  tearDownAll(() {
    secureStorageMock.tearDownAll();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      sharedPreferencesChannel,
      null,
    );
  });

  setUp(() async {
    sharedPreferencesStore.clear();
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

      // Verify the self-shard toggle is displayed
      expect(find.text('Include yourself as a steward'), findsOneWidget);
      expect(find.text('Keep one shard for yourself'), findsOneWidget);
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

