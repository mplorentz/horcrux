import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horcrux/models/shard_data.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/horcrux_notification_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/vault_share_service.dart';
import '../fixtures/test_keys.dart';
import '../helpers/shared_preferences_mock.dart';
import 'vault_share_service_test.mocks.dart';

@GenerateMocks([LoginService, NdkService, HorcruxNotificationService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sharedPreferencesMock = SharedPreferencesMock();

  setUpAll(() {
    sharedPreferencesMock.setUpAll();
  });

  tearDownAll(() {
    sharedPreferencesMock.tearDownAll();
  });

  group('VaultShareService.addVaultShare pushEnabled propagation', () {
    const ownerPubkey = TestHexPubkeys.alice;
    const vaultId = 'test-vault';

    late MockLoginService mockLoginService;
    late MockNdkService mockNdkService;
    late MockHorcruxNotificationService mockNotificationService;
    late VaultRepository repository;
    late VaultShareService service;

    setUp(() {
      sharedPreferencesMock.clear();
      // Reset SharedPreferences' internal singleton so each test starts with
      // an empty store (the method-channel mock alone is not enough - the
      // plugin caches values in-process across getInstance() calls).
      SharedPreferences.setMockInitialValues({});

      mockLoginService = MockLoginService();
      when(mockLoginService.encryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
      when(mockLoginService.decryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);

      mockNdkService = MockNdkService();
      mockNotificationService = MockHorcruxNotificationService();
      repository = VaultRepository(mockLoginService);
      service = VaultShareService(
        repository,
        () => mockNdkService,
        () => mockNotificationService,
      );
    });

    ShardData buildShard({required int index, bool? pushEnabled}) {
      return createShardData(
        shard: 'abc123',
        threshold: 2,
        shardIndex: index,
        totalShards: 3,
        primeMod: 'xyz',
        creatorPubkey: ownerPubkey,
        vaultId: vaultId,
        vaultName: 'Vault From Owner',
        pushEnabled: pushEnabled,
      );
    }

    test(
      'creates a fresh vault with pushEnabled adopted from the first shard',
      () async {
        final shard = buildShard(index: 0, pushEnabled: true);

        await service.addVaultShare(vaultId, shard);

        final stored = await repository.getVault(vaultId);
        expect(stored, isNotNull);
        expect(stored!.pushEnabled, isTrue);
        expect(stored.ownerPubkey, ownerPubkey);
      },
    );

    test(
      'creates a fresh vault with pushEnabled=false when shard omits the flag (legacy)',
      () async {
        final shard = buildShard(index: 0); // pushEnabled: null on the wire

        await service.addVaultShare(vaultId, shard);

        final stored = await repository.getVault(vaultId);
        expect(stored, isNotNull);
        expect(stored!.pushEnabled, isFalse);
      },
    );

    test(
      'upgrades a stub vault (pushEnabled=false) to the owner\'s value on first shard',
      () async {
        // Stub vault mimics what InvitationService writes at acceptance time.
        final stub = Vault(
          id: vaultId,
          name: 'Stub Name',
          content: null,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ownerPubkey: ownerPubkey,
          shards: const [],
          backupConfig: null,
          pushEnabled: false,
        );
        await repository.addVault(stub);

        final shard = buildShard(index: 0, pushEnabled: true);
        await service.addVaultShare(vaultId, shard);

        final stored = await repository.getVault(vaultId);
        expect(stored!.pushEnabled, isTrue);
        expect(stored.name, 'Vault From Owner'); // stub name overridden
      },
    );

    test(
      'redistribution flips pushEnabled on an already-populated vault',
      () async {
        // First distribution: pushEnabled=false.
        await service.addVaultShare(vaultId, buildShard(index: 0, pushEnabled: false));
        expect((await repository.getVault(vaultId))!.pushEnabled, isFalse);

        // Owner toggles push on and redistributes (new shard for a later index).
        await service.addVaultShare(vaultId, buildShard(index: 1, pushEnabled: true));

        final stored = await repository.getVault(vaultId);
        expect(stored!.pushEnabled, isTrue,
            reason: 'redistribution should sync the owner\'s new preference');
      },
    );

    test(
      'legacy shard (no pushEnabled on the wire) collapses steward to false',
      () async {
        // Populate with pushEnabled=true.
        await service.addVaultShare(vaultId, buildShard(index: 0, pushEnabled: true));
        expect((await repository.getVault(vaultId))!.pushEnabled, isTrue);

        // A later shard from an older owner build (or a serialization bug)
        // omits the flag entirely. Null on the wire is treated as "no opinion
        // → off", so the steward snaps back to the privacy-preserving default.
        await service.addVaultShare(vaultId, buildShard(index: 1));

        expect((await repository.getVault(vaultId))!.pushEnabled, isFalse);
      },
    );

    test(
      'repeat shard with the same pushEnabled value is a no-op (no unnecessary writes)',
      () async {
        await service.addVaultShare(vaultId, buildShard(index: 0, pushEnabled: true));
        // No exception / no crash; state remains consistent.
        await service.addVaultShare(vaultId, buildShard(index: 1, pushEnabled: true));

        expect((await repository.getVault(vaultId))!.pushEnabled, isTrue);
      },
    );
  });
}
