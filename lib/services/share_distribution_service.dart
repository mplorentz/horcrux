import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import '../models/backup_config.dart';
import '../models/nostr_kinds.dart';
import '../models/share_event.dart';
import '../models/share.dart';
import '../models/steward_status.dart';
import '../models/event_status.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import '../utils/date_time_extensions.dart';
import 'horcrux_notification_service.dart';
import 'login_service.dart';
import 'ndk_service.dart';
import 'logger.dart';

/// Provider for [ShareDistributionService]
final Provider<ShareDistributionService> shareDistributionServiceProvider =
    Provider<ShareDistributionService>((ref) {
  // Watching repository and notification providers ensures that invalidating
  // [appDatabaseProvider] (logout) cascades through and rebuilds this service
  // against the fresh database.
  //
  // Use ref.read() for NdkService to break circular dependency: NdkService
  // calls _ref.read(shareDistributionServiceProvider) from _handleShareConfirmation;
  // watching ndk here would throw CircularDependencyError during that read.
  return ShareDistributionService(
    ref.watch(vaultRepositoryProvider),
    ref.watch(loginServiceProvider),
    ref.read(ndkServiceProvider),
    ref.watch(horcruxNotificationServiceProvider),
  );
});

/// Service for distributing Shamir shares to stewards via Nostr
class ShareDistributionService {
  final VaultRepository _repository;
  final LoginService _loginService;
  final NdkService _ndkService;
  final HorcruxNotificationService _notificationService;

  ShareDistributionService(
    this._repository,
    this._loginService,
    this._ndkService,
    this._notificationService,
  );

