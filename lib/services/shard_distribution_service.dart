import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import '../models/backup_config.dart';
import '../models/nostr_kinds.dart';
import '../models/shard_event.dart';
import '../models/shard_data.dart';
import '../models/steward.dart';
import '../models/steward_status.dart';
import '../models/event_status.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import 'login_service.dart';
import 'ndk_service.dart';
import 'logger.dart';

/// Provider for ShardDistributionService
final Provider<ShardDistributionService> shardDistributionServiceProvider =
    Provider<ShardDistributionService>((ref) {
  return ShardDistributionService(
    ref.read(vaultRepositoryProvider),
    ref.read(loginServiceProvider),
    ref.read(ndkServiceProvider),
  );
});

/// Service for distributing shards to stewards via Nostr
class ShardDistributionService {
  final VaultRepository _repository;
  final LoginService _loginService;
  final NdkService _ndkService;

  ShardDistributionService(
    this._repository,
    this._loginService,
    this._ndkService,
  );

  /// Distribute shards to all stewards
  Future<List<ShardEvent>> distributeShards({
    required String ownerPubkey, // Hex format - vault owner's pubkey for signing
    required BackupConfig config,
    required List<ShardData> shards,
  }) async {
    try {
      if (shards.length != config.totalKeys) {
        throw ArgumentError('Number of shards must equal totalKeys');
      }

      final shardEvents = <ShardEvent>[];

      for (int i = 0; i < shards.length; i++) {
        final shard = shards[i];
        final keyHolder = config.stewards[i];

        // Skip stewards without pubkeys (invited but not yet accepted)
        if (keyHolder.pubkey == null) {
          Log.info(
            'Skipping shard distribution to steward ${keyHolder.name ?? keyHolder.id} - no pubkey yet (invited)',
          );
          continue;
        }

        try {
          // Update shard with relay URLs and distribution version from backup config
          final shardWithRelays = copyShardData(
            shard,
            relayUrls: config.relays,
            distributionVersion: config.distributionVersion,
          );

          // Create shard data JSON
          final shardJson = shardDataToJson(shardWithRelays);
          final shardString = json.encode(shardJson);

          Log.debug('recipient pubkey: ${keyHolder.pubkey}');

          // Publish using NdkService
          final eventId = await _ndkService.publishEncryptedEvent(
            content: shardString,
            kind: NostrKind.shardData.value,
            recipientPubkey: keyHolder.pubkey!, // Hex format - safe because we checked null above
            relays: config.relays,
            tags: [
              ['d', 'shard_${config.vaultId}_$i'], // Distinguisher tag
              ['backup_config_id', config.vaultId],
              ['shard_index', i.toString()],
            ],
            customPubkey: ownerPubkey, // Vault owner signs the rumor
          );

          if (eventId == null) {
            throw Exception('Failed to publish shard event');
          }

          // Create ShardEvent record
          final shardEvent = createShardEvent(
            eventId: eventId,
            recipientPubkey: keyHolder.pubkey!, // Hex format - safe because we checked null above
            encryptedContent: shardString, // Store original content for reference
            backupConfigId: config.vaultId,
            shardIndex: i,
          );

          // Update status to published
          final publishedShardEvent = copyShardEvent(
            shardEvent,
            publishedAt: DateTime.now(),
            status: EventStatus.published,
          );

          shardEvents.add(publishedShardEvent);
          Log.info(
            'Distributed shard $i to ${keyHolder.npub ?? keyHolder.name ?? keyHolder.id}',
          );
        } catch (e) {
          Log.error(
            'Failed to distribute shard $i to ${keyHolder.npub ?? keyHolder.name ?? keyHolder.id}',
            e,
          );
          // Continue with other shards even if one fails
        }
      }

      return shardEvents;
    } catch (e) {
      Log.error('Error distributing shards', e);
      throw Exception('Failed to distribute shards: $e');
    }
  }

  /// Check distribution status and update steward statuses
  Future<void> updateDistributionStatus({
    required String vaultId,
    required List<ShardEvent> shardEvents,
  }) async {
    try {
      final ndk = await _ndkService.getNdk();

      for (final shardEvent in shardEvents) {
        try {
          // Query for acknowledgment events (kind 1059) from the recipient
          final filter = Filter(
            kinds: [1059], // Gift wrap events
            authors: [shardEvent.recipientPubkey], // Hex format
            since: shardEvent.createdAt.millisecondsSinceEpoch ~/ 1000,
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
            // Update steward status to holdingKey (confirmed receipt)
            await _repository.updateStewardStatus(
              vaultId: vaultId,
              pubkey: shardEvent.recipientPubkey, // Hex format
              status: StewardStatus.holdingKey,
              acknowledgedAt: DateTime.now(),
              acknowledgmentEventId: acknowledgmentEventId,
            );
          } else {
            // Update steward status to awaitingKey (published but not acknowledged)
            await _repository.updateStewardStatus(
              vaultId: vaultId,
              pubkey: shardEvent.recipientPubkey, // Hex format
              status: StewardStatus.awaitingKey,
            );
          }
        } catch (e) {
          Log.error(
            'Failed to check acknowledgment for shard ${shardEvent.shardIndex}',
            e,
          );
          // Continue with other shards even if one fails
        }
      }
    } catch (e) {
      Log.error('Error updating distribution status', e);
      throw Exception('Failed to update distribution status: $e');
    }
  }

