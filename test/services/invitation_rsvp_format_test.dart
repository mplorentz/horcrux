import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/ndk.dart';

import 'package:horcrux/services/invitation_sending_service.dart';
import 'package:horcrux/services/invitation_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/relay_scan_service.dart';
import 'package:horcrux/providers/vault_provider.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/nostr_kinds.dart';
import '../fixtures/test_keys.dart';

import 'invitation_rsvp_format_test.mocks.dart';

@GenerateMocks([
  NdkService,
  LoginService,
  VaultRepository,
  InvitationSendingService,
  RelayScanService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel sharedPreferencesChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );
  final Map<String, dynamic> sharedPreferencesStore = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sharedPreferencesChannel, (call) async {
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
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sharedPreferencesChannel, null);
  });

  group('RSVP Event Format Compatibility Tests', () {
    late MockNdkService mockNdkService;
    late MockLoginService mockLoginService;
    late VaultRepository realRepository;
    late MockInvitationSendingService mockInvitationSendingService;
    late InvitationSendingService invitationSendingService;
    late InvitationService invitationService;

    setUp(() async {
      mockNdkService = MockNdkService();
      mockLoginService = MockLoginService();
      realRepository = VaultRepository(mockLoginService);
      mockInvitationSendingService = MockInvitationSendingService();

      invitationSendingService = InvitationSendingService(mockNdkService);
      final mockRelayScanService = MockRelayScanService();
      invitationService = InvitationService(
        realRepository,
        mockInvitationSendingService,
        mockLoginService,
        () => mockNdkService,
        mockRelayScanService,
      );

      // Clear SharedPreferences before each test
      sharedPreferencesStore.clear();
    });

    test(
      'sendRsvpEvent creates JSON that processRsvpEvent can parse',
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

        // Capture the content passed to publishEncryptedEvent
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
          capturedContent = invocation.namedArguments[#content] as String;
          return 'test-event-id';
        });

        // Act: Call sendRsvpEvent
        await invitationSendingService.sendRsvpEvent(
          inviteCode: inviteCode,
          ownerPubkey: ownerPubkey,
          relayUrls: relayUrls,
        );

        // Verify content was captured
        expect(capturedContent, isNotNull);
        final content = capturedContent!;

        // Parse the captured JSON to verify its structure
        final parsedJson = json.decode(content) as Map<String, dynamic>;
        expect(parsedJson['invite_code'], inviteCode);
        expect(parsedJson['invitee_pubkey'], inviteePubkey);
        expect(parsedJson['responded_at'], isA<String>());

        // Now create a mock event with this content (simulating NDK unwrapping)
        final mockEvent = Nip01Event(
          kind: NostrKind.invitationRsvp.value,
          pubKey: inviteePubkey,
          content: content, // Already decrypted JSON from NDK
          tags: [],
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
          content: 'test content',
          createdAt: DateTime.now(),
          ownerPubkey: ownerPubkey,
        );
        await realRepository.addVault(testVault);

        // Act: Call processRsvpEvent with the JSON created by sendRsvpEvent
        await invitationService.processRsvpEvent(event: mockEvent);

        // Verify it succeeded (no exception thrown)
        // The invitation should now be marked as redeemed
        final redeemedInvitation = await invitationService.lookupInvitationByCode(inviteCode);
        expect(redeemedInvitation, isNotNull);
        expect(redeemedInvitation!.status.name, 'redeemed');
        expect(redeemedInvitation.redeemedBy, inviteePubkey);
      },
    );

    test(
      'processRsvpEvent throws ArgumentError for missing inviteCode',
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
          kind: NostrKind.invitationRsvp.value,
          pubKey: inviteePubkey,
          content: invalidJson,
          tags: [],
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );

        when(
          mockLoginService.getCurrentPublicKey(),
        ).thenAnswer((_) async => ownerPubkey);

        // Act & Assert
        expect(
          () => invitationService.processRsvpEvent(event: mockEvent),
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

    test('processRsvpEvent throws ArgumentError for invalid pubkey', () async {
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
        kind: NostrKind.invitationRsvp.value,
        pubKey: 'short',
        content: invalidJson,
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      when(
        mockLoginService.getCurrentPublicKey(),
      ).thenAnswer((_) async => ownerPubkey);

      // Act & Assert
      expect(
        () => invitationService.processRsvpEvent(event: mockEvent),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'toString',
            contains('Invalid invitee_pubkey'),
          ),
        ),
      );
    });

    test('processRsvpEvent throws ArgumentError for pubkey mismatch', () async {
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
        kind: NostrKind.invitationRsvp.value,
        pubKey: differentPubkey, // Different from payload
        content: mismatchJson,
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      when(
        mockLoginService.getCurrentPublicKey(),
      ).thenAnswer((_) async => ownerPubkey);

      // Act & Assert
      expect(
        () => invitationService.processRsvpEvent(event: mockEvent),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'toString',
            contains('pubkey mismatch'),
          ),
        ),
      );
    });

    test('processRsvpEvent silently ignores unknown invitation', () async {
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
        kind: NostrKind.invitationRsvp.value,
        pubKey: inviteePubkey,
        content: validJson,
        tags: [],
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );

      when(
        mockLoginService.getCurrentPublicKey(),
      ).thenAnswer((_) async => ownerPubkey);

      // Act: Should not throw, just silently ignore
      await invitationService.processRsvpEvent(event: mockEvent);

      // Verify invitation doesn't exist
      final invitation = await invitationService.lookupInvitationByCode(
        inviteCode,
      );
      expect(invitation, isNull);
    });

    test('sendRsvpEvent JSON format matches expected structure', () async {
      // Arrange
      const inviteCode = 'test-code-xyz';
      const ownerPubkey = TestHexPubkeys.alice;
      const inviteePubkey = TestHexPubkeys.bob;
      final relayUrls = ['ws://localhost:10547'];

      when(
        mockNdkService.getCurrentPubkey(),
      ).thenAnswer((_) async => inviteePubkey);

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
        capturedContent = invocation.namedArguments[#content] as String;
        return 'test-event-id';
      });

      // Act
      await invitationSendingService.sendRsvpEvent(
        inviteCode: inviteCode,
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
      );

      // Assert: Verify JSON structure
      expect(capturedContent, isNotNull);
      final content = capturedContent!;
      final parsed = json.decode(content) as Map<String, dynamic>;
      expect(parsed['invite_code'], isA<String>());
      expect(parsed['invitee_pubkey'], isA<String>());
      expect(parsed['responded_at'], isA<String>());
      expect((parsed['invitee_pubkey'] as String).length, 64);

      // Verify values match
      expect(parsed['invite_code'], inviteCode);
      expect(parsed['invitee_pubkey'], inviteePubkey);
    });
  });

  group('sendRsvpEvent Unit Tests', () {
    late MockNdkService mockNdkService;
    late InvitationSendingService invitationSendingService;

    setUp(() {
      mockNdkService = MockNdkService();
      invitationSendingService = InvitationSendingService(mockNdkService);
    });

    test(
      'sendRsvpEvent calls publishEncryptedEvent with correct parameters',
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
          capturedRecipientPubkey = invocation.namedArguments[#recipientPubkey] as String;
          capturedRelays = invocation.namedArguments[#relays] as List<String>;
          capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
          return 'test-event-id-123';
        });

        // Act
        final result = await invitationSendingService.sendRsvpEvent(
          inviteCode: inviteCode,
          ownerPubkey: ownerPubkey,
          relayUrls: relayUrls,
        );

        // Assert
        expect(result, 'test-event-id-123');
        expect(capturedKind, NostrKind.invitationRsvp.value);
        expect(capturedRecipientPubkey, ownerPubkey);
        expect(capturedRelays, relayUrls);
        expect(capturedTags, isNotNull);
        // Note: expiration tag is added inside publishEncryptedEvent, so we verify
        // the custom tags passed to it (expiration will be prepended internally)
        expect(capturedTags!.length, 2);
        expect(capturedTags![0], ['d', 'invitation_rsvp_$inviteCode']);
        expect(capturedTags![1], ['invite', inviteCode]);
      },
    );

    test('sendRsvpEvent creates payload with correct field names', () async {
      // Arrange
      const inviteCode = 'test-code-123';
      const ownerPubkey = TestHexPubkeys.alice;
      const inviteePubkey = TestHexPubkeys.bob;
      final relayUrls = ['ws://localhost:10547'];

      when(
        mockNdkService.getCurrentPubkey(),
      ).thenAnswer((_) async => inviteePubkey);

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
        capturedContent = invocation.namedArguments[#content] as String;
        return 'test-event-id';
      });

      // Act
      await invitationSendingService.sendRsvpEvent(
        inviteCode: inviteCode,
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
      );

      // Assert: Verify payload structure
      expect(capturedContent, isNotNull);
      final payload = json.decode(capturedContent!) as Map<String, dynamic>;

      // Verify all required fields exist with correct names
      expect(
        payload.containsKey('invite_code'),
        true,
        reason: 'Payload must contain invite_code field',
      );
      expect(
        payload.containsKey('invitee_pubkey'),
        true,
        reason: 'Payload must contain invitee_pubkey field',
      );
      expect(
        payload.containsKey('responded_at'),
        true,
        reason: 'Payload must contain responded_at field',
      );

      // Verify field values
      expect(payload['invite_code'], inviteCode);
      expect(payload['invitee_pubkey'], inviteePubkey);
      expect(payload['responded_at'], isA<String>());

      // Verify no extra fields that might confuse parsing
      expect(
        payload.keys.length,
        3,
        reason: 'Payload should only have 3 fields: invite_code, invitee_pubkey, responded_at',
      );
    });

    test('sendRsvpEvent returns null when getCurrentPubkey fails', () async {
      // Arrange
      when(mockNdkService.getCurrentPubkey()).thenAnswer((_) async => null);

      // Act
      final result = await invitationSendingService.sendRsvpEvent(
        inviteCode: 'test-code',
        ownerPubkey: TestHexPubkeys.alice,
        relayUrls: ['ws://localhost:10547'],
      );

      // Assert
      expect(result, isNull);
      verifyNever(
        mockNdkService.publishEncryptedEvent(
          content: anyNamed('content'),
          kind: anyNamed('kind'),
          recipientPubkey: anyNamed('recipientPubkey'),
          relays: anyNamed('relays'),
          tags: anyNamed('tags'),
        ),
      );
    });

    test(
      'sendRsvpEvent handles publishEncryptedEvent errors gracefully',
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
        final result = await invitationSendingService.sendRsvpEvent(
          inviteCode: inviteCode,
          ownerPubkey: ownerPubkey,
          relayUrls: ['ws://localhost:10547'],
        );

        // Assert: Should return null on error, not throw
        expect(result, isNull);
      },
    );

    test('sendRsvpEvent includes invite code in tags', () async {
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
        return 'test-event-id';
      });

      // Act
      await invitationSendingService.sendRsvpEvent(
        inviteCode: inviteCode,
        ownerPubkey: ownerPubkey,
        relayUrls: ['ws://localhost:10547'],
      );

      // Assert: Verify invite code is in tags
      expect(capturedTags, isNotNull);
      final inviteTag = capturedTags!.firstWhere(
        (tag) => tag.isNotEmpty && tag[0] == 'invite',
        orElse: () => [],
      );
      expect(inviteTag.isNotEmpty, true);
      expect(inviteTag[1], inviteCode);
    });

    test(
      'sendRsvpEvent JSON payload can be roundtrip encoded/decoded',
      () async {
        // Arrange
        const inviteCode = 'roundtrip-test-code';
        const ownerPubkey = TestHexPubkeys.alice;
        const inviteePubkey = TestHexPubkeys.bob;

        when(
          mockNdkService.getCurrentPubkey(),
        ).thenAnswer((_) async => inviteePubkey);

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
          capturedContent = invocation.namedArguments[#content] as String;
          return 'test-event-id';
        });

        // Act
        await invitationSendingService.sendRsvpEvent(
          inviteCode: inviteCode,
          ownerPubkey: ownerPubkey,
          relayUrls: ['ws://localhost:10547'],
        );

        // Assert: Verify JSON roundtrip
        expect(capturedContent, isNotNull);
        final payload1 = json.decode(capturedContent!) as Map<String, dynamic>;
        final encoded = json.encode(payload1);
        final payload2 = json.decode(encoded) as Map<String, dynamic>;

        // Verify roundtrip preserves data
        expect(payload2['invite_code'], payload1['invite_code']);
        expect(payload2['invitee_pubkey'], payload1['invitee_pubkey']);
        expect(payload2['responded_at'], payload1['responded_at']);
      },
    );
  });
}