  /// Publishes encrypted share events for each steward in [config] who has a
  /// pubkey, using [shares] entries aligned by roster index with those stewards.
  ///
  /// [ownerPubkey] (hex) is passed to [NdkService.publishEncryptedEvent] as
  /// `customPubkey` so the vault owner signs each rumor.
  ///
  /// If the roster has no entry that is both `isOwner` and keyed by
  /// [ownerPubkey], this also publishes one extra manifest-only share event
  /// (empty payload, sentinel `shareIndex` -1) to [ownerPubkey] so the owner
  /// can rehydrate recovery metadata without holding a steward slot.
  Future<List<ShareEvent>> distributeShares({
    required String ownerPubkey, // Hex format - vault owner's pubkey for signing
    required BackupConfig config,
    required List<Share> shares,
  }) async {
    try {
      if (shares.length != config.totalKeys) {
        throw ArgumentError('Number of shares must equal totalKeys');
      }

      final shareEvents = <ShareEvent>[];

      for (int i = 0; i < shares.length; i++) {
        final share = shares[i];
        final keyHolder = config.stewards[i];

        // Skip stewards without pubkeys (invited but not yet accepted)
        if (keyHolder.pubkey == null) {
          Log.info(
            'Skipping share distribution to steward ${keyHolder.name ?? keyHolder.id} - no pubkey yet (invited)',
          );
          continue;
        }

        try {
          // Capture before publish/push/repo so [updateDistributionStatus]'s
          // `since` lower bound is not shifted past fast steward acknowledgments.
          final shareDistributionStartedAt = DateTime.now();

          // Update share with relay URLs and distribution version from backup config
          final shareWithRelays = share.copyWith(
            relayUrls: config.relays,
            distributionVersion: config.distributionVersion,
          );

          // New Nostr wire format: content is raw payload, tags from shareToNostrTags
          final nostrContent = shareToNostrContent(shareWithRelays);
          final nostrTags = shareToNostrTags(shareWithRelays);
          // Add d tag for dedup (stable identifier for replaceable event)
          nostrTags.insert(0, ['d', 'share_${config.vaultId}_$i']);

          Log.debug('recipient pubkey: ${keyHolder.pubkey}');

          // Publish using NdkService. The method returns the signed gift
          // wrap so we can pipe it to [tryPushForEvent] below without
          // rebuilding it.
          final publishedEvent = await _ndkService.publishEncryptedEvent(
            content: nostrContent,
            kind: NostrKind.shareData.value,
            recipientPubkey: keyHolder.pubkey!,
            relays: config.relays,
            tags: nostrTags,
            customPubkey: ownerPubkey,
          );

          if (publishedEvent == null) {
            throw Exception('Failed to publish share event');
          }
          final eventId = publishedEvent.id;

          // Best-effort push to the steward. The event is already on Nostr,
          // so a notifier/FCM failure is non-fatal and swallowed inside
          // [tryPushForEvent].
          if (keyHolder.pubkey != ownerPubkey) {
            final vault = await _repository.getVault(config.vaultId);
            if (vault != null) {
              await _notificationService.tryPushForEvent(
                event: publishedEvent,
                kind: NostrKind.shareData,
                vault: vault,
                relayHints: config.relays,
              );
            }
          }

          // If this is the owner's own share, immediately store it locally and acknowledge it
          if (keyHolder.pubkey == ownerPubkey && keyHolder.isOwner) {
            try {
              // Update share with event ID and recipient pubkey
              final shareWithEventId = shareWithRelays.copyWith(
                nostrEventId: eventId,
                recipientPubkey: ownerPubkey,
              );

              // Store share locally (same persistence model as steward-held keys).
              await _repository.addShareToVault(
                config.vaultId,
                shareWithEventId,
              );

              // Immediately acknowledge with current distribution version
              await _repository.updateStewardStatus(
                vaultId: config.vaultId,
                pubkey: ownerPubkey,
                acknowledgedAt: DateTime.now(),
                // Owner self-steward: provenance is distribution version + outbound
                // wrap id only — no separate ack event id (stewards infer the same).
                acknowledgmentEventId: null,
                acknowledgedDistributionVersion: config.distributionVersion,
                giftWrapEventId: eventId,
              );

              Log.info(
                'Owner share stored locally and acknowledged immediately',
              );
            } catch (e) {
              Log.error(
                'Failed to store and acknowledge owner share locally',
                e,
              );
              // Continue - share was still published to Nostr
            }
          } else {
            // Record publish so [BackupConfig.needsRedistribution] can tell "awaiting
            // steward acknowledgment" apart from "owner still needs to send".
            await _repository.updateStewardStatus(
              vaultId: config.vaultId,
              pubkey: keyHolder.pubkey!,
              status: keyHolder.status,
              giftWrapEventId: eventId,
            );
          }

          // Create ShareEvent record
          final shareEvent = (
            giftWrapEventId: eventId,
            recipientPubkey: keyHolder.pubkey!,
            shareIndex: i,
            createdAt: shareDistributionStartedAt,
            publishedAt: null,
            status: EventStatus.created,
          );

          // Update status to published
          final publishedShareEvent = (
            giftWrapEventId: shareEvent.giftWrapEventId,
            recipientPubkey: shareEvent.recipientPubkey,
            shareIndex: shareEvent.shareIndex,
            createdAt: shareDistributionStartedAt,
            publishedAt: shareDistributionStartedAt,
            status: EventStatus.published,
          );

          shareEvents.add(publishedShareEvent);
          Log.info(
            'Distributed share $i to ${keyHolder.npub ?? keyHolder.name ?? keyHolder.id}',
          );
        } catch (e) {
          Log.error(
            'Failed to distribute share $i to ${keyHolder.npub ?? keyHolder.name ?? keyHolder.id}',
            e,
          );
          // Continue with other shares even if one fails
        }
      }

      final ownerInRoster = config.stewards.any(
        (s) => s.isOwner && s.pubkey == ownerPubkey,
      );
      if (!ownerInRoster) {
        final template = shares.firstWhere(
          (s) => s.payload.isNotEmpty,
          orElse: () => throw StateError('distributeShares: no payload-bearing share for manifest'),
        );
        final manifest = Share(
          payload: '',
          threshold: config.threshold,
          shareIndex: -1,
          totalShares: config.totalKeys,
          primeMod: template.primeMod,
          creatorPubkey: ownerPubkey,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          vaultId: config.vaultId,
          vaultName: template.vaultName,
          ownerName: template.ownerName,
          instructions: config.instructions,
          stewards: template.stewards,
          recipientPubkey: ownerPubkey,
          relayUrls: config.relays,
          distributionVersion: config.distributionVersion,
          pushEnabled: template.pushEnabled,
        );
        if (!manifest.isValid) {
          throw StateError('distributeShares: built manifest share failed validation');
        }
        // New Nostr wire format for manifest: empty content, tags from shareToNostrTags
        final manifestContent = shareToNostrContent(manifest);
        final manifestTags = shareToNostrTags(manifest);
        manifestTags.insert(0, ['d', 'manifest_${config.vaultId}']);
        final publishedManifest = await _ndkService.publishEncryptedEvent(
          content: manifestContent,
          kind: NostrKind.shareData.value,
          recipientPubkey: ownerPubkey,
          relays: config.relays,
          tags: manifestTags,
          customPubkey: ownerPubkey,
        );
        if (publishedManifest == null) {
          throw Exception('Failed to publish owner manifest share event');
        }
        Log.info(
          'Published manifest-only 1337 for vault ${config.vaultId} (owner not self-steward)',
        );
      }

      return shareEvents;
    } catch (e) {
      Log.error('Error distributing shares', e);
      throw Exception('Failed to distribute shares: $e');
    }
  }

