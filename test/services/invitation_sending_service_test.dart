import 'dart:convert';

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
      service = InvitationSendingService(
        ndkService: mockNdkService,
      );

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

    test('sendInvitationAcceptanceEvent JSON payload has snake_case wire keys', () async {
      String capturedContent = '';
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.invitationAcceptance.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        return _stubGiftWrap();
      });

      await service.sendInvitationAcceptanceEvent(
        inviteCode: 'invite-123',
        vaultId: 'vault-abc',
        ownerPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
      );

      final payload = json.decode(capturedContent) as Map<String, dynamic>;
      expect(payload, containsPair('invite_code', 'invite-123'));
      expect(payload, containsPair('vault_id', 'vault-abc'));
      expect(payload, containsPair('invitee_pubkey', isNotEmpty));
      expect(payload, containsPair('responded_at', isNotEmpty));
    });

    test('sendInvitationAcceptanceEvent passes correct tags', () async {
      List<List<String>> capturedTags = [];
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.invitationAcceptance.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedTags = invocation.namedArguments[#tags] as List<List<String>>;
        return _stubGiftWrap();
      });

      await service.sendInvitationAcceptanceEvent(
        inviteCode: 'invite-123',
        vaultId: 'vault-abc',
        ownerPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
      );

      expect(capturedTags, contains(['d', 'invitation_acceptance_invite-123']));
      expect(capturedTags, contains(['invite', 'invite-123']));
    });

    test('sendInvitationAcceptanceEvent returns null when no key pair', () async {
      when(mockNdkService.getCurrentPubkey()).thenAnswer((_) async => null);

      final result = await service.sendInvitationAcceptanceEvent(
        inviteCode: 'invite-123',
        vaultId: 'vault-abc',
        ownerPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
      );

      expect(result, isNull);
    });

    // ── sendDenialEvent (kind 1341) ──

    test('sendDenialEvent JSON payload has snake_case wire keys', () async {
      String capturedContent = '';
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.invitationDenial.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        return _stubGiftWrap();
      });

      await service.sendDenialEvent(
        inviteCode: 'invite-123',
        ownerPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
      );

      final payload = json.decode(capturedContent) as Map<String, dynamic>;
      expect(payload, containsPair('invite_code', 'invite-123'));
      expect(payload, containsPair('invitee_pubkey', isNotEmpty));
      expect(payload, containsPair('responded_at', isNotEmpty));
    });

    test('sendDenialEvent includes reason when provided', () async {
      String capturedContent = '';
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.invitationDenial.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        return _stubGiftWrap();
      });

      await service.sendDenialEvent(
        inviteCode: 'invite-123',
        ownerPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
        reason: 'Not interested',
      );

      final payload = json.decode(capturedContent) as Map<String, dynamic>;
      expect(payload, containsPair('reason', 'Not interested'));
    });

    test('sendDenialEvent omits reason when null or empty', () async {
      String capturedContent = '';
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: NostrKind.invitationDenial.value,
        recipientPubkey: anyNamed('recipientPubkey'),
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((invocation) async {
        capturedContent = invocation.namedArguments[#content] as String;
        return _stubGiftWrap();
      });

      await service.sendDenialEvent(
        inviteCode: 'invite-123',
        ownerPubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        relayUrls: ['wss://relay.example.com'],
      );

      final payload = json.decode(capturedContent) as Map<String, dynamic>;
      expect(payload, isNot(contains('reason')));
    });

    // ── sendShareConfirmationEvent (kind 1342) ──

    test('sendShareConfirmationEvent JSON payload has snake_case wire keys', () async {
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

      // Empty content — all data in tags
      expect(capturedContent, isEmpty);
      expect(capturedTags, contains(['vault_id', 'vault-abc']));
      expect(capturedTags, contains(['share_index', '2']));
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

      expect(capturedTags, contains(['distribution_version', '5']));
    });

    // ── sendShareErrorEvent (kind 1343) ──

    test('sendShareErrorEvent JSON payload has snake_case wire keys', () async {
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

      // Empty content — all data in tags
      expect(capturedContent, isEmpty);
      expect(capturedTags, contains(['vault_id', 'vault-abc']));
      expect(capturedTags, contains(['d', 'share_error_vault-abc_2']));
      expect(capturedTags, contains(['error', 'Decryption failed']));
    });

    // ── sendInvitationInvalidEvent (kind 1344) ──

    test('sendInvitationInvalidEvent JSON payload has snake_case wire keys', () async {
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

      // Empty content — all data in tags
      expect(capturedContent, isEmpty);
      expect(capturedTags, contains(['invite_code', 'invite-123']));
      expect(capturedTags, contains(['reason', 'Steward removed']));
    });

    // ── sendKeyHolderRemovalEvent (kind 1345) ──

    test('sendKeyHolderRemovalEvent JSON payload has snake_case wire keys', () async {
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

      // Empty content — all data in tags
      expect(capturedContent, isEmpty);
      expect(capturedTags, contains(['vault_id', 'vault-abc']));
    });
  });
}
