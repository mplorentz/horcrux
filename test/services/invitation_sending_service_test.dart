import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/ndk.dart';

import 'package:horcrux/models/nostr_kinds.dart';
import 'package:horcrux/services/invitation_sending_service.dart';
import 'package:horcrux/services/ndk_service.dart';

import 'invitation_sending_service_test.mocks.dart';

/// Synthesizes a minimal signed gift wrap event for stubs that only care
/// that [NdkService.publishEncryptedEvent] "succeeded".
Nip01Event _stubGiftWrap() => Nip01Event(
      kind: NostrKind.giftWrap.value,
      pubKey: 'a' * 64,
      tags: const [],
      createdAt: 1,
      content: '',
    );

/// Helper: check if tag list contains a tag [key, value].
bool _hasTag(List<List<String>> tags, String key, String value) =>
    tags.any((t) => t.length >= 2 && t[0] == key && t[1] == value);

@GenerateMocks([
  NdkService,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InvitationSendingService Event Format Tests', () {
    late MockNdkService mockNdkService;
    late InvitationSendingService service;

    setUp(() {
      mockNdkService = MockNdkService();
      service = InvitationSendingService(mockNdkService);

      // Default stub: publish succeeds
      when(mockNdkService.getCurrentPubkey()).thenAnswer(
          (_) async => 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb');
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: anyNamed('kind'),
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((_) async => _stubGiftWrap());
    });

    // ── sendInvitationAcceptanceEvent (kind 1340) ──

    test('sendInvitationAcceptanceEvent sends empty content and correct tags', () async {
      String capturedContent = '';
      List<List<String>> capturedTags = [];
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.invitationAcceptance.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
        return _stubGiftWrap();
      });

      await service.sendInvitationAcceptanceEvent(
        inviteCode: 'invite-123',
        vaultId: 'vault-abc',
        ownerPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
      );

      expect(capturedContent, isEmpty);
      expect(_hasTag(capturedTags, 'invite_code', 'invite-123'), isTrue);
      expect(_hasTag(capturedTags, 'vault_id', 'vault-abc'), isTrue);
    });

    // ── sendDenialEvent (kind 1341) ──

    test('sendDenialEvent sends empty content and correct tags', () async {
      String capturedContent = '';
      List<List<String>> capturedTags = [];
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.invitationDenial.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
        return _stubGiftWrap();
      });

      await service.sendDenialEvent(
        inviteCode: 'invite-123',
        ownerPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
      );

      expect(capturedContent, isEmpty);
      expect(_hasTag(capturedTags, 'invite_code', 'invite-123'), isTrue);
    });

    // ── sendShareConfirmationEvent (kind 1342) ──

    test('sendShareConfirmationEvent sends empty content and correct tags', () async {
      String capturedContent = '';
      List<List<String>> capturedTags = [];
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.shareConfirmation.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
        return _stubGiftWrap();
      });

      await service.sendShareConfirmationEvent(
        vaultId: 'vault-abc',
        shareIndex: 2,
        ownerPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
      );

      expect(capturedContent, isEmpty);
      expect(_hasTag(capturedTags, 'vault_id', 'vault-abc'), isTrue);
      expect(_hasTag(capturedTags, 'share_index', '2'), isTrue);
    });

    test('sendShareConfirmationEvent includes distribution_version tag when provided', () async {
      List<List<String>> capturedTags = [];
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.shareConfirmation.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
        return _stubGiftWrap();
      });

      await service.sendShareConfirmationEvent(
        vaultId: 'vault-abc',
        shareIndex: 2,
        ownerPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
        distributionVersion: 5,
      );

      expect(_hasTag(capturedTags, 'distribution_version', '5'), isTrue);
    });

    // ── sendShareErrorEvent (kind 1343) ──

    test('sendShareErrorEvent sends empty content and correct tags', () async {
      String capturedContent = '';
      List<List<String>> capturedTags = [];
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.shareError.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
        return _stubGiftWrap();
      });

      await service.sendShareErrorEvent(
        vaultId: 'vault-abc',
        shareIndex: 2,
        ownerPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
        error: 'Decryption failed',
      );

      expect(capturedContent, isEmpty);
      expect(_hasTag(capturedTags, 'vault_id', 'vault-abc'), isTrue);
      expect(_hasTag(capturedTags, 'error', 'Decryption failed'), isTrue);
    });

    // ── sendInvitationInvalidEvent (kind 1344) ──

    test('sendInvitationInvalidEvent sends empty content and correct tags', () async {
      String capturedContent = '';
      List<List<String>> capturedTags = [];
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.invitationInvalid.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
        return _stubGiftWrap();
      });

      await service.sendInvitationInvalidEvent(
        inviteCode: 'invite-123',
        inviteePubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
        reason: 'Steward removed',
      );

      expect(capturedContent, isEmpty);
      expect(_hasTag(capturedTags, 'invite_code', 'invite-123'), isTrue);
      expect(_hasTag(capturedTags, 'reason', 'Steward removed'), isTrue);
    });

    // ── sendKeyHolderRemovalEvent (kind 1345) ──

    test('sendKeyHolderRemovalEvent sends empty content and correct tags', () async {
      String capturedContent = '';
      List<List<String>> capturedTags = [];
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.keyHolderRemoved.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
        return _stubGiftWrap();
      });

      await service.sendKeyHolderRemovalEvent(
        vaultId: 'vault-abc',
        removedStewardPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
      );

      expect(capturedContent, isEmpty);
      expect(_hasTag(capturedTags, 'vault_id', 'vault-abc'), isTrue);
    });
  });
}
