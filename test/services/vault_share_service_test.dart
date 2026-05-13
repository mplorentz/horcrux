import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/ndk.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'dart:typed_data';

import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/horcrux_notification_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/push_notification_receiver.dart';
import 'package:horcrux/services/vault_share_service.dart';
import '../fixtures/test_keys.dart';
import '../helpers/test_database.dart';
import 'vault_share_service_test.mocks.dart';

@GenerateMocks([
  LoginService,
  NdkService,
  HorcruxNotificationService,
  PushNotificationReceiver,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultShareService.addVaultShare pushEnabled propagation', () {
    const ownerPubkey = TestHexPubkeys.alice;
    const vaultId = 'test-vault';

    late MockLoginService mockLoginService;
    late MockNdkService mockNdkService;
    late MockHorcruxNotificationService mockNotificationService;
    late MockPushNotificationReceiver mockPushReceiver;
    late VaultRepository repository;
    late VaultShareService service;

    setUp(() {
      mockLoginService = MockLoginService();
      when(mockLoginService.encryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
      when(mockLoginService.decryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);

      mockNdkService = MockNdkService();
      when(mockNdkService.getCurrentPubkey()).thenAnswer((_) async => TestHexPubkeys.bob);
      mockNotificationService = MockHorcruxNotificationService();
      mockPushReceiver = MockPushNotificationReceiver();
      when(mockPushReceiver.isOptedIn()).thenAnswer((_) async => true);
      repository = VaultRepository(mockLoginService);
      service = VaultShareService(
        repository,
        () => mockNdkService,
        () => mockNotificationService,
        () => mockPushReceiver,
      );
    });

    Share buildShard({
      required int index,
      bool? pushEnabled,
      int? distributionVersion,
    }) {
      return createShare(
        payload: 'abc123',
        threshold: 2,
        shareIndex: index,
        totalShares: 3,
        primeMod: 'xyz',
        creatorPubkey: ownerPubkey,
        vaultId: vaultId,
        vaultName: 'Vault From Owner',
        distributionVersion: distributionVersion,
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
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ownerPubkey: ownerPubkey,
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
        await service.addVaultShare(
          vaultId,
          buildShard(index: 0, pushEnabled: false, distributionVersion: 1),
        );
        expect((await repository.getVault(vaultId))!.pushEnabled, isFalse);

        // Owner toggles push on and redistributes (new shard for a later index).
        await service.addVaultShare(
          vaultId,
          buildShard(index: 1, pushEnabled: true, distributionVersion: 2),
        );

        final stored = await repository.getVault(vaultId);
        expect(stored!.pushEnabled, isTrue,
            reason: 'redistribution should sync the owner\'s new preference');
      },
    );

    test(
      'legacy or unversioned shard does not roll back pushEnabled after a newer distribution',
      () async {
        await service.addVaultShare(
          vaultId,
          buildShard(index: 0, pushEnabled: true, distributionVersion: 2),
        );
        expect((await repository.getVault(vaultId))!.pushEnabled, isTrue);

        // Later shard omits distribution_version and pushEnabled (legacy replay).
        await service.addVaultShare(vaultId, buildShard(index: 1));

        expect((await repository.getVault(vaultId))!.pushEnabled, isTrue);
      },
    );

    test(
      'repeat shard with the same pushEnabled value is a no-op (no unnecessary writes)',
      () async {
        await service.addVaultShare(
          vaultId,
          buildShard(index: 0, pushEnabled: true, distributionVersion: 1),
        );
        await service.addVaultShare(
          vaultId,
          buildShard(index: 1, pushEnabled: true, distributionVersion: 2),
        );

        expect((await repository.getVault(vaultId))!.pushEnabled, isTrue);
      },
    );

    test(
      'processVaultShare calls global push optIn when shard has pushEnabled and steward is not opted in',
      () async {
        PushNotificationReceiver.debugIsSupportedOverride = true;
        addTearDown(
          () => PushNotificationReceiver.debugIsSupportedOverride = null,
        );

        when(mockPushReceiver.isOptedIn()).thenAnswer((_) async => false);
        when(mockPushReceiver.optIn()).thenAnswer((_) async => true);
        when(mockNdkService.getCurrentPubkey()).thenAnswer((_) async => TestHexPubkeys.bob);
        when(
          mockNdkService.publishEncryptedEvent(
            content: anyNamed('content'),
            kind: anyNamed('kind'),
            recipientPubkey: anyNamed('recipientPubkey'),
            relays: anyNamed('relays'),
            tags: anyNamed('tags'),
          ),
        ).thenAnswer(
          (_) async => Nip01Event(
            kind: NostrKind.shareConfirmation.value,
            pubKey: TestHexPubkeys.bob,
            tags: const [],
            content: '',
            createdAt: 1,
          ),
        );
        when(
          mockNotificationService.tryPushForEvent(
            event: anyNamed('event'),
            kind: anyNamed('kind'),
            vault: anyNamed('vault'),
            relayHints: anyNamed('relayHints'),
          ),
        ).thenAnswer((_) async {});

        final shard = buildShard(
          index: 0,
          pushEnabled: true,
          distributionVersion: 1,
        ).copyWith(
          relayUrls: ['wss://relay.example.com'],
          nostrEventId: 'process-vault-share-push-opt-in',
        );
        await service.processVaultShare(vaultId, shard);

        verify(mockPushReceiver.isOptedIn()).called(1);
        verify(mockPushReceiver.optIn()).called(1);
      },
    );
  });

  group('VaultShareService steward shard_index placement', () {
    late AppDatabase db;
    late MockLoginService mockLoginService;
    late MockNdkService mockNdkService;
    late MockHorcruxNotificationService mockNotificationService;
    late MockPushNotificationReceiver mockPushReceiver;
    late VaultRepository repository;
    late VaultShareService service;

    setUp(() {
      db = newTestDatabase();
      mockLoginService = MockLoginService();
      when(mockLoginService.encryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
      when(mockLoginService.decryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);

      mockNdkService = MockNdkService();
      when(mockNdkService.getCurrentPubkey()).thenAnswer((_) async => TestHexPubkeys.bob);
      mockNotificationService = MockHorcruxNotificationService();
      mockPushReceiver = MockPushNotificationReceiver();

      repository = VaultRepository(mockLoginService, db: db);
      service = VaultShareService(
        repository,
        () => mockNdkService,
        () => mockNotificationService,
        () => mockPushReceiver,
      );
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
    });

    test('upserts stewards at shard_index slots from payload', () async {
      const vaultId = 'vault-shard-idx';
      const ownerPubkey = TestHexPubkeys.alice;
      final share = createShare(
        payload: 'shard-bytes',
        threshold: 2,
        shareIndex: 2,
        totalShares: 3,
        primeMod: 'prime-mod-value',
        creatorPubkey: ownerPubkey,
        vaultId: vaultId,
        vaultName: 'Shared Vault',
        stewards: [
          {
            'id': 'steward-alice',
            'name': 'Alice',
            'pubkey': TestHexPubkeys.alice,
            'shard_index': '0',
          },
          {
            'id': 'steward-bob',
            'name': 'Bob',
            'pubkey': TestHexPubkeys.bob,
            'shard_index': '2',
          },
        ],
      );

      await service.addVaultShare(vaultId, share);

      final rows = await db.stewardDao.activeForVault(vaultId);
      expect(rows, hasLength(2));
      final alice = rows.firstWhere((r) => r.pubkey == TestHexPubkeys.alice);
      final bob = rows.firstWhere((r) => r.pubkey == TestHexPubkeys.bob);
      expect(alice.shareIndex, 1);
      expect(bob.shareIndex, 3);
    });

    test('upserts all embedded stewards when wire payload omits steward id', () async {
      const vaultId = 'vault-no-steward-id';
      const ownerPubkey = TestHexPubkeys.alice;
      final share = createShare(
        payload: 'shard-bytes',
        threshold: 2,
        shareIndex: 1,
        totalShares: 3,
        primeMod: 'prime-mod-value',
        creatorPubkey: ownerPubkey,
        vaultId: vaultId,
        vaultName: 'Shared Vault',
        stewards: [
          {
            'name': 'Alice',
            'pubkey': TestHexPubkeys.alice,
            'shard_index': '0',
          },
          {
            'name': 'Bob',
            'pubkey': TestHexPubkeys.bob,
            'shard_index': '1',
          },
        ],
      );

      await service.addVaultShare(vaultId, share);

      final rows = await db.stewardDao.activeForVault(vaultId);
      expect(rows, hasLength(2));
      final alice = rows.firstWhere((r) => r.pubkey == TestHexPubkeys.alice);
      final bob = rows.firstWhere((r) => r.pubkey == TestHexPubkeys.bob);
      expect(alice.id, 'wire_${vaultId}_0_${TestHexPubkeys.alice}');
      expect(bob.id, 'wire_${vaultId}_1_${TestHexPubkeys.bob}');
      expect(alice.shareIndex, 1);
      expect(bob.shareIndex, 2);
    });

    test(
      'infers owner holdingKey from embedded roster when owner self-stewards',
      () async {
        const vaultId = 'vault-owner-self-steward-infer';
        const ownerPubkey = TestHexPubkeys.alice;
        const distVersion = 4;
        final share = createShare(
          payload: 'shard-bytes',
          threshold: 2,
          shareIndex: 1,
          totalShares: 3,
          primeMod: 'prime-mod-value',
          creatorPubkey: ownerPubkey,
          vaultId: vaultId,
          vaultName: 'Shared Vault',
          distributionVersion: distVersion,
          stewards: [
            {
              'id': 'steward-alice',
              'name': 'Alice',
              'pubkey': TestHexPubkeys.alice,
              'shard_index': '0',
            },
            {
              'id': 'steward-bob',
              'name': 'Bob',
              'pubkey': TestHexPubkeys.bob,
              'shard_index': '1',
            },
          ],
        );

        await service.addVaultShare(vaultId, share);

        final vault = await repository.getVault(vaultId);
        expect(vault, isNotNull);
        expect(vault!.backupConfig!.distributionVersion, distVersion);

        final ownerSteward = vault.backupConfig!.stewards.firstWhere(
          (s) => s.pubkey == ownerPubkey,
        );
        expect(ownerSteward.status, StewardStatus.holdingKey);
        expect(ownerSteward.acknowledgmentEventId, isNull);
        expect(ownerSteward.acknowledgedDistributionVersion, distVersion);
        expect(
          ownerSteward.giftWrapEventId,
          'owner-self-steward-inferred:$vaultId:v$distVersion',
        );

        const distributionId = '${vaultId}_v$distVersion';
        final shareRows = await db.distributionDao.sharesFor(distributionId);
        final ownerShareRow = shareRows.firstWhere((r) => r.stewardId == 'steward-alice');
        expect(ownerShareRow.acknowledgmentEventId, isNull);
        expect(ownerShareRow.acknowledgmentDistributionVersion, distVersion);
        expect(
          ownerShareRow.giftWrapEventId,
          'owner-self-steward-inferred:$vaultId:v$distVersion',
        );
      },
    );

    test(
      'inference skips stale share when vault current_distribution_version is newer',
      () async {
        const vaultId = 'vault-stale-owner-infer';
        const ownerPubkey = TestHexPubkeys.alice;

        Share shareForVersion(int version, int shareIndex) => createShare(
              payload: 'shard-bytes-$version',
              threshold: 2,
              shareIndex: shareIndex,
              totalShares: 3,
              primeMod: 'prime-mod-value',
              creatorPubkey: ownerPubkey,
              vaultId: vaultId,
              vaultName: 'Shared Vault',
              distributionVersion: version,
              stewards: [
                {
                  'id': 'steward-alice',
                  'name': 'Alice',
                  'pubkey': TestHexPubkeys.alice,
                  'shard_index': '0',
                },
                {
                  'id': 'steward-bob',
                  'name': 'Bob',
                  'pubkey': TestHexPubkeys.bob,
                  'shard_index': '1',
                },
              ],
            );

        await service.addVaultShare(vaultId, shareForVersion(5, 1));
        final afterFresh = await repository.getVault(vaultId);
        final ownerAfterFresh = afterFresh!.backupConfig!.stewards.firstWhere(
          (s) => s.pubkey == ownerPubkey,
        );
        expect(ownerAfterFresh.acknowledgedDistributionVersion, 5);
        expect(
          ownerAfterFresh.giftWrapEventId,
          'owner-self-steward-inferred:$vaultId:v5',
        );

        await service.addVaultShare(vaultId, shareForVersion(3, 2));

        final afterStale = await repository.getVault(vaultId);
        expect(afterStale!.backupConfig!.distributionVersion, 5);
        final ownerAfterStale = afterStale.backupConfig!.stewards.firstWhere(
          (s) => s.pubkey == ownerPubkey,
        );
        expect(ownerAfterStale.acknowledgedDistributionVersion, 5);
        expect(
          ownerAfterStale.giftWrapEventId,
          'owner-self-steward-inferred:$vaultId:v5',
        );

        final rowsV5 = await db.distributionDao.sharesFor('${vaultId}_v5');
        expect(
          rowsV5.where((r) => r.stewardId == 'steward-alice').single.giftWrapEventId,
          'owner-self-steward-inferred:$vaultId:v5',
        );
      },
    );

    test(
      'inference updates owner synthetic ack when redistribution bumps distribution version',
      () async {
        const vaultId = 'vault-owner-infer-redist';
        const ownerPubkey = TestHexPubkeys.alice;

        Future<void> ingest(int version, int shareIndex) async {
          await service.addVaultShare(
            vaultId,
            createShare(
              payload: 'shard-v$version',
              threshold: 2,
              shareIndex: shareIndex,
              totalShares: 3,
              primeMod: 'prime-mod-value',
              creatorPubkey: ownerPubkey,
              vaultId: vaultId,
              vaultName: 'Shared Vault',
              distributionVersion: version,
              stewards: [
                {
                  'id': 'steward-alice',
                  'name': 'Alice',
                  'pubkey': TestHexPubkeys.alice,
                  'shard_index': '0',
                },
                {
                  'id': 'steward-bob',
                  'name': 'Bob',
                  'pubkey': TestHexPubkeys.bob,
                  'shard_index': '1',
                },
              ],
            ),
          );
        }

        await ingest(1, 1);
        var vault = await repository.getVault(vaultId);
        var ownerRow = vault!.backupConfig!.stewards.firstWhere((s) => s.pubkey == ownerPubkey);
        expect(ownerRow.acknowledgedDistributionVersion, 1);
        expect(ownerRow.giftWrapEventId, 'owner-self-steward-inferred:$vaultId:v1');

        await ingest(2, 2);
        vault = await repository.getVault(vaultId);
        ownerRow = vault!.backupConfig!.stewards.firstWhere((s) => s.pubkey == ownerPubkey);
        expect(vault.backupConfig!.distributionVersion, 2);
        expect(ownerRow.acknowledgedDistributionVersion, 2);
        expect(ownerRow.giftWrapEventId, 'owner-self-steward-inferred:$vaultId:v2');

        final rowsV2 = await db.distributionDao.sharesFor('${vaultId}_v2');
        expect(
          rowsV2
              .where((r) => r.stewardId == 'steward-alice')
              .single
              .acknowledgmentDistributionVersion,
          2,
        );
      },
    );

    test(
      'does not infer owner ack when owner pubkey is absent from embedded stewards',
      () async {
        const vaultId = 'vault-owner-not-in-embedded';
        const ownerPubkey = TestHexPubkeys.alice;

        final share = createShare(
          payload: 'shard-bytes',
          threshold: 2,
          shareIndex: 1,
          totalShares: 3,
          primeMod: 'prime-mod-value',
          creatorPubkey: ownerPubkey,
          vaultId: vaultId,
          vaultName: 'Shared Vault',
          distributionVersion: 1,
          stewards: [
            {
              'id': 'steward-bob',
              'name': 'Bob',
              'pubkey': TestHexPubkeys.bob,
              'shard_index': '1',
            },
            {
              'id': 'steward-charlie',
              'name': 'Charlie',
              'pubkey': TestHexPubkeys.charlie,
              'shard_index': '2',
            },
          ],
        );

        await service.addVaultShare(vaultId, share);

        final stewardRows = await db.stewardDao.activeForVault(vaultId);
        expect(stewardRows.any((r) => r.pubkey == ownerPubkey), isFalse);

        const distributionId = '${vaultId}_v1';
        final shareRows = await db.distributionDao.sharesFor(distributionId);
        expect(
          shareRows.any((r) => r.giftWrapEventId.startsWith('owner-self-steward-inferred:')),
          isFalse,
        );
      },
    );
  });

  group('VaultShareService stale owned_vaults vs logged-in pubkey', () {
    late AppDatabase db;
    late MockLoginService mockLoginService;
    late MockNdkService mockNdkService;
    late MockHorcruxNotificationService mockNotificationService;
    late MockPushNotificationReceiver mockPushReceiver;
    late VaultRepository repository;
    late VaultShareService service;

    setUp(() {
      db = newTestDatabase();
      mockLoginService = MockLoginService();
      when(mockLoginService.encryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
      when(mockLoginService.decryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
      when(mockLoginService.getCurrentPublicKey()).thenAnswer((_) async => TestHexPubkeys.bob);

      mockNdkService = MockNdkService();
      when(mockNdkService.getCurrentPubkey()).thenAnswer((_) async => TestHexPubkeys.bob);
      mockNotificationService = MockHorcruxNotificationService();
      mockPushReceiver = MockPushNotificationReceiver();

      repository = VaultRepository(mockLoginService, db: db);
      service = VaultShareService(
        repository,
        () => mockNdkService,
        () => mockNotificationService,
        () => mockPushReceiver,
      );
    });

    tearDown(() async {
      repository.dispose();
      await db.close();
    });

    test(
      'still upserts embedded stewards when owned_vaults row is stale on steward device',
      () async {
        final fixture = await VaultFixture.stewarded(
          db,
          ownerPubkey: TestHexPubkeys.alice,
        );

        await db.into(db.ownedVaults).insert(
              OwnedVaultsCompanion.insert(
                vaultId: fixture.vaultId,
                content: 'placeholder-ciphertext',
                contentHmac: Uint8List(32),
                createdBySelfAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );

        final share = createShare(
          payload: 'shard-bytes',
          threshold: 2,
          shareIndex: 1,
          totalShares: 3,
          primeMod: 'prime-mod-value',
          creatorPubkey: TestHexPubkeys.alice,
          vaultId: fixture.vaultId,
          vaultName: 'Shared Vault',
          stewards: [
            {
              'id': 'steward-alice',
              'name': 'Alice',
              'pubkey': TestHexPubkeys.alice,
              'shard_index': '0',
            },
            {
              'id': 'steward-bob',
              'name': 'Bob',
              'pubkey': TestHexPubkeys.bob,
              'shard_index': '1',
            },
          ],
        );

        await service.addVaultShare(fixture.vaultId, share);

        final rows = await db.stewardDao.activeForVault(fixture.vaultId);
        expect(rows, hasLength(2));
      },
    );
  });
}
