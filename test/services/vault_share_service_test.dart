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
import 'package:horcrux/services/relay_scan_service.dart';
import 'package:horcrux/services/vault_share_service.dart';
import '../fixtures/test_keys.dart';
import '../helpers/test_database.dart';
import 'vault_share_service_test.mocks.dart';

@GenerateMocks([
  LoginService,
  NdkService,
  HorcruxNotificationService,
  PushNotificationReceiver,
  RelayScanService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLoginService mockLoginService;
  late MockNdkService mockNdkService;
  late MockPushNotificationReceiver mockPushReceiver;
  late MockRelayScanService mockRelayScanService;

  setUp(() {
    mockLoginService = MockLoginService();
    when(mockLoginService.encryptText(any))
        .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
    when(mockLoginService.decryptText(any))
        .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);

    mockNdkService = MockNdkService();
    when(mockNdkService.getCurrentPubkey()).thenAnswer((_) async => TestHexPubkeys.bob);
    mockPushReceiver = MockPushNotificationReceiver();
    when(mockPushReceiver.isOptedIn()).thenAnswer((_) async => true);
    mockRelayScanService = MockRelayScanService();
  });

  group('VaultShareService.addVaultShare pushEnabled propagation', () {
    const ownerPubkey = TestHexPubkeys.alice;
    const vaultId = 'test-vault';

    late MockLoginService mockLoginService;
    late MockNdkService mockNdkService;
    late MockHorcruxNotificationService mockNotificationService;
    late MockPushNotificationReceiver mockPushReceiver;
    late MockRelayScanService mockRelayScanService;
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
      mockRelayScanService = MockRelayScanService();
      repository = VaultRepository(mockLoginService);
      service = VaultShareService(
        repository,
        () => mockNdkService,
        () => mockNotificationService,
        () => mockPushReceiver,
        () => mockRelayScanService,
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

  group('VaultShareService.sendShareConfirmationEvent wire tags', () {
    late MockLoginService mockLoginService;
    late MockNdkService mockNdkService;
    late MockHorcruxNotificationService mockNotificationService;
    late MockRelayScanService mockRelayScanService;
    late VaultShareService service;
    List<List<String>>? capturedTags;

    setUp(() {
      mockLoginService = MockLoginService();
      mockNdkService = MockNdkService();
      mockNotificationService = MockHorcruxNotificationService();
      mockRelayScanService = MockRelayScanService();
      capturedTags = null;
      when(mockNdkService.getCurrentPubkey()).thenAnswer((_) async => TestHexPubkeys.bob);
      when(
        mockNdkService.publishEncryptedEvent(
          content: anyNamed('content'),
          kind: anyNamed('kind'),
          recipientPubkey: anyNamed('recipientPubkey'),
          relays: anyNamed('relays'),
          tags: anyNamed('tags'),
        ),
      ).thenAnswer((invocation) async {
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>?;
        return Nip01Event(
          kind: NostrKind.shareConfirmation.value,
          pubKey: TestHexPubkeys.bob,
          tags: const [],
          content: '',
          createdAt: 1,
        );
      });
      service = VaultShareService(
        VaultRepository(mockLoginService),
        () => mockNdkService,
        () => mockNotificationService,
        () => MockPushNotificationReceiver(),
        () => mockRelayScanService,
      );
    });

    test('publishes share_index without steward_pubkey tag', () async {
      await service.sendShareConfirmationEvent(
        vaultId: 'vault-wire',
        shareIndex: 2,
        ownerPubkey: TestHexPubkeys.alice,
        relayUrls: ['wss://relay.example.com'],
        distributionVersion: 4,
      );

      expect(capturedTags, isNotNull);
      expect(
        capturedTags!.any((t) => t[0] == 'share_index' && t[1] == '2'),
        isTrue,
      );
      expect(capturedTags!.any((t) => t[0] == 'shard_index'), isFalse);
      expect(capturedTags!.any((t) => t[0] == 'steward_pubkey'), isFalse);
    });
  });

  group('VaultShareService steward shard_index placement', () {
    late AppDatabase db;
    late MockLoginService mockLoginService;
    late MockNdkService mockNdkService;
    late MockHorcruxNotificationService mockNotificationService;
    late MockPushNotificationReceiver mockPushReceiver;
    late MockRelayScanService mockRelayScanService;
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
      mockRelayScanService = MockRelayScanService();

      repository = VaultRepository(mockLoginService, db: db);
      service = VaultShareService(
        repository,
        () => mockNdkService,
        () => mockNotificationService,
        () => mockPushReceiver,
        () => mockRelayScanService,
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
      mockRelayScanService = MockRelayScanService();

      repository = VaultRepository(mockLoginService, db: db);
      service = VaultShareService(
        repository,
        () => mockNdkService,
        () => mockNotificationService,
        () => mockPushReceiver,
        () => mockRelayScanService,
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

  group('VaultShareService manifest ingest', () {
    const vaultId = 'manifest-ingest-vault';
    const owner = TestHexPubkeys.alice;

    late MockLoginService mockLoginService;
    late MockNdkService mockNdkService;
    late MockHorcruxNotificationService mockNotificationService;
    late MockPushNotificationReceiver mockPushReceiver;
    late MockRelayScanService mockRelayScanService;
    late VaultRepository repository;
    late VaultShareService service;

    setUp(() {
      mockLoginService = MockLoginService();
      when(mockLoginService.encryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
      when(mockLoginService.decryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
      when(mockLoginService.getCurrentPublicKey()).thenAnswer((_) async => owner);

      mockNdkService = MockNdkService();
      when(mockNdkService.getCurrentPubkey()).thenAnswer((_) async => owner);
      mockNotificationService = MockHorcruxNotificationService();
      mockPushReceiver = MockPushNotificationReceiver();
      when(mockPushReceiver.isOptedIn()).thenAnswer((_) async => true);
      mockRelayScanService = MockRelayScanService();

      repository = VaultRepository(mockLoginService);
      service = VaultShareService(
        repository,
        () => mockNdkService,
        () => mockNotificationService,
        () => mockPushReceiver,
        () => mockRelayScanService,
      );
    });

    tearDown(() {
      repository.dispose();
    });

    test('hydrates backup config without held_shares or confirmation publish', () async {
      final embedded = <Map<String, String>>[
        {'id': 'b1', 'name': 'Bob', 'pubkey': TestHexPubkeys.bob, 'shard_index': '0'},
        {'id': 'c1', 'name': 'Charlie', 'pubkey': TestHexPubkeys.charlie, 'shard_index': '1'},
      ];
      final manifest = Share(
        payload: '',
        threshold: 2,
        shareIndex: -1,
        totalShares: 2,
        primeMod: TestShare.testPrimeMod,
        creatorPubkey: owner,
        createdAt: 1700000000,
        vaultId: vaultId,
        vaultName: 'Wire Vault',
        ownerName: 'Alice',
        instructions: 'Handle with care',
        stewards: embedded,
        relayUrls: const ['ws://relay.example'],
        distributionVersion: 3,
        nostrEventId: 'manifest-event-1',
      );

      await service.processVaultShare(vaultId, manifest);

      final shares = await repository.getSharesForVault(vaultId);
      expect(shares, isEmpty);

      final v = await repository.getVault(vaultId);
      expect(v, isNotNull);
      expect(v!.backupConfig, isNotNull);
      expect(v.backupConfig!.threshold, 2);
      expect(v.backupConfig!.instructions, 'Handle with care');
      expect(v.backupConfig!.distributionVersion, 3);
      expect(v.backupConfig!.stewards, hasLength(2));
      expect(await repository.isOwnedVault(vaultId), isTrue);
      expect(
        await repository.isOwnedVaultForCurrentUser(vaultId),
        isTrue,
        reason: 'manifest-only ingest must insert owned shell so owner UI gates work',
      );

      verifyNever(
        mockNdkService.publishEncryptedEvent(
          content: anyNamed('content'),
          kind: anyNamed('kind'),
          recipientPubkey: anyNamed('recipientPubkey'),
          relays: anyNamed('relays'),
          tags: anyNamed('tags'),
          customPubkey: anyNamed('customPubkey'),
          vaultId: anyNamed('vaultId'),
          nip40Expiration: anyNamed('nip40Expiration'),
        ),
      );
    });

    test(
      'stale manifest does not overwrite a newer manifest (distribution order)',
      () async {
        const orderVaultId = 'manifest-order-vault';
        final embedded = <Map<String, String>>[
          {'id': 'b1', 'name': 'Bob', 'pubkey': TestHexPubkeys.bob, 'shard_index': '0'},
          {'id': 'c1', 'name': 'Charlie', 'pubkey': TestHexPubkeys.charlie, 'shard_index': '1'},
        ];

        Share wireManifest({
          required int distributionVersion,
          required String vaultName,
          required String nostrEventId,
        }) {
          return Share(
            payload: '',
            threshold: 2,
            shareIndex: -1,
            totalShares: 2,
            primeMod: TestShare.testPrimeMod,
            creatorPubkey: owner,
            createdAt: 1700000000,
            vaultId: orderVaultId,
            vaultName: vaultName,
            ownerName: 'Alice',
            instructions: 'Instr $distributionVersion',
            stewards: embedded,
            relayUrls: const ['ws://relay.example'],
            distributionVersion: distributionVersion,
            nostrEventId: nostrEventId,
          );
        }

        await service.processVaultShare(
          orderVaultId,
          wireManifest(
            distributionVersion: 3,
            vaultName: 'FromVThree',
            nostrEventId: 'manifest-v3-first',
          ),
        );

        await service.processVaultShare(
          orderVaultId,
          wireManifest(
            distributionVersion: 2,
            vaultName: 'FromVTwoStale',
            nostrEventId: 'manifest-v2-late',
          ),
        );

        final v = await repository.getVault(orderVaultId);
        expect(v, isNotNull);
        expect(v!.name, 'FromVThree');
        expect(v.backupConfig, isNotNull);
        expect(v.backupConfig!.distributionVersion, 3);
        expect(v.backupConfig!.instructions, 'Instr 3');
      },
    );

    test(
      'stale same-version manifest still restores owned_vaults shell for owner',
      () async {
        const shellVaultId = 'manifest-stale-shell-vault';
        final embedded = <Map<String, String>>[
          {'id': 'b1', 'name': 'Bob', 'pubkey': TestHexPubkeys.bob, 'shard_index': '0'},
          {'id': 'c1', 'name': 'Charlie', 'pubkey': TestHexPubkeys.charlie, 'shard_index': '1'},
        ];
        final manifest = Share(
          payload: '',
          threshold: 2,
          shareIndex: -1,
          totalShares: 2,
          primeMod: TestShare.testPrimeMod,
          creatorPubkey: owner,
          createdAt: 1700000000,
          vaultId: shellVaultId,
          vaultName: 'Wire Vault',
          ownerName: 'Alice',
          instructions: 'Once',
          stewards: embedded,
          relayUrls: const ['ws://relay.example'],
          distributionVersion: 3,
          nostrEventId: 'manifest-shell-a',
        );

        await service.processVaultShare(shellVaultId, manifest);
        expect(await repository.isOwnedVault(shellVaultId), isTrue);

        await repository.deleteVaultContent(shellVaultId);
        expect(await repository.isOwnedVault(shellVaultId), isFalse);

        await service.processVaultShare(
          shellVaultId,
          manifest.copyWith(
            instructions: 'Replay same dist',
            nostrEventId: 'manifest-shell-b',
          ),
        );

        expect(await repository.isOwnedVault(shellVaultId), isTrue);
        final v = await repository.getVault(shellVaultId);
        expect(v, isNotNull);
        expect(v!.backupConfig, isNotNull);
        expect(v.backupConfig!.distributionVersion, 3);
        expect(
          v.backupConfig!.instructions,
          'Once',
          reason: 'stale ingest must not overwrite metadata',
        );
      },
    );
  });


  group('processKeyHolderRemoval', () {
    const ownerPubkey = TestHexPubkeys.alice;
    const stewardPubkey = TestHexPubkeys.bob;
    const vaultId = 'test-removal-vault';

    late MockLoginService mockLoginService;
    late MockNdkService mockNdkService;
    late MockHorcruxNotificationService mockNotificationService;
    late MockPushNotificationReceiver mockPushReceiver;
    late VaultRepository repository;
    late VaultShareService service;

    setUp(() {
      mockLoginService = MockLoginService();
      when(mockLoginService.encryptText(any))
          .thenAnswer((inv) async => inv.positionalArguments[0] as String);
      when(mockLoginService.decryptText(any))
          .thenAnswer((inv) async => inv.positionalArguments[0] as String);

      mockNdkService = MockNdkService();
      when(mockNdkService.getCurrentPubkey())
          .thenAnswer((_) async => stewardPubkey);
      mockNotificationService = MockHorcruxNotificationService();
      mockPushReceiver = MockPushNotificationReceiver();

      repository = VaultRepository(mockLoginService);
      service = VaultShareService(
        repository,
        () => mockNdkService,
        () => mockNotificationService,
        () => mockPushReceiver,
      );
    });

    tearDown(() async {
      await repository.clearAll();
    });

    Nip01Event makeRemovalEvent({String? vaultIdTag}) {
      return Nip01Event(
        kind: NostrKind.keyHolderRemoved.value,
        pubKey: ownerPubkey,
        tags: [
          ['vault_id', vaultIdTag ?? vaultId],
        ],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        content: '',
      );
    }

    Future<void> addTestVaultWithShare() async {
      final vault = Vault(
        id: vaultId,
        name: 'Test Vault',
        createdAt: DateTime.now(),
        ownerPubkey: ownerPubkey,
      );
      await repository.addVault(vault);
      final share = createShare(
        payload: 'test-shard-payload',
        threshold: 1,
        shareIndex: 0,
        totalShares: 2,
        primeMod: 'test-prime-mod',
        creatorPubkey: ownerPubkey,
        vaultId: vaultId,
      );
      await repository.addShareToVault(vaultId, share);
    }

    test('archives the vault with reason Removed by owner', () async {
      await addTestVaultWithShare();
      final event = makeRemovalEvent();
      await service.processKeyHolderRemoval(event: event);

      final vault = await repository.getVault(vaultId);
      expect(vault, isNotNull);
      expect(vault!.isArchived, isTrue);
      expect(vault.archivedReason, 'Removed by owner');
    });

    test('removes the held share', () async {
      await addTestVaultWithShare();
      final sharesBefore = await repository.getSharesForVault(vaultId);
      expect(sharesBefore, isNotEmpty);

      final event = makeRemovalEvent();
      await service.processKeyHolderRemoval(event: event);

      final sharesAfter = await repository.getSharesForVault(vaultId);
      expect(sharesAfter, isEmpty);
    });

    test('reads vault_id from tags (canonical format)', () async {
      await addTestVaultWithShare();
      final event = makeRemovalEvent();
      expect(event.content, isEmpty);
      await service.processKeyHolderRemoval(event: event);

      final vault = await repository.getVault(vaultId);
      expect(vault!.isArchived, isTrue);
    });

    test('throws ArgumentError when vault_id tag is missing', () async {
      final event = Nip01Event(
        kind: NostrKind.keyHolderRemoved.value,
        pubKey: ownerPubkey,
        tags: [],
        createdAt: 1,
        content: '',
      );

      expect(
        () => service.processKeyHolderRemoval(event: event),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError on wrong event kind', () async {
      final event = Nip01Event(
        kind: 9999,
        pubKey: ownerPubkey,
        tags: [['vault_id', vaultId]],
        createdAt: 1,
        content: '',
      );

      expect(
        () => service.processKeyHolderRemoval(event: event),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('no-ops when vault not found (already deleted)', () async {
      final event = makeRemovalEvent(vaultIdTag: 'nonexistent-vault');
      await service.processKeyHolderRemoval(event: event);
    });
  });

  group('VaultShareService.processVaultShare relay sync', () {
    const vaultId = 'relay-sync-vault';
    const ownerPubkey = TestHexPubkeys.alice;
    const relayUrl = 'wss://test.relay.example.com';

    late MockLoginService mockLoginService;
    late MockNdkService mockNdkService;
    late MockHorcruxNotificationService mockNotificationService;
    late MockPushNotificationReceiver mockPushReceiver;
    late MockRelayScanService mockRelayScanService;
    late VaultRepository repository;
    late VaultShareService service;

    setUp(() {
      mockLoginService = MockLoginService();
      when(mockLoginService.encryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
      when(mockLoginService.decryptText(any))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);
      when(mockLoginService.getCurrentPublicKey()).thenAnswer((_) async => TestHexPubkeys.bob);

      mockNdkService = MockNdkService();
      when(mockNdkService.getCurrentPubkey()).thenAnswer((_) async => TestHexPubkeys.bob);
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: anyNamed('kind'),
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((_) async => Nip01Event(
            kind: NostrKind.shareConfirmation.value,
            pubKey: TestHexPubkeys.bob,
            tags: const [],
            content: '',
            createdAt: 1,
          ));

      mockNotificationService = MockHorcruxNotificationService();
      mockPushReceiver = MockPushNotificationReceiver();
      when(mockPushReceiver.isOptedIn()).thenAnswer((_) async => true);
      mockRelayScanService = MockRelayScanService();

      repository = VaultRepository(mockLoginService);
      service = VaultShareService(
        repository,
        () => mockNdkService,
        () => mockNotificationService,
        () => mockPushReceiver,
        () => mockRelayScanService,
      );

      when(mockRelayScanService.syncRelaysFromUrls(any)).thenAnswer((_) async => {});
    });

    test('syncs relay URLs from share data to RelayScanService', () async {
      final shard = createShare(
        payload: 'shard-data',
        threshold: 2,
        shareIndex: 0,
        totalShares: 2,
        primeMod: 'prime',
        creatorPubkey: ownerPubkey,
        vaultId: vaultId,
        vaultName: 'Relay Test',
        relayUrls: [relayUrl],
      );

      await service.processVaultShare(vaultId, shard);

      verify(mockRelayScanService.syncRelaysFromUrls([relayUrl])).called(1);
    });

    test('does not call syncRelaysFromUrls when relayUrls is null', () async {
      final shard = createShare(
        payload: 'shard-data-no-relay',
        threshold: 2,
        shareIndex: 1,
        totalShares: 2,
        primeMod: 'prime',
        creatorPubkey: ownerPubkey,
        vaultId: vaultId,
        vaultName: 'No Relay',
        relayUrls: null,
      );

      await service.processVaultShare(vaultId, shard);

      verifyNever(mockRelayScanService.syncRelaysFromUrls(any));
    });
  });
}
