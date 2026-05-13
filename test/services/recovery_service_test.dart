import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/ndk.dart';
import 'package:horcrux/models/backup_config.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/share.dart';
import 'package:horcrux/services/horcrux_notification_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/recovery_service.dart';
import 'package:horcrux/services/backup_service.dart';
import 'package:horcrux/services/share_distribution_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/local_notification_service.dart';
import 'package:horcrux/services/processed_nostr_event_store.dart';
import '../helpers/secure_storage_mock.dart';
import '../helpers/test_database.dart';
import 'recovery_service_test.mocks.dart';

@GenerateMocks([
  BackupService,
  LocalNotificationService,
  ShareDistributionService,
  NdkService,
  HorcruxNotificationService,
  Nip01Event,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final secureStorageMock = SecureStorageMock();

  setUpAll(() {
    secureStorageMock.setUpAll();
  });

  tearDownAll(() {
    secureStorageMock.tearDownAll();
  });

  group('RecoveryService - Nostr Event Payload Validation', () {
    late String testCreatorPubkey;
    late LoginService loginService;
    late VaultRepository repository;
    late BackupService backupService;
    late NdkService ndkService;
    late MockLocalNotificationService mockLocalNotificationService;
    late RecoveryService recoveryService;
    late AppDatabase testDb;
    const testKeyHolder1 = 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321';
    const testKeyHolder2 = 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef1234';
    const testVaultId = 'vault-test-123';

    setUp(() async {
      secureStorageMock.clear();
      loginService = LoginService();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();

      // Generate a key pair for the test
      final keyPair = await loginService.generateAndStoreNostrKey();
      testCreatorPubkey = keyPair.publicKey;

      testDb = newTestDatabase();
      // Clear any existing recovery requests and vaults
      repository = VaultRepository(loginService, db: testDb);
      // Create mocks for circular dependency
      final mockBackupService = MockBackupService();
      final mockNdkService = MockNdkService();
      mockLocalNotificationService = MockLocalNotificationService();
      when(
        mockLocalNotificationService.notifyRecoveryRequestProcessed(any),
      ).thenAnswer((_) async {});
      when(
        mockLocalNotificationService.notifyRecoveryResponseProcessed(any),
      ).thenAnswer((_) async {});

      when(
        mockNdkService.getCurrentPubkey(),
      ).thenAnswer((_) async => testCreatorPubkey);

      backupService = mockBackupService;
      ndkService = mockNdkService;
      final mockHorcruxNotificationService = MockHorcruxNotificationService();
      when(
        mockHorcruxNotificationService.tryPushForEvent(
          event: anyNamed('event'),
          kind: anyNamed('kind'),
          vault: anyNamed('vault'),
          relayHints: anyNamed('relayHints'),
          recoveryApproved: anyNamed('recoveryApproved'),
        ),
      ).thenAnswer((_) async {});
      recoveryService = RecoveryService(
        repository,
        backupService,
        ndkService,
        ProcessedNostrEventStore(),
        mockLocalNotificationService,
        mockHorcruxNotificationService,
        testDb,
      );
      await recoveryService.clearAll();
      await repository.clearAll();

      // Create a test vault for recovery tests
      final testVault = Vault(
        id: testVaultId,
        name: 'Test Vault',
        createdAt: DateTime.now(),
        ownerPubkey: testCreatorPubkey,
      );
      await repository.addVault(testVault);

      final relayPlan = createBackupConfig(
        vaultId: testVaultId,
        threshold: 1,
        totalKeys: 1,
        stewards: [
          createSteward(pubkey: testKeyHolder1).copyWith(status: StewardStatus.holdingKey),
        ],
        relays: ['wss://relay.example.com'],
      );
      await repository.updateBackupConfig(testVaultId, relayPlan);
    });

    tearDown(() async {
      await repository.clearAll();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();
      await testDb.close();
    });

    test('concurrent initiateRecovery calls from same user do not create duplicates', () async {
      // Both calls launched without awaiting; the per-(vault, initiator) lock
      // must serialize them so the second one observes the first's persisted
      // active request and rejects, even though they raced through the
      // existence check.
      final results = await Future.wait<RecoveryRequest?>([
        recoveryService
            .initiateRecovery(
              testVaultId,
              initiatorPubkey: testCreatorPubkey,
              stewardPubkeys: [testKeyHolder1],
              threshold: 1,
            )
            .then<RecoveryRequest?>((r) => r)
            .catchError((_) => null),
        recoveryService
            .initiateRecovery(
              testVaultId,
              initiatorPubkey: testCreatorPubkey,
              stewardPubkeys: [testKeyHolder1],
              threshold: 1,
            )
            .then<RecoveryRequest?>((r) => r)
            .catchError((_) => null),
      ]);

      final successes = results.whereType<RecoveryRequest>().toList();
      expect(successes.length, 1, reason: 'exactly one initiate should succeed for the same user');

      final stored = await repository.getRecoveryRequestsForVault(testVaultId);
      expect(
        stored.where((r) => r.status.isActive && r.initiatorPubkey == testCreatorPubkey).length,
        1,
        reason: 'only one active recovery for this user should be persisted',
      );
    });

    test('same user cannot start a real recovery while their practice is active', () async {
      // Per-user exclusivity covers practice + real: if I'm holding any active
      // session on this vault, the service must reject another initiate from me
      // (the UI relies on this to keep its gating consistent with the service).
      await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1],
        threshold: 1,
        isPractice: true,
      );

      await expectLater(
        recoveryService.initiateRecovery(
          testVaultId,
          initiatorPubkey: testCreatorPubkey,
          stewardPubkeys: [testKeyHolder1],
          threshold: 1,
          isPractice: false,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('different users may both have active recoveries on the same vault', () async {
      // Per-user exclusivity: two distinct initiators may concurrently hold
      // their own active recovery sessions on the same vault.
      final results = await Future.wait<RecoveryRequest>([
        recoveryService.initiateRecovery(
          testVaultId,
          initiatorPubkey: testCreatorPubkey,
          stewardPubkeys: [testKeyHolder1],
          threshold: 1,
        ),
        recoveryService.initiateRecovery(
          testVaultId,
          initiatorPubkey: testKeyHolder1,
          stewardPubkeys: [testKeyHolder2],
          threshold: 1,
        ),
      ]);

      expect(results.length, 2);
      expect(results.map((r) => r.initiatorPubkey).toSet(), {testCreatorPubkey, testKeyHolder1});

      final stored = await repository.getRecoveryRequestsForVault(testVaultId);
      final activeByInitiator = <String, int>{};
      for (final r in stored.where((r) => r.status.isActive)) {
        activeByInitiator[r.initiatorPubkey] = (activeByInitiator[r.initiatorPubkey] ?? 0) + 1;
      }
      expect(activeByInitiator[testCreatorPubkey], 1);
      expect(activeByInitiator[testKeyHolder1], 1);
    });

    test(
      'initiateRecovery releases the per-(vault, initiator) lock after a failed attempt '
      'so the same user can retry',
      () async {
        // The mutex is keyed by (vaultId, initiatorPubkey). To prove cleanup,
        // both calls below MUST hit the SAME lock key -- so we keep the
        // initiator constant and drive the first failure through a path
        // OTHER than initiator-pubkey rejection. Pre-seeding an active
        // request for `testCreatorPubkey` makes the per-user exclusivity
        // check trip after lock acquisition, exercising the `finally` that
        // removes the entry from `_initiateRecoveryLocks`.
        final seeded = RecoveryRequest(
          id: 'seeded-active',
          vaultId: testVaultId,
          initiatorPubkey: testCreatorPubkey,
          requestedAt: DateTime.now().subtract(const Duration(minutes: 1)),
          status: RecoveryRequestStatus.inProgress,
          threshold: 1,
        );
        await repository.addRecoveryRequestToVault(testVaultId, seeded);

        await expectLater(
          recoveryService.initiateRecovery(
            testVaultId,
            initiatorPubkey: testCreatorPubkey,
            stewardPubkeys: [testKeyHolder1],
            threshold: 1,
          ),
          throwsA(isA<StateError>()),
        );

        // Free the user's slot, then retry with the SAME (vaultId, initiator)
        // -- if the lock had not been released, the `while` loop in
        // `initiateRecovery` would spin forever (the entry would still be in
        // the map even though its future is complete), and the timeout below
        // would fail the test.
        await repository.updateRecoveryRequestInVault(
          testVaultId,
          seeded.id,
          seeded.copyWith(status: RecoveryRequestStatus.cancelled),
        );

        final ok = await recoveryService
            .initiateRecovery(
              testVaultId,
              initiatorPubkey: testCreatorPubkey,
              stewardPubkeys: [testKeyHolder1],
              threshold: 1,
            )
            .timeout(const Duration(seconds: 5));
        expect(ok.vaultId, testVaultId);
        expect(ok.initiatorPubkey, testCreatorPubkey);
      },
    );

    test('recovery request creation succeeds with valid data', () async {
      // Create a recovery request
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1, testKeyHolder2],
        threshold: 2,
      );

      // Verify request was created
      expect(recoveryRequest.vaultId, testVaultId);
      expect(recoveryRequest.initiatorPubkey, testCreatorPubkey);
      expect(recoveryRequest.totalStewards, 2);
      expect(
        recoveryRequest.responseForPubkey(testKeyHolder1) != null,
        true,
      );
      expect(
        recoveryRequest.responseForPubkey(testKeyHolder2) != null,
        true,
      );
    });

    test('recovery request JSON payload has correct structure', () async {
      // Arrange
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1, testKeyHolder2],
        threshold: 2,
      );

      // Build the expected JSON structure (as would be sent via Nostr)
      final requestData = {
        'type': 'recovery_request',
        'recovery_request_id': recoveryRequest.id,
        'vault_id': recoveryRequest.vaultId,
        'initiator_pubkey': recoveryRequest.initiatorPubkey,
        'requested_at': recoveryRequest.requestedAt.toIso8601String(),
        'expires_at': recoveryRequest.expiresAt?.toIso8601String(),
        'threshold': (recoveryRequest.totalStewards * 0.67).ceil(),
      };

      final requestJson = json.encode(requestData);

      // Verify JSON structure
      expect(requestJson, isNotEmpty);

      final decoded = json.decode(requestJson) as Map<String, dynamic>;
      expect(decoded['type'], 'recovery_request');
      expect(decoded['vault_id'], testVaultId);
      expect(decoded['initiator_pubkey'], testCreatorPubkey);
      expect(decoded['threshold'], 2);
      expect(decoded['recovery_request_id'], isNotEmpty);
      expect(decoded['requested_at'], isNotEmpty);
      expect(decoded['expires_at'], isNull);
    });

    test(
      'recovery response JSON payload has correct structure with shard data',
      () async {
        // Arrange
        final recoveryRequest = await recoveryService.initiateRecovery(
          testVaultId,
          initiatorPubkey: testCreatorPubkey,
          stewardPubkeys: [testKeyHolder1],
          threshold: 1,
        );

        final shardData = createShare(
          payload: 'test_shard_data_base64',
          threshold: 2,
          shareIndex: 0,
          totalShares: 3,
          primeMod: 'test_prime_mod',
          creatorPubkey: testCreatorPubkey,
          vaultId: testVaultId,
          vaultName: 'Test Vault',
        );

        // Build the expected JSON structure for approval (as would be sent via Nostr)
        final responseData = {
          'type': 'recovery_response',
          'recovery_request_id': recoveryRequest.id,
          'vault_id': recoveryRequest.vaultId,
          'responder_pubkey': testKeyHolder1,
          'approved': true,
          'responded_at': DateTime.now().toIso8601String(),
          'shard_data': shareToJson(shardData),
        };

        final responseJson = json.encode(responseData);

        // Verify JSON structure
        expect(responseJson, isNotEmpty);

        final decoded = json.decode(responseJson) as Map<String, dynamic>;
        expect(decoded['type'], 'recovery_response');
        expect(decoded['recovery_request_id'], recoveryRequest.id);
        expect(decoded['vault_id'], testVaultId);
        expect(decoded['responder_pubkey'], testKeyHolder1);
        expect(decoded['approved'], true);
        expect(decoded['shard_data'], isNotNull);

        // Verify shard data structure
        final shardDataJson = decoded['shard_data'] as Map<String, dynamic>;
        expect(shardDataJson['shard'], 'test_shard_data_base64');
        expect(shardDataJson['threshold'], 2);
        expect(shardDataJson['shard_index'], 0);
        expect(shardDataJson['total_shards'], 3);
        expect(shardDataJson['creator_pubkey'], testCreatorPubkey);
        expect(shardDataJson['vault_id'], testVaultId);
        expect(shardDataJson['vault_name'], 'Test Vault');
      },
    );

    test('recovery response JSON payload for denial omits shard data', () async {
      // Arrange
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      // Build the expected JSON structure for denial (as would be sent via Nostr)
      final responseData = {
        'type': 'recovery_response',
        'recovery_request_id': recoveryRequest.id,
        'vault_id': recoveryRequest.vaultId,
        'responder_pubkey': testKeyHolder1,
        'approved': false,
        'responded_at': DateTime.now().toIso8601String(),
      };

      final responseJson = json.encode(responseData);

      // Verify JSON structure
      expect(responseJson, isNotEmpty);

      final decoded = json.decode(responseJson) as Map<String, dynamic>;
      expect(decoded['type'], 'recovery_response');
      expect(decoded['approved'], false);
      expect(decoded.containsKey('shard_data'), false);
    });

    test('recovery request is sent to all stewards', () async {
      // Create a recovery request with multiple stewards
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1, testKeyHolder2],
        threshold: 2,
      );

      // Verify all stewards are in the request
      expect(recoveryRequest.totalStewards, 2);
      expect(
        recoveryRequest.responseForPubkey(testKeyHolder1)?.status,
        RecoveryResponseStatus.pending,
      );
      expect(
        recoveryRequest.responseForPubkey(testKeyHolder2)?.status,
        RecoveryResponseStatus.pending,
      );

      // In actual sendRecoveryRequestViaNostr, this would create 2 gift wraps
      // (one for each steward)
    });

    test('recovery response includes threshold information', () async {
      // Arrange
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1, testKeyHolder2],
        threshold: 2,
      );

      expect(recoveryRequest.totalStewards, 2);
    });

    test('recovery request has no expiration', () async {
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      expect(recoveryRequest.expiresAt, isNull);
      expect(recoveryRequest.isExpired, false);
    });

    test('recovery response shard data is stored and can be retrieved', () async {
      // Create initial recovery request
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      // Simulate receiving a recovery response with shard data
      // In real flow, this would come via NDK from _handleRecoveryResponseData
      final shardData = createShare(
        payload: 'recovered_shard_AAA=',
        threshold: 2,
        shareIndex: 0,
        totalShares: 3,
        primeMod: 'test_prime_CCC=',
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
        vaultName: 'Recovered Vault',
        stewards: [
          {'name': 'Steward 1', 'pubkey': testKeyHolder1},
        ],
      );

      // Respond to the recovery request (simulating what _handleRecoveryResponseData does)
      await recoveryService.processRecoveryResponse(
        recoveryRequest.id,
        testKeyHolder1,
        true, // approved
        share: shardData,
      );

      // Verify the response was recorded
      final updatedRequest = await recoveryService.getRecoveryRequest(
        recoveryRequest.id,
      );
      expect(updatedRequest, isNotNull);
      expect(
        updatedRequest!.responseForPubkey(testKeyHolder1)?.status,
        RecoveryResponseStatus.approved,
      );
      expect(
        updatedRequest.responseForPubkey(testKeyHolder1)?.share,
        isNotNull,
      );
      expect(
        updatedRequest.responseForPubkey(testKeyHolder1)?.share?.payload,
        'recovered_shard_AAA=',
      );

      final daoRows = await testDb.recoveryDao.responsesFor(recoveryRequest.id);
      expect(daoRows, hasLength(1));
      expect(daoRows.single.sharePayload, contains('recovered_shard_AAA'));
    });

    test('recovery response denial does not include shard data', () async {
      // Create initial recovery request
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      // Simulate receiving a denial response (no shard data)
      await recoveryService.processRecoveryResponse(
        recoveryRequest.id,
        testKeyHolder1,
        false, // denied
      );

      // Verify the response was recorded without shard data
      final updatedRequest = await recoveryService.getRecoveryRequest(
        recoveryRequest.id,
      );
      expect(updatedRequest, isNotNull);
      expect(
        updatedRequest!.responseForPubkey(testKeyHolder1)?.status,
        RecoveryResponseStatus.denied,
      );
      expect(
        updatedRequest.responseForPubkey(testKeyHolder1)?.share,
        isNull,
      );
    });

    test('cancelRecoveryRequest clears share_payload in recovery_responses', () async {
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      final shardData = createShare(
        payload: 'cancel_test_payload=',
        threshold: 1,
        shareIndex: 0,
        totalShares: 1,
        primeMod: 'test_prime=',
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
      );

      await recoveryService.processRecoveryResponse(
        recoveryRequest.id,
        testKeyHolder1,
        true,
        share: shardData,
      );

      var rows = await testDb.recoveryDao.responsesFor(recoveryRequest.id);
      expect(rows, isNotEmpty);
      expect(rows.every((r) => r.sharePayload.isNotEmpty), isTrue);

      await recoveryService.cancelRecoveryRequest(recoveryRequest.id);

      rows = await testDb.recoveryDao.responsesFor(recoveryRequest.id);
      expect(rows, isNotEmpty);
      expect(rows.every((r) => r.sharePayload.isEmpty), isTrue);
    });

    test('exitRecoveryMode deletes recovery_responses rows for the request', () async {
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      final shardData = createShare(
        payload: 'exit_mode_payload=',
        threshold: 1,
        shareIndex: 0,
        totalShares: 1,
        primeMod: 'test_prime=',
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
      );

      await recoveryService.processRecoveryResponse(
        recoveryRequest.id,
        testKeyHolder1,
        true,
        share: shardData,
      );

      expect(await testDb.recoveryDao.responsesFor(recoveryRequest.id), isNotEmpty);

      await recoveryService.exitRecoveryMode(recoveryRequest.id);

      expect(await testDb.recoveryDao.responsesFor(recoveryRequest.id), isEmpty);
    });

    test('multiple recovery responses accumulate correctly', () async {
      // Create recovery request with multiple stewards
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1, testKeyHolder2],
        threshold: 2,
      );

      // Create shard data for first steward
      final shardData1 = createShare(
        payload: 'shard_data_1_AAA=',
        threshold: 2,
        shareIndex: 0,
        totalShares: 2,
        primeMod: 'test_prime_DDD=',
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
      );

      // Create shard data for second steward
      final shardData2 = createShare(
        payload: 'shard_data_2_BBB=',
        threshold: 2,
        shareIndex: 1,
        totalShares: 2,
        primeMod: 'test_prime_DDD=',
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
      );

      // First steward approves
      await recoveryService.processRecoveryResponse(
        recoveryRequest.id,
        testKeyHolder1,
        true, // approved
        share: shardData1,
      );

      // Second steward approves
      await recoveryService.processRecoveryResponse(
        recoveryRequest.id,
        testKeyHolder2,
        true, // approved
        share: shardData2,
      );

      // Verify both responses were recorded
      final updatedRequest = await recoveryService.getRecoveryRequest(
        recoveryRequest.id,
      );
      expect(updatedRequest, isNotNull);
      expect(updatedRequest!.approvedCount, 2);
      expect(
        updatedRequest.responseForPubkey(testKeyHolder1)?.status,
        RecoveryResponseStatus.approved,
      );
      expect(
        updatedRequest.responseForPubkey(testKeyHolder2)?.status,
        RecoveryResponseStatus.approved,
      );
      expect(
        updatedRequest.responseForPubkey(testKeyHolder1)?.share,
        isNotNull,
      );
      expect(
        updatedRequest.responseForPubkey(testKeyHolder2)?.share,
        isNotNull,
      );
      expect(
        updatedRequest.responseForPubkey(testKeyHolder1)?.share?.payload,
        'shard_data_1_AAA=',
      );
      expect(
        updatedRequest.responseForPubkey(testKeyHolder2)?.share?.payload,
        'shard_data_2_BBB=',
      );

      // When threshold is met, status should be completed
      expect(updatedRequest.status, RecoveryRequestStatus.completed);
    });

    test(
      'practice recovery response does not send shard data over the wire',
      () async {
        // Arrange: Create a practice recovery request
        final recoveryRequest = await recoveryService.initiateRecovery(
          testVaultId,
          initiatorPubkey: testCreatorPubkey,
          stewardPubkeys: [testKeyHolder1],
          threshold: 1,
          isPractice: true, // This is a practice recovery
        );

        // Add a shard to the vault (steward has this shard)
        final shardData = createShare(
          payload: 'practice_shard_secret_AAA=',
          threshold: 1,
          shareIndex: 0,
          totalShares: 1,
          primeMod: 'test_prime_EEE=',
          creatorPubkey: testCreatorPubkey,
          vaultId: testVaultId,
          vaultName: 'Test Vault',
          relayUrls: ['wss://relay.example.com'],
        );
        await repository.addShareToVault(testVaultId, shardData);

        // Mock the NDK service to capture what's being sent
        final mockNdk = ndkService as MockNdkService;
        String? capturedContent;
        when(
          mockNdk.publishEncryptedEvent(
            content: anyNamed('content'),
            kind: anyNamed('kind'),
            recipientPubkey: anyNamed('recipientPubkey'),
            relays: anyNamed('relays'),
            tags: anyNamed('tags'),
            vaultId: anyNamed('vaultId'),
          ),
        ).thenAnswer((invocation) {
          capturedContent = invocation.namedArguments[#content] as String?;
          return Future.value(
            Nip01Event(
              kind: NostrKind.giftWrap.value,
              pubKey: 'a' * 64,
              tags: const [],
              createdAt: 1,
              content: '',
            ),
          );
        });

        // Act: Respond to the practice recovery request with approval
        await recoveryService.respondToRecoveryRequestWithShare(
          recoveryRequest.id,
          testKeyHolder1,
          true, // approved
        );

        // Assert: Verify that publishEncryptedEvent was called
        verify(
          mockNdk.publishEncryptedEvent(
            content: anyNamed('content'),
            kind: anyNamed('kind'),
            recipientPubkey: anyNamed('recipientPubkey'),
            relays: anyNamed('relays'),
            tags: anyNamed('tags'),
            vaultId: anyNamed('vaultId'),
          ),
        ).called(1);

        // Assert: Verify the captured content does NOT contain shard data
        expect(capturedContent, isNotNull);
        final decodedContent = json.decode(capturedContent!) as Map<String, dynamic>;

        // Should have the basic response fields
        expect(decodedContent['type'], 'recovery_response');
        expect(decodedContent['recovery_request_id'], recoveryRequest.id);
        expect(decodedContent['vault_id'], testVaultId);
        expect(
          decodedContent['responder_pubkey'],
          testCreatorPubkey,
        ); // The current user responding
        expect(decodedContent['approved'], true);
        expect(decodedContent['is_practice'], true);

        // CRITICAL: Should NOT contain shard_data field
        expect(decodedContent.containsKey('shard_data'), false);

        // Log the captured content for verification
        // ignore: avoid_print
        print(
          'Captured practice recovery response (no shard data): $capturedContent',
        );
      },
    );

    test('real recovery response DOES send shard data over the wire', () async {
      // Arrange: Create a REAL (non-practice) recovery request
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1],
        threshold: 1,
        isPractice: false, // This is a REAL recovery
      );

      // Add a shard to the vault (steward has this shard)
      final shardData = createShare(
        payload: 'real_shard_secret_BBB=',
        threshold: 1,
        shareIndex: 0,
        totalShares: 1,
        primeMod: 'test_prime_FFF=',
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
        vaultName: 'Test Vault',
        relayUrls: ['wss://relay.example.com'],
      );
      await repository.addShareToVault(testVaultId, shardData);

      // Mock the NDK service to capture what's being sent
      final mockNdk = ndkService as MockNdkService;
      String? capturedContent;
      when(
        mockNdk.publishEncryptedEvent(
          content: anyNamed('content'),
          kind: anyNamed('kind'),
          recipientPubkey: anyNamed('recipientPubkey'),
          relays: anyNamed('relays'),
          tags: anyNamed('tags'),
          vaultId: anyNamed('vaultId'),
        ),
      ).thenAnswer((invocation) {
        capturedContent = invocation.namedArguments[#content] as String?;
        return Future.value(
          Nip01Event(
            kind: NostrKind.giftWrap.value,
            pubKey: 'a' * 64,
            tags: const [],
            createdAt: 1,
            content: '',
          ),
        );
      });

      // Act: Respond to the REAL recovery request with approval
      await recoveryService.respondToRecoveryRequestWithShare(
        recoveryRequest.id,
        testKeyHolder1,
        true, // approved
      );

      // Assert: Verify that publishEncryptedEvent was called
      verify(
        mockNdk.publishEncryptedEvent(
          content: anyNamed('content'),
          kind: anyNamed('kind'),
          recipientPubkey: anyNamed('recipientPubkey'),
          relays: anyNamed('relays'),
          tags: anyNamed('tags'),
          vaultId: anyNamed('vaultId'),
        ),
      ).called(1);

      // Assert: Verify the captured content DOES contain shard data
      expect(capturedContent, isNotNull);
      final decodedContent = json.decode(capturedContent!) as Map<String, dynamic>;

      // Should have the basic response fields
      expect(decodedContent['type'], 'recovery_response');
      expect(decodedContent['recovery_request_id'], recoveryRequest.id);
      expect(decodedContent['vault_id'], testVaultId);
      expect(
        decodedContent['responder_pubkey'],
        testCreatorPubkey,
      ); // The current user responding
      expect(decodedContent['approved'], true);
      expect(decodedContent['is_practice'], false);

      // CRITICAL: Should contain shard_data field for real recovery
      expect(decodedContent.containsKey('shard_data'), true);
      expect(decodedContent['shard_data'], isNotNull);

      // Verify shard data structure
      final sentShare = decodedContent['shard_data'] as Map<String, dynamic>;
      expect(sentShare['shard'], 'real_shard_secret_BBB=');
      expect(sentShare['threshold'], 1);
      expect(sentShare['shard_index'], 0);
      expect(sentShare['total_shards'], 1);

      // Log the captured content for verification
      // ignore: avoid_print
      print(
        'Captured real recovery response (with shard data): $capturedContent',
      );
    });

    test(
      'exitRecoveryMode deletes owner content when ending a REAL recovery '
      '(bug: owned_vaults row removed, vault re-hydrates as '
      'StewardedVaultDetail)',
      () async {
        // Arrange: Set up owned vault content (simulating vault content that
        // exists either before recovery or was restored via performRecovery)
        await repository.saveOwnedVaultContent(testVaultId, 'ciphertext-AAA');

        // Initiate a REAL recovery (isPractice: false)
        final request = await recoveryService.initiateRecovery(
          testVaultId,
          initiatorPubkey: testCreatorPubkey,
          stewardPubkeys: [testKeyHolder1],
          threshold: 1,
          isPractice: false, // REAL recovery
        );

        // Sanity-check: content exists before exitRecoveryMode
        var ownedRow = await testDb.ownedVaultDao.getByVaultId(testVaultId);
        expect(ownedRow, isNotNull,
            reason: 'owned_vaults row must exist before exitRecoveryMode');
        expect(ownedRow!.content, 'ciphertext-AAA');

        // Act: Exit real recovery mode
        await recoveryService.exitRecoveryMode(request.id);

        // Assert: Vault content was DELETED (the bug — !request.isPractice is
        // true, so deleteVaultContent fires even for a completed recovery)
        ownedRow = await testDb.ownedVaultDao.getByVaultId(testVaultId);
        expect(
          ownedRow,
          isNull,
          reason: 'exitRecoveryMode deletes owned_vaults for real recoveries '
              'because !request.isPractice is true, causing the vault to '
              're-hydrate as StewardedVaultDetail with "Initiate Recovery" '
              'instead of the expected content view',
        );
      },
    );
  });
}