  /// Check distribution status and update steward statuses
  Future<void> updateDistributionStatus({
    required String vaultId,
    required List<ShareEvent> shareEvents,
  }) async {
    try {
      final ndk = await _ndkService.getNdk();

      for (final shareEvent in shareEvents) {
        try {
          // Query for acknowledgment events (kind 1059) from the recipient
          final filter = Filter(
            kinds: [1059], // Gift wrap events
            authors: [shareEvent.recipientPubkey], // Hex format
            since: shareEvent.createdAt.secondsSinceEpoch,
          );

          final acknowledgmentResponse = ndk.requests.query(filters: [filter]);

          // Get the events from the response
          final acknowledgmentEvents = await acknowledgmentResponse.future;

          // Check if any acknowledgment event references our gift wrap
          bool isAcknowledged = false;
          String? acknowledgmentEventId;

          for (final event in acknowledgmentEvents) {
            // Look for 'p' tag referencing the original sender
            final pTags = event.pTags;
            if (pTags.isNotEmpty) {
              // This is a simplified check - in practice you'd want to verify
              // that this acknowledgment is specifically for our gift wrap
              isAcknowledged = true;
              acknowledgmentEventId = event.id;
              break;
            }
          }

          if (isAcknowledged) {
            // Get the backup config to get the current distribution version
            final vault = await _repository.getVault(vaultId);
            final backupConfig = vault?.backupConfig;
            final currentDistributionVersion = backupConfig?.distributionVersion;

            // Update steward status to holdingKey (confirmed receipt)
            await _repository.updateStewardStatus(
              vaultId: vaultId,
              pubkey: shareEvent.recipientPubkey, // Hex format
              acknowledgedAt: DateTime.now(),
              acknowledgmentEventId: acknowledgmentEventId,
              acknowledgedDistributionVersion: currentDistributionVersion,
            );
          } else {
            // Update steward status to awaitingKey (published but not acknowledged)
            await _repository.updateStewardStatus(
              vaultId: vaultId,
              pubkey: shareEvent.recipientPubkey, // Hex format
              status: StewardStatus.awaitingKey,
            );
          }
        } catch (e) {
          Log.error(
            'Failed to check acknowledgment for share ${shareEvent.shareIndex}',
            e,
          );
          // Continue with other shares even if one fails
        }
      }
    } catch (e) {
      Log.error('Error updating distribution status', e);
      throw Exception('Failed to update distribution status: $e');
    }
  }

  /// Processes share confirmation event received from steward (kind 1342).
  ///
  /// Tag-only wire (empty content): [vault_id], [share_index],
  /// optional [distribution_version], [confirmed_at]. Steward identity is
  /// [Nip01Event.pubKey] (gift-wrap seal author), not a redundant tag.
  Future<void> processShareConfirmationEvent({
    required Nip01Event event,
  }) async {
    // Validate event kind
    if (event.kind != NostrKind.shareConfirmation.value) {
      throw ArgumentError(
        'Invalid event kind: expected ${NostrKind.shareConfirmation.value}, got ${event.kind}',
      );
    }

    // Get current user's pubkey to verify we're the owner
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception(
        'No key pair available. Cannot process share confirmation event.',
      );
    }

    final vaultId = _extractTagValue(event.tags, 'vault_id');
    final shareIndexStr = _extractTagValue(event.tags, 'share_index');
    final distributionVersionStr = _extractTagValue(
      event.tags,
      'distribution_version',
    );

    if (vaultId == null) {
      throw ArgumentError('Missing vault_id tag in share confirmation event');
    }

    if (shareIndexStr == null) {
      throw ArgumentError('Missing share_index tag in share confirmation event');
    }

    final shareIndex = int.tryParse(shareIndexStr);
    if (shareIndex == null) {
      throw ArgumentError(
        'Invalid share_index in share confirmation event: $shareIndexStr',
      );
    }

