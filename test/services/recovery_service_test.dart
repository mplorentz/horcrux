import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/recovery_request.dart';
import 'package:horcrux/models/shard_data.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/services/recovery_service.dart';
import 'package:horcrux/services/backup_service.dart';
import 'package:horcrux/services/shard_distribution_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/vault_share_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'recovery_service_test.mocks.dart';
import '../helpers/secure_storage_mock.dart';

@GenerateMocks([
  BackupService,
  ShardDistributionService,
  NdkService,
  VaultShareService,
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
    late VaultShareService vaultShareService;
    late RecoveryService recoveryService;
    const testKeyHolder1 = 'fedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321';
    const testKeyHolder2 = 'abcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdef1234';
    const testVaultId = 'vault-test-123';

    setUp(() async {
      secureStorageMock.clear();
      SharedPreferences.setMockInitialValues({});

      loginService = LoginService();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();

      // Generate a key pair for the test
      final keyPair = await loginService.generateAndStoreNostrKey();
      testCreatorPubkey = keyPair.publicKey;

      // Clear any existing recovery requests and vaults
      repository = VaultRepository(loginService);
      // Create mocks for circular dependency
      final mockBackupService = MockBackupService();
      final mockNdkService = MockNdkService();
      final mockVaultShareService = MockVaultShareService();

      // Stub the streams that RecoveryService accesses in its constructor
      when(
        mockNdkService.recoveryRequestStream,
      ).thenAnswer((_) => const Stream<RecoveryRequest>.empty());
      when(
        mockNdkService.recoveryResponseStream,
      ).thenAnswer((_) => const Stream<RecoveryResponseEvent>.empty());
      // Stub getCurrentPubkey to return the test creator pubkey
      when(
        mockNdkService.getCurrentPubkey(),
      ).thenAnswer((_) async => testCreatorPubkey);

      backupService = mockBackupService;
      ndkService = mockNdkService;
      vaultShareService = mockVaultShareService;
      recoveryService = RecoveryService(
        repository,
        backupService,
        ndkService,
        vaultShareService,
      );
      await recoveryService.clearAll();
      await repository.clearAll();

      // Create a test vault for recovery tests
      final testVault = Vault(
        id: testVaultId,
        name: 'Test Vault',
        content: 'Test vault content',
        createdAt: DateTime.now(),
        ownerPubkey: testCreatorPubkey,
      );
      await repository.addVault(testVault);
    });

    tearDown(() async {
      await repository.clearAll();
      await loginService.clearStoredKeys();
      loginService.resetCacheForTest();
    });

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
      expect(recoveryRequest.stewardResponses.length, 2);
      expect(
        recoveryRequest.stewardResponses.containsKey(testKeyHolder1),
        true,
      );
      expect(
        recoveryRequest.stewardResponses.containsKey(testKeyHolder2),
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

        final shardData = createShardData(
          shard: 'test_shard_data_base64',
          threshold: 2,
          shardIndex: 0,
          totalShards: 3,
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
          'shard_data': shardDataToJson(shardData),
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
        expect(shardDataJson['shardIndex'], 0);
        expect(shardDataJson['totalShards'], 3);
        expect(shardDataJson['creatorPubkey'], testCreatorPubkey);
        expect(shardDataJson['vaultId'], testVaultId);
        expect(shardDataJson['vaultName'], 'Test Vault');
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
      expect(recoveryRequest.stewardResponses.length, 2);
      expect(
        recoveryRequest.stewardResponses[testKeyHolder1]?.status,
        RecoveryResponseStatus.pending,
      );
      expect(
        recoveryRequest.stewardResponses[testKeyHolder2]?.status,
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

    test('recovery request contains proper expiration', () async {
      // Create request with default expiration
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1],
        threshold: 1,
      );

      // Verify expiration is set and in the future
      expect(recoveryRequest.expiresAt, isNotNull);
      expect(recoveryRequest.expiresAt!.isAfter(DateTime.now()), true);

      // Should default to ~24 hours
      final duration = recoveryRequest.expiresAt!.difference(
        recoveryRequest.requestedAt,
      );
      expect(duration.inHours, greaterThanOrEqualTo(23));
      expect(duration.inHours, lessThanOrEqualTo(25));
    });

    test('recovery request respects custom expiration duration', () async {
      // Create request with custom 2-hour expiration
      final recoveryRequest = await recoveryService.initiateRecovery(
        testVaultId,
        initiatorPubkey: testCreatorPubkey,
        stewardPubkeys: [testKeyHolder1],
        threshold: 1,
        expirationDuration: const Duration(hours: 2),
      );

      // Verify custom expiration
      expect(recoveryRequest.expiresAt, isNotNull);
      final duration = recoveryRequest.expiresAt!.difference(
        recoveryRequest.requestedAt,
      );
      expect(duration.inHours, greaterThanOrEqualTo(1));
      expect(duration.inHours, lessThanOrEqualTo(3));
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
      final shardData = createShardData(
        shard: 'recovered_shard_AAA=',
        threshold: 2,
        shardIndex: 0,
        totalShards: 3,
        primeMod: 'test_prime_CCC=',
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
        vaultName: 'Recovered Vault',
        stewards: [
          {'name': 'Steward 1', 'pubkey': testKeyHolder1},
        ],
      );

      // Respond to the recovery request (simulating what _handleRecoveryResponseData does)
      await recoveryService.respondToRecoveryRequest(
        recoveryRequest.id,
        testKeyHolder1,
        true, // approved
        shardData: shardData,
      );

      // Verify the response was recorded
      final updatedRequest = await recoveryService.getRecoveryRequest(
        recoveryRequest.id,
      );
      expect(updatedRequest, isNotNull);
      expect(
        updatedRequest!.stewardResponses[testKeyHolder1]?.status,
        RecoveryResponseStatus.approved,
      );
      expect(
        updatedRequest.stewardResponses[testKeyHolder1]?.shardData,
        isNotNull,
      );
      expect(
        updatedRequest.stewardResponses[testKeyHolder1]?.shardData?.shard,
        'recovered_shard_AAA=',
      );
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
      await recoveryService.respondToRecoveryRequest(
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
        updatedRequest!.stewardResponses[testKeyHolder1]?.status,
        RecoveryResponseStatus.denied,
      );
      expect(
        updatedRequest.stewardResponses[testKeyHolder1]?.shardData,
        isNull,
      );
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
      final shardData1 = createShardData(
        shard: 'shard_data_1_AAA=',
        threshold: 2,
        shardIndex: 0,
        totalShards: 2,
        primeMod: 'test_prime_DDD=',
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
      );

      // Create shard data for second steward
      final shardData2 = createShardData(
        shard: 'shard_data_2_BBB=',
        threshold: 2,
        shardIndex: 1,
        totalShards: 2,
        primeMod: 'test_prime_DDD=',
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
      );

      // First steward approves
      await recoveryService.respondToRecoveryRequest(
        recoveryRequest.id,
        testKeyHolder1,
        true, // approved
        shardData: shardData1,
      );

      // Second steward approves
      await recoveryService.respondToRecoveryRequest(
        recoveryRequest.id,
        testKeyHolder2,
        true, // approved
        shardData: shardData2,
      );

      // Verify both responses were recorded
      final updatedRequest = await recoveryService.getRecoveryRequest(
        recoveryRequest.id,
      );
      expect(updatedRequest, isNotNull);
      expect(updatedRequest!.approvedCount, 2);
      expect(
        updatedRequest.stewardResponses[testKeyHolder1]?.status,
        RecoveryResponseStatus.approved,
      );
      expect(
        updatedRequest.stewardResponses[testKeyHolder2]?.status,
        RecoveryResponseStatus.approved,
      );
      expect(
        updatedRequest.stewardResponses[testKeyHolder1]?.shardData,
        isNotNull,
      );
      expect(
        updatedRequest.stewardResponses[testKeyHolder2]?.shardData,
        isNotNull,
      );
      expect(
        updatedRequest.stewardResponses[testKeyHolder1]?.shardData?.shard,
        'shard_data_1_AAA=',
      );
      expect(
        updatedRequest.stewardResponses[testKeyHolder2]?.shardData?.shard,
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
        final shardData = createShardData(
          shard: 'practice_shard_secret_AAA=',
          threshold: 1,
          shardIndex: 0,
          totalShards: 1,
          primeMod: 'test_prime_EEE=',
          creatorPubkey: testCreatorPubkey,
          vaultId: testVaultId,
          vaultName: 'Test Vault',
          relayUrls: ['wss://relay.example.com'],
        );
        await repository.addShardToVault(testVaultId, shardData);

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
          ),
        ).thenAnswer((invocation) {
          capturedContent = invocation.namedArguments[#content] as String?;
          return Future.value('mock_event_id_12345');
        });

        // Act: Respond to the practice recovery request with approval
        await recoveryService.respondToRecoveryRequestWithShard(
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
      final shardData = createShardData(
        shard: 'real_shard_secret_BBB=',
        threshold: 1,
        shardIndex: 0,
        totalShards: 1,
        primeMod: 'test_prime_FFF=',
        creatorPubkey: testCreatorPubkey,
        vaultId: testVaultId,
        vaultName: 'Test Vault',
        relayUrls: ['wss://relay.example.com'],
      );
      await repository.addShardToVault(testVaultId, shardData);

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
        ),
      ).thenAnswer((invocation) {
        capturedContent = invocation.namedArguments[#content] as String?;
        return Future.value('mock_event_id_67890');
      });

      // Act: Respond to the REAL recovery request with approval
      await recoveryService.respondToRecoveryRequestWithShard(
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
      final sentShardData = decodedContent['shard_data'] as Map<String, dynamic>;
      expect(sentShardData['shard'], 'real_shard_secret_BBB=');
      expect(sentShardData['threshold'], 1);
      expect(sentShardData['shardIndex'], 0);
      expect(sentShardData['totalShards'], 1);

      // Log the captured content for verification
      // ignore: avoid_print
      print(
        'Captured real recovery response (with shard data): $capturedContent',
      );
    });
  });
}
