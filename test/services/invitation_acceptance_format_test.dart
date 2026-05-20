import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/ndk.dart';

import 'package:horcrux/services/invitation_sending_service.dart';
import 'package:horcrux/services/invitation_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
import 'package:horcrux/services/backup_service.dart';
import 'package:horcrux/database/app_database.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/utils/date_time_extensions.dart';
import '../fixtures/test_keys.dart';
import '../helpers/test_database.dart';

import 'invitation_acceptance_format_test.mocks.dart';

/// Synthesizes a minimal signed gift wrap event for stubs that only care
/// that [NdkService.publishEncryptedEvent] "succeeded". The tests below
/// verify what we asked the service to publish, not the specifics of the
/// returned event.
Nip01Event _stubGiftWrap() => Nip01Event(
      kind: NostrKind.giftWrap.value,
      pubKey: 'a' * 64,
      tags: const [],
      createdAt: 1,
      content: '',
    );

@GenerateMocks([
  NdkService,
  LoginService,
  VaultRepository,
  InvitationSendingService,
  RelayScanService,
  BackupService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Invitation Acceptance Event Format Compatibility Tests', () {
    late MockNdkService mockNdkService;
    late MockLoginService mockLoginService;
    late VaultRepository realRepository;
    late MockInvitationSendingService mockInvitationSendingService;
    late InvitationSendingService invitationSendingService;
    late InvitationService invitationService;
    late AppDatabase testDb;

    setUp(() async {
      mockNdkService = MockNdkService();
      mockLoginService = MockLoginService();
      testDb = newTestDatabase();
      realRepository = VaultRepository(mockLoginService, db: testDb);
      mockInvitationSendingService = MockInvitationSendingService();

      invitationSendingService = InvitationSendingService(mockNdkService);
      final mockRelayScanService = MockRelayScanService();
      final mockBackupService = MockBackupService();
      invitationService = InvitationService(
        realRepository,
        mockInvitationSendingService,
        mockLoginService,
        () => mockNdkService,
        mockRelayScanService,
        mockBackupService,
        testDb,
      );
    });

    tearDown(() async {
      await testDb.close();
    });

    test(
      'sendInvitationAcceptanceEvent creates tag-based event that processInvitationAcceptanceEvent can parse',
      () async {
        // Arrange
        const inviteCode = 'test-invite-code-123';
        const ownerPubkey = TestHexPubkeys.alice;
        const inviteePubkey = TestHexPubkeys.bob;
        final relayUrls = ['ws://localhost:10547'];

        // Mock NdkService.getCurrentPubkey() to return invitee pubkey
        when(
          mockNdkService.getCurrentPubkey(),
        ).thenAnswer((_) async => inviteePubkey);

        // Capture the content and tags passed to publishEncryptedEvent
        String? capturedContent;
        List<List<String>>? capturedTags;
        when(
          mockNdkService.publishEncryptedEvent(
            content: anyNamed('content'),
            kind: anyNamed('kind'),
            recipientPubkey: anyNamed('recipientPubkey'),
            relays: anyNamed('relays'),
            tags: anyNamed('tags'),
          ),
        ).thenAnswer((invocation) async {
          capturedContent = invocation.namedArguments[#content] as String;
          capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
          return _stubGiftWrap();
        });

        // Act: Call sendInvitationAcceptanceEvent
        await invitationSendingService.sendInvitationAcceptanceEvent(
          inviteCode: inviteCode,
          vaultId: 'test-vault-id',
          ownerPubkey: ownerPubkey,
          relayUrls: relayUrls,
        );

        // Verify content is empty (canonical format uses tags, not JSON)
        expect(capturedContent, isEmpty);
        expect(capturedTags, isNotNull);

        // Now create a mock event using the tag-based format
        final mockEvent = Nip01Event(
          kind: NostrKind.invitationAcceptance.value,
          pubKey: inviteePubkey,
          tags: [
            ['invite_code', inviteCode],
            ['vault_id', 'test-vault-id'],
          ],
          createdAt: secondsSinceEpoch(),
          content: '',
        );

        // Mock LoginService.getCurrentPublicKey() to return owner pubkey
        when(
          mockLoginService.getCurrentPublicKey(),
        ).thenAnswer((_) async => ownerPubkey);

        // Mock encryptText for vault storage
        when(mockLoginService.encryptText(any)).thenAnswer(
          (invocation) async => invocation.positionalArguments[0] as String,
        );

        // Mock decryptText for vault retrieval
        when(mockLoginService.decryptText(any)).thenAnswer(
          (invocation) async => invocation.positionalArguments[0] as String,
        );

        // Create and save the invitation using InvitationService
        await invitationService.createReceivedInvitation(
          inviteCode: inviteCode,
          vaultId: 'test-vault-id',
          ownerPubkey: ownerPubkey,
          relayUrls: relayUrls,
          vaultName: 'Test Vault',
        );

        // Create a vault so backup config can be created
        final testVault = Vault(
          id: 'test-vault-id',
          name: 'Test Vault',
          createdAt: DateTime.now(),
          ownerPubkey: ownerPubkey,
        );
        await realRepository.addVault(testVault);

        // Act: Call processInvitationAcceptanceEvent with the tag-based event
        await invitationService.processInvitationAcceptanceEvent(event: mockEvent);

        // Verify it succeeded (no exception thrown)
        // The invitation should now be marked as redeemed
        final redeemedInvitation = await invitationService.lookupInvitationByCode(inviteCode);
        expect(redeemedInvitation, isNotNull);
        expect(redeemedInvitation!.status.name, 'redeemed');
        expect(redeemedInvitation.redeemedBy, inviteePubkey);
      },
    );

    test(
      'processInvitationAcceptanceEvent throws ArgumentError for missing inviteCode tag',
      () async {
        // Arrange
        const ownerPubkey = TestHexPubkeys.alice;
        const inviteePubkey = TestHexPubkeys.bob;

        // Create event with missing invite_code tag (empty tags)
        final mockEvent = Nip01Event(
          kind: NostrKind.invitationAcceptance.value,
          pubKey: inviteePubkey,
          tags: [],
          createdAt: secondsSinceEpoch(),
          content: '',
        );

        when(
          mockLoginService.getCurrentPublicKey(),
        ).thenAnswer((_) async => ownerPubkey);

        // Act & Assert
        expect(
          () => invitationService.processInvitationAcceptanceEvent(event: mockEvent),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'toString',
              contains('Missing invite_code'),
            ),
          ),
        );
      },
    );

    test('processInvitationAcceptanceEvent throws ArgumentError for invalid pubkey', () async {
      // Arrange
      const ownerPubkey = TestHexPubkeys.alice;
      const inviteCode = 'test-invite-code';

      // Create event with invalid pubkey (wrong length) on event.pubKey
      final mockEvent = Nip01Event(
        kind: NostrKind.invitationAcceptance.value,
        pubKey: 'short', // Should be 64 chars
        tags: [
          ['invite_code', inviteCode],
        ],
        createdAt: secondsSinceEpoch(),
        content: '',
      );

      when(
        mockLoginService.getCurrentPublicKey(),
      ).thenAnswer((_) async => ownerPubkey);

      // Act & Assert
      expect(
        () => invitationService.processInvitationAcceptanceEvent(event: mockEvent),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'toString',
            contains('Invalid invitee pubkey'),
          ),
        ),
      );
    });

    test('processInvitationAcceptanceEvent catches pubkey mismatch via event author', () async {
      // Arrange
      const ownerPubkey = TestHexPubkeys.alice;
      const differentPubkey = TestHexPubkeys.charlie;
      // Use a valid Base64URL invite code
      const inviteCode = 'dGVzdF9iYXNlNjRfY29kZQ';

      // In the new canonical format, the invitee pubkey comes from event.pubKey.
      // Create a received invitation first.
      await invitationService.createReceivedInvitation(
        inviteCode: inviteCode,
        vaultId: 'test-vault-id',
        ownerPubkey: ownerPubkey,
        relayUrls: ['ws://localhost:10547'],
        vaultName: 'Test Vault',
      );

      final testVault = Vault(
        id: 'test-vault-id',
        name: 'Test Vault',
        createdAt: DateTime.now(),
        ownerPubkey: ownerPubkey,
      );
      await realRepository.addVault(testVault);

      // Create event where event.pubKey doesn't match expected invitee
      final mockEvent = Nip01Event(
        kind: NostrKind.invitationAcceptance.value,
        pubKey: differentPubkey, // Different from what invitation expects
        tags: [
          ['invite_code', inviteCode],
          ['vault_id', 'test-vault-id'],
        ],
        createdAt: secondsSinceEpoch(),
        content: '',
      );

      when(
        mockLoginService.getCurrentPublicKey(),
      ).thenAnswer((_) async => ownerPubkey);

      when(mockLoginService.encryptText(any)).thenAnswer(
        (invocation) async => invocation.positionalArguments[0] as String,
      );

      // Act - The event author (differentPubkey) won't match the invited
      // steward pubkey, but the code handles this gracefully by adding
      // the new pubkey as a steward. It should not throw an ArgumentError.
      await invitationService.processInvitationAcceptanceEvent(event: mockEvent);

      // Verify the invitation was processed (steward added for differentPubkey)
      final invitation = await invitationService.lookupInvitationByCode(inviteCode);
      expect(invitation, isNotNull);
      expect(invitation!.status.name, 'redeemed');
      expect(invitation.redeemedBy, differentPubkey);
    });

    test('processInvitationAcceptanceEvent silently ignores unknown invitation', () async {
      // Arrange
      const ownerPubkey = TestHexPubkeys.alice;
      const inviteePubkey = TestHexPubkeys.bob;
      // Use a valid Base64URL invite code (no padding, Base64URL format)
      const inviteCode = 'dGVzdF9iYXNlNjRfY29kZQ'; // Base64URL without padding

      final mockEvent = Nip01Event(
        kind: NostrKind.invitationAcceptance.value,
        pubKey: inviteePubkey,
        tags: [
          ['invite_code', inviteCode],
        ],
        createdAt: secondsSinceEpoch(),
        content: '',
      );

      when(
        mockLoginService.getCurrentPublicKey(),
      ).thenAnswer((_) async => ownerPubkey);

      // Act: Should not throw, just silently ignore
      await invitationService.processInvitationAcceptanceEvent(event: mockEvent);

      // Verify invitation doesn't exist
      final invitation = await invitationService.lookupInvitationByCode(
        inviteCode,
      );
      expect(invitation, isNull);
    });

    test('sendInvitationAcceptanceEvent publishes canonical tags', () async {
      // Arrange
      const inviteCode = 'test-code-xyz';
      const ownerPubkey = TestHexPubkeys.alice;
      const inviteePubkey = TestHexPubkeys.bob;
      final relayUrls = ['ws://localhost:10547'];

      when(
        mockNdkService.getCurrentPubkey(),
      ).thenAnswer((_) async => inviteePubkey);

      String? capturedContent;
      List<List<String>>? capturedTags;
      when(
        mockNdkService.publishEncryptedEvent(
          content: anyNamed('content'),
          kind: anyNamed('kind'),
          recipientPubkey: anyNamed('recipientPubkey'),
          relays: anyNamed('relays'),
          tags: anyNamed('tags'),
        ),
      ).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
        return _stubGiftWrap();
      });

      // Act
      await invitationSendingService.sendInvitationAcceptanceEvent(
        inviteCode: inviteCode,
        vaultId: 'vault-for-structure-test',
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
      );

      // Assert: Content is empty (canonical format), tags carry metadata
      expect(capturedContent, isEmpty);
      expect(capturedTags, isNotNull);
      expect(capturedTags!.any((t) => t[0] == 'invite_code' && t[1] == inviteCode), true);
      expect(
        capturedTags!.any((t) => t[0] == 'vault_id' && t[1] == 'vault-for-structure-test'),
        true,
      );
    });
  });

  group('sendInvitationAcceptanceEvent Unit Tests', () {
    late MockNdkService mockNdkService;
    late InvitationSendingService invitationSendingService;

    setUp(() {
      mockNdkService = MockNdkService();
      invitationSendingService = InvitationSendingService(mockNdkService);
    });

    test(
      'sendInvitationAcceptanceEvent calls publishEncryptedEvent with correct parameters',
      () async {
        // Arrange
        const inviteCode = 'test-invite-code-abc';
        const ownerPubkey = TestHexPubkeys.alice;
        const inviteePubkey = TestHexPubkeys.bob;
        final relayUrls = ['ws://localhost:10547', 'wss://relay.example.com'];

        when(
          mockNdkService.getCurrentPubkey(),
        ).thenAnswer((_) async => inviteePubkey);

        int? capturedKind;
        String? capturedRecipientPubkey;
        List<String>? capturedRelays;
        List<List<String>>? capturedTags;
        String? capturedContent;

        when(
          mockNdkService.publishEncryptedEvent(
            content: anyNamed('content'),
            kind: anyNamed('kind'),
            recipientPubkey: anyNamed('recipientPubkey'),
            relays: anyNamed('relays'),
            tags: anyNamed('tags'),
          ),
        ).thenAnswer((invocation) async {
          capturedKind = invocation.namedArguments[#kind] as int;
          capturedContent = invocation.namedArguments[#content] as String;
          capturedRecipientPubkey = invocation.namedArguments[#recipientPubkey] as String;
          capturedRelays = invocation.namedArguments[#relays] as List<String>;
          capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
          return _stubGiftWrap();
        });

        // Act
        final result = await invitationSendingService.sendInvitationAcceptanceEvent(
          inviteCode: inviteCode,
          vaultId: 'vault-param-test',
          ownerPubkey: ownerPubkey,
          relayUrls: relayUrls,
        );

        // Assert
        expect(result, _stubGiftWrap().id);
        expect(capturedKind, NostrKind.invitationAcceptance.value);
        expect(capturedRecipientPubkey, ownerPubkey);
        expect(capturedRelays, relayUrls);
        expect(capturedContent, isEmpty);
        expect(capturedTags, isNotNull);
        expect(capturedTags!.length, 2);
        expect(capturedTags![0], ['invite_code', inviteCode]);
        expect(capturedTags![1], ['vault_id', 'vault-param-test']);
      },
    );

    test('sendInvitationAcceptanceEvent creates payload with correct tags', () async {
      // Arrange
      const inviteCode = 'test-code-123';
      const ownerPubkey = TestHexPubkeys.alice;
      const inviteePubkey = TestHexPubkeys.bob;
      final relayUrls = ['ws://localhost:10547'];

      when(
        mockNdkService.getCurrentPubkey(),
      ).thenAnswer((_) async => inviteePubkey);

      String? capturedContent;
      List<List<String>>? capturedTags;
      when(
        mockNdkService.publishEncryptedEvent(
          content: anyNamed('content'),
          kind: anyNamed('kind'),
          recipientPubkey: anyNamed('recipientPubkey'),
          relays: anyNamed('relays'),
          tags: anyNamed('tags'),
        ),
      ).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
        return _stubGiftWrap();
      });

      // Act
      await invitationSendingService.sendInvitationAcceptanceEvent(
        inviteCode: inviteCode,
        vaultId: 'vault-field-names-test',
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
      );

      // Assert: Content is empty, tags have the right structure
      expect(capturedContent, isEmpty);
      expect(capturedTags, isNotNull);

      // Verify tag structure: [invite_code, code], [vault_id, vaultId]
      expect(
        capturedTags!.any((t) => t[0] == 'invite_code' && t[1] == inviteCode),
        true,
        reason: 'Tags must contain invite_code',
      );
      expect(
        capturedTags!.any((t) => t[0] == 'vault_id' && t[1] == 'vault-field-names-test'),
        true,
        reason: 'Tags must contain vault_id',
      );

      // Verify no extra unexpected tags
      expect(capturedTags!.length, 2);
    });

    test('sendInvitationAcceptanceEvent returns null when publishEncryptedEvent fails', () async {
      // Arrange
      when(
        mockNdkService.publishEncryptedEvent(
          content: anyNamed('content'),
          kind: anyNamed('kind'),
          recipientPubkey: anyNamed('recipientPubkey'),
          relays: anyNamed('relays'),
          tags: anyNamed('tags'),
        ),
      ).thenThrow(Exception('publish failed'));

      // Act
      final result = await invitationSendingService.sendInvitationAcceptanceEvent(
        inviteCode: 'test-code',
        vaultId: 'vault-null-pubkey-test',
        ownerPubkey: TestHexPubkeys.alice,
        relayUrls: ['ws://localhost:10547'],
      );

      // Assert
      expect(result, isNull);
    });

    test(
      'sendInvitationAcceptanceEvent handles publishEncryptedEvent errors gracefully',
      () async {
        // Arrange
        const inviteCode = 'test-code';
        const ownerPubkey = TestHexPubkeys.alice;
        const inviteePubkey = TestHexPubkeys.bob;

        when(
          mockNdkService.getCurrentPubkey(),
        ).thenAnswer((_) async => inviteePubkey);
        when(
          mockNdkService.publishEncryptedEvent(
            content: anyNamed('content'),
            kind: anyNamed('kind'),
            recipientPubkey: anyNamed('recipientPubkey'),
            relays: anyNamed('relays'),
            tags: anyNamed('tags'),
          ),
        ).thenThrow(Exception('Network error'));

        // Act
        final result = await invitationSendingService.sendInvitationAcceptanceEvent(
          inviteCode: inviteCode,
          vaultId: 'vault-network-error-test',
          ownerPubkey: ownerPubkey,
          relayUrls: ['ws://localhost:10547'],
        );

        // Assert: Should return null on error, not throw
        expect(result, isNull);
      },
    );

    test('sendInvitationAcceptanceEvent includes invite code and vault_id in tags', () async {
      // Arrange
      const inviteCode = 'special-invite-code-xyz';
      const ownerPubkey = TestHexPubkeys.alice;
      const inviteePubkey = TestHexPubkeys.bob;

      when(
        mockNdkService.getCurrentPubkey(),
      ).thenAnswer((_) async => inviteePubkey);

      List<List<String>>? capturedTags;
      when(
        mockNdkService.publishEncryptedEvent(
          content: anyNamed('content'),
          kind: anyNamed('kind'),
          recipientPubkey: anyNamed('recipientPubkey'),
          relays: anyNamed('relays'),
          tags: anyNamed('tags'),
        ),
      ).thenAnswer((invocation) async {
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
        return _stubGiftWrap();
      });

      // Act
      await invitationSendingService.sendInvitationAcceptanceEvent(
        inviteCode: inviteCode,
        vaultId: 'vault-tags-test',
        ownerPubkey: ownerPubkey,
        relayUrls: ['ws://localhost:10547'],
      );

      // Assert: Verify invite code and vault_id are in tags
      expect(capturedTags, isNotNull);
      expect(
        capturedTags!.any((t) => t.length >= 2 && t[0] == 'invite_code' && t[1] == inviteCode),
        true,
      );
      expect(
        capturedTags!.any((t) => t.length >= 2 && t[0] == 'vault_id' && t[1] == 'vault-tags-test'),
        true,
      );
    });

    test(
      'sendInvitationAcceptanceEvent uses canonical tag-based format (no JSON content)',
      () async {
        // Arrange
        const inviteCode = 'roundtrip-test-code';
        const ownerPubkey = TestHexPubkeys.alice;
        const inviteePubkey = TestHexPubkeys.bob;

        when(
          mockNdkService.getCurrentPubkey(),
        ).thenAnswer((_) async => inviteePubkey);

        String? capturedContent;
        List<List<String>>? capturedTags;
        when(
          mockNdkService.publishEncryptedEvent(
            content: anyNamed('content'),
            kind: anyNamed('kind'),
            recipientPubkey: anyNamed('recipientPubkey'),
            relays: anyNamed('relays'),
            tags: anyNamed('tags'),
          ),
        ).thenAnswer((invocation) async {
          capturedContent = invocation.namedArguments[#content] as String;
          capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
          return _stubGiftWrap();
        });

        // Act
        await invitationSendingService.sendInvitationAcceptanceEvent(
          inviteCode: inviteCode,
          vaultId: 'vault-roundtrip-test',
          ownerPubkey: ownerPubkey,
          relayUrls: ['ws://localhost:10547'],
        );

        // Assert: Content is empty (no JSON), tags carry all data
        expect(capturedContent, isEmpty);
        expect(capturedTags, isNotNull);
        expect(
          capturedTags!.any((t) => t[0] == 'invite_code' && t[1] == inviteCode),
          true,
        );
        expect(
          capturedTags!.any((t) => t[0] == 'vault_id' && t[1] == 'vault-roundtrip-test'),
          true,
        );
      },
    );
  });
}