    final tagDistributionVersion =
        distributionVersionStr != null ? int.tryParse(distributionVersionStr) : null;

    final vaultBefore = await _repository.getVault(vaultId);
    final config = vaultBefore?.backupConfig;
    final currentDistributionVersion = config?.distributionVersion ?? 0;
    final keyHolderPubkey = event.pubKey;

    final acknowledgedDistributionVersion = tagDistributionVersion ?? currentDistributionVersion;
    if (tagDistributionVersion != null && tagDistributionVersion > currentDistributionVersion) {
      Log.warning(
        'Share confirmation for future distribution v$tagDistributionVersion '
        '(current v$currentDistributionVersion) on vault $vaultId',
      );
    }
    await _repository.updateStewardStatus(
      vaultId: vaultId,
      pubkey: keyHolderPubkey,
      acknowledgedAt: DateTime.now(),
      acknowledgmentEventId: event.id,
      acknowledgedDistributionVersion: acknowledgedDistributionVersion,
    );

    final status = stewardStatusFromDistributionAck(
      acknowledgedDistributionVersion: acknowledgedDistributionVersion,
      currentDistributionVersion: currentDistributionVersion,
    );
    Log.info(
      'Processed share confirmation event for vault $vaultId, share $shareIndex '
      'from steward $keyHolderPubkey (ack v$acknowledgedDistributionVersion, status $status)',
    );
  }

  /// Processes share error event received from steward (kind 1343).
  ///
  /// Wire tags keep historical names (`shard`, `shard_index` in payload).
  Future<void> processShareErrorEvent({required Nip01Event event}) async {
    // Validate event kind
    if (event.kind != NostrKind.shareError.value) {
      throw ArgumentError(
        'Invalid event kind: expected ${NostrKind.shareError.value}, got ${event.kind}',
      );
    }

    // Get current user's pubkey to verify we're the owner
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception(
        'No key pair available. Cannot process share error event.',
      );
    }

    // Extract vault ID and share index from tags (wire `shard` tag)
    final vaultId = _extractTagValue(event.tags, 'vault');
    final shareIndexStr = _extractTagValue(event.tags, 'shard');

    if (vaultId == null) {
      throw ArgumentError('Missing vault tag in share error event');
    }

    if (shareIndexStr == null) {
      throw ArgumentError('Missing shard tag in share error event');
    }

    final shareIndex = int.tryParse(shareIndexStr);
    if (shareIndex == null) {
      throw ArgumentError(
        'Invalid share index in share error event: $shareIndexStr',
      );
    }

    // Verify we're the recipient (p tag should be owner)
    final recipientPubkey = _extractTagValue(event.tags, 'p');
    if (recipientPubkey != ownerPubkey) {
      throw ArgumentError('Share error event not addressed to current user');
    }

    // Decrypt event content
    String decryptedContent;
    try {
      decryptedContent = await _loginService.decryptFromSender(
        encryptedText: event.content,
        senderPubkey: event.pubKey,
      );
    } catch (e) {
      Log.error('Error decrypting share error event content', e);
      throw Exception('Failed to decrypt share error event content: $e');
    }

    // Parse decrypted JSON
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(decryptedContent) as Map<String, dynamic>;
    } catch (e) {
      Log.error('Error parsing share error event JSON', e);
      throw Exception('Invalid JSON in share error event content: $e');
    }

    // Validate payload (wire keys remain snake_case shard_* )
    final payloadVaultId = payload['vault_id'] as String?;
    final payloadShareIndex = payload['shard_index'] as int?;
    final error = payload['error'] as String? ?? 'Unknown error';

    if (payloadVaultId != vaultId) {
      throw ArgumentError('Vault ID mismatch in share error event payload');
    }

    if (payloadShareIndex != shareIndex) {
      throw ArgumentError('Share index mismatch in share error event payload');
    }

    // Update steward status to error
    final keyHolderPubkey = event.pubKey;
    await _repository.updateStewardStatus(
      vaultId: vaultId,
      pubkey: keyHolderPubkey,
      status: StewardStatus.error,
    );

    Log.error(
      'Processed share error event for vault $vaultId, share $shareIndex from steward $keyHolderPubkey: $error',
    );
  }

  /// Helper method to extract a tag value from event tags
  String? _extractTagValue(List<List<String>> tags, String tagName) {
    for (final tag in tags) {
      if (tag.isNotEmpty && tag[0] == tagName && tag.length > 1) {
        return tag[1];
      }
    }
    return null;
  }
}
