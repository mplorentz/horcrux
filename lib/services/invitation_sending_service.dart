import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database_provider.dart';
import '../services/ndk_service.dart';
import '../services/logger.dart';
import '../models/nostr_kinds.dart';

/// Provider for InvitationSendingService.
///
/// Uses [ref.read] for [ndkServiceProvider] to break the circular dependency:
///   ndk → invitationService → invitationSendingService → ndk.
/// [appDatabaseProvider] is watched so that a logout (which invalidates the
/// database) cascades and rebuilds this provider with a fresh NdkService.
final invitationSendingServiceProvider = Provider<InvitationSendingService>((
  ref,
) {
  ref.watch(appDatabaseProvider); // keep logout-invalidation cascade
  return InvitationSendingService(ref.read(ndkServiceProvider));
});

/// Stateless utility service for creating and publishing outgoing invitation-related Nostr events
///
/// This service handles only outgoing event creation and publishing, with no local state or storage.
/// All methods are pure functions that create and publish events.
class InvitationSendingService {
  final NdkService ndkService;

  InvitationSendingService(this.ndkService);

  /// Creates and publishes invitation acceptance event to accept invitation
  ///
  /// Creates invitation acceptance event payload.
  /// Encrypts using NIP-44.
  /// Creates Nostr event (kind 1340).
  /// Signs with invitee's private key.
  /// Publishes to relays.
  /// Returns event ID, or null if publishing fails.
  Future<String?> sendInvitationAcceptanceEvent({
    required String inviteCode,
    required String vaultId,
    required String ownerPubkey, // Hex format
    required List<String> relayUrls,
  }) async {
    try {
      Log.info(
        'Sending invitation acceptance event for invite code: ${inviteCode.substring(0, 8)}...',
      );

      // Publish with empty content, data in tags
      final event = await ndkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.invitationAcceptance.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['d', 'invitation_acceptance_$inviteCode'],
          ['invite_code', inviteCode],
          ['vault_id', vaultId],
        ],
      );
      return event?.id;
    } catch (e) {
      Log.error('Error sending invitation acceptance event', e);
      return null;
    }
  }

  /// Creates and publishes denial event to decline invitation
  ///
  /// Creates denial event with empty content, data in tags.
  /// Creates Nostr event (kind 1341).
  /// Signs with invitee's private key.
  /// Publishes to relays.
  /// Returns event ID, or null if publishing fails.
  Future<String?> sendDenialEvent({
    required String inviteCode,
    required String ownerPubkey, // Hex format
    required List<String> relayUrls,
    String? reason,
  }) async {
    try {
      Log.info(
        'Sending denial event for invite code: ${inviteCode.substring(0, 8)}...',
      );

      // Build tags
      final tags = <List<String>>[
        ['d', 'invitation_denial_$inviteCode'],
        ['invite_code', inviteCode],
      ];

      // Include reason in tags if provided
      if (reason != null && reason.isNotEmpty) {
        tags.add(['reason', reason]);
      }

      // Publish with empty content, data in tags
      final event = await ndkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.invitationDenial.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: tags,
      );
      return event?.id;
    } catch (e) {
      Log.error('Error sending denial event', e);
      return null;
    }
  }

  /// Creates and publishes shard confirmation event
  ///
  /// Creates confirmation event payload.
  /// Encrypts using NIP-44.
  /// Creates Nostr event (kind 1342).
  /// Signs with steward's private key.
  /// Publishes to relays.
  /// Returns event ID, or null if publishing fails.
  Future<String?> sendShareConfirmationEvent({
    required String vaultId,
    required int shareIndex,
    required String ownerPubkey, // Hex format
    required List<String> relayUrls,
    int? distributionVersion,
  }) async {
    try {
      Log.info(
        'Sending share confirmation event for vault: ${vaultId.substring(0, 8)}..., share: $shareIndex',
      );

      // Publish with empty content, data in tags
      final tags = [
        ['d', 'share_confirmation_${vaultId}_$shareIndex'],
        ['vault_id', vaultId],
        ['share_index', shareIndex.toString()],
      ];

      // Include distribution version if provided
      if (distributionVersion != null) {
        tags.add(['distribution_version', distributionVersion.toString()]);
      }

      final event = await ndkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.shareConfirmation.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: tags,
      );
      return event?.id;
    } catch (e) {
      Log.error('Error sending share confirmation event', e);
      return null;
    }
  }

  /// Creates and publishes share error event
  ///
  /// Creates error event with empty content, data in tags.
  /// Creates Nostr event (kind 1343).
  /// Signs with steward's private key.
  /// Publishes to relays.
  /// Returns event ID, or null if publishing fails.
  Future<String?> sendShareErrorEvent({
    required String vaultId,
    required int shareIndex,
    required String ownerPubkey, // Hex format
    required List<String> relayUrls,
    required String error,
  }) async {
    try {
      Log.warning(
        'Sending share error event for vault: ${vaultId.substring(0, 8)}..., share: $shareIndex',
      );

      // Publish with empty content, data in tags
      final event = await ndkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.shareError.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: [
          ['d', 'share_error_${vaultId}_$shareIndex'],
          ['vault_id', vaultId],
          ['error', error],
        ],
      );
      return event?.id;
    } catch (e) {
      Log.error('Error sending share error event', e);
      return null;
    }
  }

  /// Creates and publishes invitation invalid event
  ///
  /// Creates invalid event payload.
  /// Encrypts using NIP-44.
  /// Creates Nostr event (kind 1344).
  /// Signs with vault owner's private key.
  /// Publishes to relays.
  /// Returns event ID, or null if publishing fails.
  Future<String?> sendInvitationInvalidEvent({
    required String inviteCode,
    required String inviteePubkey, // Hex format
    required List<String> relayUrls,
    required String reason,
  }) async {
    try {
      Log.warning(
        'Sending invitation invalid event for invite code: ${inviteCode.substring(0, 8)}...',
      );

      // Publish using NdkService with empty content, data in tags
      final event = await ndkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.invitationInvalid.value,
        recipientPubkey: inviteePubkey,
        relays: relayUrls,
        tags: [
          ['invite_code', inviteCode],
          ['reason', reason],
        ],
      );
      return event?.id;
    } catch (e) {
      Log.error('Error sending invitation invalid event', e);
      return null;
    }
  }

  /// Creates and publishes steward removed event
  ///
  /// Creates removal event with empty content, data in tags.
  /// Creates Nostr event (kind 1345).
  /// Signs with vault owner's private key.
  /// Publishes to relays.
  /// Returns event ID, or null if publishing fails.
  Future<String?> sendKeyHolderRemovalEvent({
    required String vaultId,
    required String removedStewardPubkey, // Hex format
    required List<String> relayUrls,
  }) async {
    try {
      Log.warning(
        'Sending steward removal event for vault: ${vaultId.substring(0, 8)}..., removed: ${removedStewardPubkey.substring(0, 8)}...',
      );

      // Publish using NdkService with empty content, data in tags
      final event = await ndkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.keyHolderRemoved.value,
        recipientPubkey: removedStewardPubkey,
        relays: relayUrls,
        tags: [
          ['vault_id', vaultId],
        ],
      );
      return event?.id;
    } catch (e) {
      Log.error('Error sending steward removal event', e);
      return null;
    }
  }
}
