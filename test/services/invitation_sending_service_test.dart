import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ndk/ndk.dart';

import 'package:horcrux/services/invitation_sending_service.dart';
import 'package:horcrux/services/ndk_service.dart';
import 'package:horcrux/services/login_service.dart';
import 'package:horcrux/models/nostr_kinds.dart';

import 'invitation_sending_service_test.mocks.dart';

/// Returns a minimal signed gift wrap event the stub can return.
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
])
void main() {
  late MockNdkService mockNdkService;
  late MockLoginService mockLoginService;
  late InvitationSendingService service;
  const ownerPubkey = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const inviteCode = 'test-invite-123';
  const vaultId = 'test-vault-456';
  const shareIndex = 2;
  const errorMsg = 'Decryption failed';
  const relayUrls = ['wss://relay.example.com'];
  const reason = 'Changed mind';

  setUp(() {
    mockNdkService = MockNdkService();
    mockLoginService = MockLoginService();
    service = InvitationSendingService(mockNdkService);

    when(mockNdkService.publishEncryptedEvent(
      content: anyNamed('content'),
      kind: anyNamed('kind'),
      recipientPubkey: ownerPubkey,
      relays: anyNamed('relays'),
      tags: anyNamed('tags'),
    )).thenAnswer((_) async => _stubGiftWrap());
  });

  group('sendInvitationAcceptanceEvent', () {
    test('uses empty content and correct tags', () async {
      await service.sendInvitationAcceptanceEvent(
        inviteCode: inviteCode,
        vaultId: vaultId,
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
      );

      verify(mockNdkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.invitationAcceptance.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['d', 'invitation_acceptance_$inviteCode'],
          ['invite_code', inviteCode],
          ['vault_id', vaultId],
        ],
      )).called(1);
    });

    test('returns null when ndkService returns null', () async {
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: anyNamed('kind'),
        recipientPubkey: ownerPubkey,
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((_) async => null);

      final result = await service.sendInvitationAcceptanceEvent(
        inviteCode: inviteCode,
        vaultId: vaultId,
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
      );

      expect(result, isNull);
    });
  });

  group('sendDenialEvent', () {
    test('uses empty content and correct tags with reason', () async {
      await service.sendDenialEvent(
        inviteCode: inviteCode,
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
        reason: reason,
      );

      verify(mockNdkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.invitationDenial.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['d', 'invitation_denial_$inviteCode'],
          ['invite_code', inviteCode],
          ['reason', reason],
        ],
      )).called(1);
    });

    test('omits reason tag when null', () async {
      await service.sendDenialEvent(
        inviteCode: inviteCode,
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
      );

      verify(mockNdkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.invitationDenial.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['d', 'invitation_denial_$inviteCode'],
          ['invite_code', inviteCode],
        ],
      )).called(1);
    });
  });

  group('sendShareConfirmationEvent', () {
    test('uses empty content and correct tags', () async {
      await service.sendShareConfirmationEvent(
        vaultId: vaultId,
        shareIndex: shareIndex,
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
        distributionVersion: 3,
      );

      verify(mockNdkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.shareConfirmation.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['d', 'share_confirmation_${vaultId}_$shareIndex'],
          ['vault_id', vaultId],
          ['share_index', shareIndex.toString()],
          ['distribution_version', '3'],
        ],
      )).called(1);
    });

    test('returns null when ndkService returns null', () async {
      when(mockNdkService.publishEncryptedEvent(
        content: anyNamed('content'),
        kind: anyNamed('kind'),
        recipientPubkey: ownerPubkey,
        relays: anyNamed('relays'),
        tags: anyNamed('tags'),
      )).thenAnswer((_) async => null);

      final result = await service.sendShareConfirmationEvent(
        vaultId: vaultId,
        shareIndex: shareIndex,
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
      );

      expect(result, isNull);
    });
  });

  group('sendShareErrorEvent', () {
    test('uses empty content and correct tags', () async {
      await service.sendShareErrorEvent(
        vaultId: vaultId,
        shareIndex: shareIndex,
        ownerPubkey: ownerPubkey,
        relayUrls: relayUrls,
        error: errorMsg,
      );

      verify(mockNdkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.shareError.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['d', 'share_error_${vaultId}_$shareIndex'],
          ['vault_id', vaultId],
          ['error', errorMsg],
        ],
      )).called(1);
    });
  });

  group('sendInvitationInvalidEvent', () {
    test('uses empty content and correct tags', () async {
      await service.sendInvitationInvalidEvent(
        inviteCode: inviteCode,
        inviteePubkey: ownerPubkey,
        relayUrls: relayUrls,
        reason: reason,
      );

      verify(mockNdkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.invitationInvalid.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['invite_code', inviteCode],
          ['reason', reason],
        ],
      )).called(1);
    });
  });

  group('sendKeyHolderRemovalEvent', () {
    test('uses empty content and correct tags', () async {
      await service.sendKeyHolderRemovalEvent(
        vaultId: vaultId,
        removedStewardPubkey: ownerPubkey,
        relayUrls: relayUrls,
      );

      verify(mockNdkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.keyHolderRemoved.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['vault_id', vaultId],
        ],
      )).called(1);
    });
  });
}
