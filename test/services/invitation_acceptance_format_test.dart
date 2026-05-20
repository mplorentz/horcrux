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

String? _tagValue(List<List<String>> tags, String name) {
  for (final tag in tags) {
    if (tag.length >= 2 && tag[0] == name) {
      return tag[1];
    }
  }
  return null;
}

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

    // Full send→process roundtrip needs inbound tag parsing (PR #207 / horcrux_app-6fc5).
    test(
      'sendInvitationAcceptanceEvent publishes canonical tags for inbound processor',
      skip: 'Requires horcrux_app-6fc5 inbound (PR #207) for processInvitationAcceptanceEvent',
      () async {
        // Arrange
        const inviteCode = 'test-invite-code-123';
        const ownerPubkey = TestHexPubkeys.alice;
        const inviteePubkey = TestHexPubkeys.bob;
        final relayUrls = ['ws://localhost:10547'];

        // Capture publish args (empty content, data in tags)
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

        expect(capturedContent, '');
        expect(capturedTags, isNotNull);
        expect(_tagValue(capturedTags!, 'invite_code'), inviteCode);
        expect(_tagValue(capturedTags!, 'vault_id'), 'test-vault-id');

        // Mock event as NDK would deliver after unwrapping
        final mockEvent = Nip01Event(
          kind: NostrKind.invitationAcceptance.value,
          pubKey: inviteePubkey,
          tags: capturedTags!,
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

        // Act: Call processInvitationAcceptanceEvent with the JSON created by sendInvitationAcceptanceEvent
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
      'processInvitationAcceptanceEvent throws ArgumentError for missing inviteCode',
      () async {
        // Arrange
        const ownerPubkey = TestHexPubkeys.alice;
        const inviteePubkey = TestHexPubkeys.bob;

        // Create event with missing invite_code
        final invalidJson = json.encode({
          'invitee_pubkey': inviteePubkey,
          'responded_at': DateTime.now().toIso8601String(),
        });

        final mockEvent = Nip01Event(
          kind: NostrKind.invitationAcceptance.value,
          pubKey: inviteePubkey,
          tags: [],
          createdAt: secondsSinceEpoch(),
          content: invalidJson,
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

      // Create event with invalid pubkey (wrong length)
      final invalidJson = json.encode({
        'invite_code': inviteCode,
        'invitee_pubkey': 'short', // Should be 64 chars
        'responded_at': DateTime.now().toIso8601String(),
      });

      final mockEvent = Nip01Event(
        kind: NostrKind.invitationAcceptance.value,
        pubKey: 'short',
        tags: [],
        createdAt: secondsSinceEpoch(),
        content: invalidJson,
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
            contains('Invalid invitee_pubkey'),
          ),
        ),
      );
    });

    test('processInvitationAcceptanceEvent throws ArgumentError for pubkey mismatch', () async {
      // Arrange
      const ownerPubkey = TestHexPubkeys.alice;
      const inviteePubkey = TestHexPubkeys.bob;
      const differentPubkey = TestHexPubkeys.charlie;
      const inviteCode = 'test-invite-code';

      // Create event where payload pubkey doesn't match event pubkey
      final mismatchJson = json.encode({
        'invite_code': inviteCode,
        'invitee_pubkey': inviteePubkey,
        'responded_at': DateTime.now().toIso8601String(),
      });

      final mockEvent = Nip01Event(
        kind: NostrKind.invitationAcceptance.value,
        pubKey: differentPubkey, // Different from payload
        tags: [],
        createdAt: secondsSinceEpoch(),
        content: mismatchJson,
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
            contains('pubkey mismatch'),
          ),
        ),
      );
    });

    test('processInvitationAcceptanceEvent silently ignores unknown invitation', () async {
      // Arrange
      const ownerPubkey = TestHexPubkeys.alice;
      const inviteePubkey = TestHexPubkeys.bob;
      // Use a valid Base64URL invite code (no padding, Base64URL format)
      const inviteCode = 'dGVzdF9iYXNlNjRfY29kZQ'; // Base64URL without padding

      final validJson = json.encode({
        'invite_code': inviteCode,
        'invitee_pubkey': inviteePubkey,
        'responded_at': DateTime.now().toIso8601String(),
      });

      final mockEvent = Nip01Event(
        kind: NostrKind.invitationAcceptance.value,
        pubKey: inviteePubkey,
        tags: [],
        createdAt: secondsSinceEpoch(),
        content: validJson,
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

    test('sendInvitationAcceptanceEvent tag format matches expected structure', () async {
      // Arrange
      const inviteCode = 'test-code-xyz';
      const ownerPubkey = TestHexPubkeys.alice;
      final relayUrls = ['ws://localhost:10547'];

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

      // Assert: empty content, invite_code and vault_id in tags
      expect(capturedContent, '');
      expect(capturedTags, isNotNull);
      expect(_tagValue(capturedTags!, 'invite_code'), inviteCode);
      expect(_tagValue(capturedTags!, 'vault_id'), 'vault-for-structure-test');
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
        final relayUrls = ['ws://localhost:10547', 'wss://relay.example.com'];

        String? capturedContent;
        int? capturedKind;
        String? capturedRecipientPubkey;
        List<String>? capturedRelays;
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
          capturedKind = invocation.namedArguments[#kind] as int;
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
        expect(capturedContent, '');
        expect(capturedKind, NostrKind.invitationAcceptance.value);
        expect(capturedRecipientPubkey, ownerPubkey);
        expect(capturedRelays, relayUrls);
        expect(capturedTags, isNotNull);
        expect(capturedTags!.length, 2);
        expect(capturedTags![0], ['invite_code', inviteCode]);
        expect(capturedTags![1], ['vault_id', 'vault-param-test']);
      },
    );

    test('sendInvitationAcceptanceEvent creates tags with correct field names', () async {
      // Arrange
      const inviteCode = 'test-code-123';
      const ownerPubkey = TestHexPubkeys.alice;
      final relayUrls = ['ws://localhost:10547'];

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

      // Assert: empty content; invite_code and vault_id only in tags
      expect(capturedContent, '');
      expect(capturedTags, isNotNull);
      expect(_tagValue(capturedTags!, 'invite_code'), inviteCode);
      expect(_tagValue(capturedTags!, 'vault_id'), 'vault-field-names-test');
      expect(capturedTags!.length, 2);
    });

    test(
      'sendInvitationAcceptanceEvent handles publishEncryptedEvent errors gracefully',
      () async {
        // Arrange
        const inviteCode = 'test-code';
        const ownerPubkey = TestHexPubkeys.alice;
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

    test('sendInvitationAcceptanceEvent includes invite code in tags', () async {
      // Arrange
      const inviteCode = 'special-invite-code-xyz';
      const ownerPubkey = TestHexPubkeys.alice;

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

      // Assert: invite_code tag carries the code
      expect(capturedTags, isNotNull);
      expect(_tagValue(capturedTags!, 'invite_code'), inviteCode);
    });
  });
}