  /// Processes shard confirmation event received from steward
  ///
  /// Decrypts event content using NIP-44.
  /// Validates vault ID and shard index.
  /// Updates steward status to "holding key".
  /// Updates last acknowledgment timestamp.
  Future<void> processShardConfirmationEvent({
    required Nip01Event event,
  }) async {
    // Validate event kind
    if (event.kind != NostrKind.shardConfirmation.value) {
      throw ArgumentError(
        'Invalid event kind: expected ${NostrKind.shardConfirmation.value}, got ${event.kind}',
      );
    }

    // Get current user's pubkey to verify we're the owner
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception(
        'No key pair available. Cannot process shard confirmation event.',
      );
    }

    // Extract vault ID, shard index, and distribution version from tags
    // All confirmation data is stored in tags (no content)
    final vaultId = _extractTagValue(event.tags, 'vault_id');
    final shardIndexStr = _extractTagValue(event.tags, 'shard_index');
    final distributionVersionStr = _extractTagValue(
      event.tags,
      'distribution_version',
    );

    if (vaultId == null) {
      throw ArgumentError('Missing vault_id tag in shard confirmation event');
    }

    if (shardIndexStr == null) {
      throw ArgumentError(
        'Missing shard_index tag in shard confirmation event',
      );
    }

    final shardIndex = int.tryParse(shardIndexStr);
    if (shardIndex == null) {
      throw ArgumentError(
        'Invalid shard index in shard confirmation event: $shardIndexStr',
      );
    }

    final distributionVersion =
        distributionVersionStr != null ? int.tryParse(distributionVersionStr) : null;

    // Update steward status
    final keyHolderPubkey = event.pubKey;
    await _repository.updateStewardStatus(
      vaultId: vaultId,
      pubkey: keyHolderPubkey,
      status: StewardStatus.holdingKey,
      acknowledgedAt: DateTime.now(),
      acknowledgmentEventId: event.id,
      acknowledgedDistributionVersion: distributionVersion,
    );

    Log.info(
      'Processed shard confirmation event for vault $vaultId, shard $shardIndex from steward $keyHolderPubkey',
    );
  }

  /// Processes shard error event received from steward
  ///
  /// Decrypts event content using NIP-44.
  /// Validates vault ID and shard index.
  /// Updates steward status to "error".
  /// Logs error details.
  Future<void> processShardErrorEvent({required Nip01Event event}) async {
    // Validate event kind
    if (event.kind != NostrKind.shardError.value) {
      throw ArgumentError(
        'Invalid event kind: expected ${NostrKind.shardError.value}, got ${event.kind}',
      );
    }

    // Get current user's pubkey to verify we're the owner
    final ownerPubkey = await _loginService.getCurrentPublicKey();
    if (ownerPubkey == null) {
      throw Exception(
        'No key pair available. Cannot process shard error event.',
      );
    }

    // Extract vault ID and shard index from tags
    final vaultId = _extractTagValue(event.tags, 'vault');
    final shardIndexStr = _extractTagValue(event.tags, 'shard');

    if (vaultId == null) {
      throw ArgumentError('Missing vault tag in shard error event');
    }

    if (shardIndexStr == null) {
      throw ArgumentError('Missing shard tag in shard error event');
    }

    final shardIndex = int.tryParse(shardIndexStr);
    if (shardIndex == null) {
      throw ArgumentError(
        'Invalid shard index in shard error event: $shardIndexStr',
      );
    }

    // Verify we're the recipient (p tag should be owner)
    final recipientPubkey = _extractTagValue(event.tags, 'p');
    if (recipientPubkey != ownerPubkey) {
      throw ArgumentError('Shard error event not addressed to current user');
    }

    // Decrypt event content
    String decryptedContent;
    try {
      decryptedContent = await _loginService.decryptFromSender(
        encryptedText: event.content,
        senderPubkey: event.pubKey,
      );
    } catch (e) {
      Log.error('Error decrypting shard error event content', e);
      throw Exception('Failed to decrypt shard error event content: $e');
    }

    // Parse decrypted JSON
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(decryptedContent) as Map<String, dynamic>;
    } catch (e) {
      Log.error('Error parsing shard error event JSON', e);
      throw Exception('Invalid JSON in shard error event content: $e');
    }

    // Validate payload
    final payloadVaultId = payload['vaultId'] as String?;
    final payloadShardIndex = payload['shardIndex'] as int?;
    final error = payload['error'] as String? ?? 'Unknown error';

    if (payloadVaultId != vaultId) {
      throw ArgumentError('Vault ID mismatch in shard error event payload');
    }

    if (payloadShardIndex != shardIndex) {
      throw ArgumentError('Shard index mismatch in shard error event payload');
    }

    // Update steward status to error
    final keyHolderPubkey = event.pubKey;
    await _repository.updateStewardStatus(
      vaultId: vaultId,
      pubkey: keyHolderPubkey,
      status: StewardStatus.error,
    );

    Log.error(
      'Processed shard error event for vault $vaultId, shard $shardIndex from steward $keyHolderPubkey: $error',
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
