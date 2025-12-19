import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invitation_link.dart';
import '../models/shard_data.dart';
import '../models/vault.dart';
import '../models/nostr_kinds.dart';
import '../providers/vault_provider.dart';
import 'logger.dart';
import 'ndk_service.dart';

/// Provider for VaultShareService
/// This service depends on VaultRepository for shard management
final vaultShareServiceProvider = Provider<VaultShareService>((ref) {
  final repository = ref.watch(vaultRepositoryProvider);
  return VaultShareService(repository, () => ref.read(ndkServiceProvider));
});

/// Service for managing vault shares and recovery operations
///
/// Manages two types of shards:
/// 1. Key holder shards: Shards we hold as a steward for others (one per vault)
/// 2. Recovery shards: Shards we collect during recovery (multiple per recovery request)
class VaultShareService {
  final VaultRepository repository;
  final NdkService Function() _getNdkService;

  VaultShareService(this.repository, this._getNdkService);
  static const String _shardDataKey = 'vault_shard_data';
  static const String _recoveryShardDataKey = 'recovery_shard_data';

  // Shards we hold as a steward (one per vault)
  static Map<String, ShardData>? _cachedShardData; // vaultId -> ShardData

  // Shards collected during recovery (multiple per recovery request)
  static Map<String, List<ShardData>>?
      _cachedRecoveryShards; // recoveryRequestId -> List<ShardData>

  static bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadShardData();
      await _loadRecoveryShardData();
      _isInitialized = true;
      Log.info(
        'VaultShareService initialized with ${_cachedShardData?.length ?? 0} steward shards and ${_cachedRecoveryShards?.length ?? 0} recovery requests',
      );
    } catch (e) {
      Log.error('Error initializing VaultShareService', e);
      _cachedShardData = {};
      _cachedRecoveryShards = {};
      _isInitialized = true;
    }
  }

  /// Load shard data from storage
  Future<void> _loadShardData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_shardDataKey);

    if (jsonData == null || jsonData.isEmpty) {
      _cachedShardData = {};
      return;
    }

    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonData);
      _cachedShardData = jsonMap.map((vaultId, shardJson) {
        final shard = shardDataFromJson(shardJson as Map<String, dynamic>);
        return MapEntry(vaultId, shard);
      });
      Log.info(
        'Loaded shard data for ${_cachedShardData!.length} vaults from storage',
      );
    } catch (e) {
      Log.error('Error loading shard data', e);
      _cachedShardData = {};
    }
  }

  /// Save shard data to storage
  Future<void> _saveShardData() async {
    if (_cachedShardData == null) return;

    try {
      final jsonMap = _cachedShardData!.map((vaultId, shard) {
        final shardJson = shardDataToJson(shard);
        return MapEntry(vaultId, shardJson);
      });
      final jsonString = json.encode(jsonMap);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_shardDataKey, jsonString);
      Log.info(
        'Saved shard data for ${_cachedShardData!.length} vaults to storage',
      );
    } catch (e) {
      Log.error('Error saving shard data', e);
      throw Exception('Failed to save shard data: $e');
    }
  }

  /// Load recovery shard data from storage
  Future<void> _loadRecoveryShardData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString(_recoveryShardDataKey);

    if (jsonData == null || jsonData.isEmpty) {
      _cachedRecoveryShards = {};
      return;
    }

    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonData);
      _cachedRecoveryShards = jsonMap.map((recoveryRequestId, shardListJson) {
        final shardList = (shardListJson as List<dynamic>)
            .map((json) => shardDataFromJson(json as Map<String, dynamic>))
            .toList();
        return MapEntry(recoveryRequestId, shardList);
      });
      Log.info(
        'Loaded recovery shards for ${_cachedRecoveryShards!.length} recovery requests from storage',
      );
    } catch (e) {
      Log.error('Error loading recovery shard data', e);
      _cachedRecoveryShards = {};
    }
  }

  /// Save recovery shard data to storage
  Future<void> _saveRecoveryShardData() async {
    if (_cachedRecoveryShards == null) return;

    try {
      final jsonMap = _cachedRecoveryShards!.map((
        recoveryRequestId,
        shardList,
      ) {
        final shardListJson = shardList.map((shard) => shardDataToJson(shard)).toList();
        return MapEntry(recoveryRequestId, shardListJson);
      });
      final jsonString = json.encode(jsonMap);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recoveryShardDataKey, jsonString);
      Log.info(
        'Saved recovery shards for ${_cachedRecoveryShards!.length} recovery requests to storage',
      );
    } catch (e) {
      Log.error('Error saving recovery shard data', e);
      throw Exception('Failed to save recovery shard data: $e');
    }
  }

  /// Get all shares for a vault
  /// Now delegates to VaultService
  Future<List<ShardData>> getVaultShares(String vaultId) async {
    return await repository.getShardsForVault(vaultId);
  }

  /// Get the share for a vault (returns first shard if multiple exist)
  /// Now delegates to VaultRepository
  Future<ShardData?> getVaultShare(String vaultId) async {
    final shards = await repository.getShardsForVault(vaultId);
    return shards.isNotEmpty ? shards.first : null;
  }

  /// Get a specific share by nostr event ID
  Future<ShardData?> getShareByEventId(String nostrEventId) async {
    await initialize();

    for (final shard in _cachedShardData!.values) {
      if (shard.nostrEventId == nostrEventId) {
        return shard;
      }
    }

    return null;
  }

  /// Add or update shard data for a vault
  /// Now delegates to VaultService
  Future<void> addVaultShare(String vaultId, ShardData shardData) async {
    // Validate shard data
    if (!shardData.isValid) {
      throw ArgumentError('Invalid shard data');
    }

    // Create a vault record if one doesn't exist yet
    await _ensureVaultExists(vaultId, shardData);

    // Add shard to vault via VaultService
    await repository.addShardToVault(vaultId, shardData);
    Log.info(
      'Added shard for vault $vaultId (event: ${shardData.nostrEventId})',
    );
  }

  /// Process a received vault share (invitation flow)
  ///
  /// This method handles the complete flow when an invitee receives a shard:
  /// 1. Stores the shard via addVaultShare (skips if duplicate)
  /// 2. Sends a confirmation event to notify the owner (only if shard was actually stored)
  ///
  /// Uses relay URLs from the shard data (included during distribution).
  Future<void> processVaultShare(String vaultId, ShardData shardData) async {
    // Validate shard data
    if (!shardData.isValid) {
      throw ArgumentError('Invalid shard data');
    }

    // Check if we already have this shard (by nostrEventId)
    final existingVault = await repository.getVault(vaultId);
    if (existingVault != null && shardData.nostrEventId != null) {
      final hasDuplicate = existingVault.shards.any(
        (s) => s.nostrEventId != null && s.nostrEventId == shardData.nostrEventId,
      );

      if (hasDuplicate) {
        Log.info(
          'Shard with event ID ${shardData.nostrEventId} already exists for vault $vaultId, skipping processing',
        );
        return; // Already have this shard, skip storing and sending confirmation
      }
    }

    // Store the shard first
    await addVaultShare(vaultId, shardData);

    // Send shard confirmation event after successfully storing the shard
    // This is required for invitation flow - the owner needs to know the invitee received the shard
    try {
      // Get relay URLs from shard data (included during distribution from backup config)
      if (shardData.relayUrls != null && shardData.relayUrls!.isNotEmpty) {
        final ownerPubkey = shardData.creatorPubkey;
        final shardIndex = shardData.shardIndex;

        // Send confirmation event with distribution version if available
        final eventId = await sendShardConfirmationEvent(
          vaultId: vaultId,
          shardIndex: shardIndex,
          ownerPubkey: ownerPubkey,
          relayUrls: shardData.relayUrls!,
          distributionVersion: shardData.distributionVersion,
        );

        if (eventId != null) {
          Log.info(
            'Sent shard confirmation event $eventId for vault $vaultId, shard $shardIndex',
          );
        } else {
          Log.warning(
            'Failed to send shard confirmation event for vault $vaultId, shard $shardIndex',
          );
        }
      } else {
        Log.warning(
          'No relay URLs found in shard data for vault $vaultId - cannot send shard confirmation event',
        );
      }
    } catch (e) {
      Log.error('Error sending shard confirmation event for vault $vaultId', e);
      // Don't fail shard storage if confirmation sending fails
    }
  }

  /// Creates and publishes shard confirmation event
  ///
  /// Creates confirmation event with empty content.
  /// All confirmation data is stored in tags.
  /// Encrypts using NIP-44.
  /// Creates Nostr event (kind 1342).
  /// Signs with steward's private key.
  /// Publishes to relays.
  /// Returns event ID.
  Future<String?> sendShardConfirmationEvent({
    required String vaultId,
    required int shardIndex,
    required String ownerPubkey, // Hex format
    required List<String> relayUrls,
    int? distributionVersion, // Optional distribution version
  }) async {
    try {
      final ndkService = _getNdkService();
      final currentPubkey = await ndkService.getCurrentPubkey();
      if (currentPubkey == null) {
        Log.error('No key pair available for sending shard confirmation event');
        return null;
      }

      Log.info(
        'Sending shard confirmation event for vault: ${vaultId.substring(0, 8)}..., shard: $shardIndex',
      );

      // Build tags list
      final tags = [
        ['vault_id', vaultId],
        ['shard_index', shardIndex.toString()],
        ['steward_pubkey', currentPubkey],
        ['confirmed_at', DateTime.now().toIso8601String()],
      ];

      // Add distribution version if provided
      if (distributionVersion != null) {
        tags.add(['distribution_version', distributionVersion.toString()]);
      }

      // Publish using NdkService with empty content, all data in tags
      return await ndkService.publishEncryptedEvent(
        content: '',
        kind: NostrKind.shardConfirmation.value,
        recipientPubkey: ownerPubkey,
        relays: relayUrls,
        tags: tags,
      );
    } catch (e) {
      Log.error('Error sending shard confirmation event', e);
      return null;
    }
  }

  /// Ensure a vault record exists for received shares
  Future<void> _ensureVaultExists(String vaultId, ShardData shardData) async {
    try {
      // Check if vault already exists
      final existingVault = await repository.getVault(vaultId);
      if (existingVault != null) {
        // Vault exists - check if it's a stub (no shards, no content)
        // If stub, update it with shard data
        if (existingVault.shards.isEmpty && existingVault.content == null) {
          // This is a stub vault created when invitation was accepted
          // Update it with shard data and name from ShardData if available
          final updatedVault = existingVault.copyWith(
            name: shardData.vaultName ?? existingVault.name,
            ownerName: shardData.ownerName ?? existingVault.ownerName,
            // createdAt stays the same (from invitation)
            // ownerPubkey stays the same (from invitation)
            // shards will be added via addShardToVault below
          );
          await repository.saveVault(updatedVault);
          Log.info('Updated stub vault $vaultId with shard data');
        } else {
          Log.info('Vault $vaultId already exists with shards/content');
        }
        return;
      }

      // Create a new vault entry for the shared key
      final vaultName = shardData.vaultName ?? defaultVaultName;

      final vault = Vault(
        id: vaultId,
        name: vaultName,
        content: null, // No decrypted content yet - we only have a shard
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          shardData.createdAt * 1000,
        ),
        ownerPubkey: shardData.creatorPubkey, // Owner is the creator of the shard
        ownerName: shardData.ownerName, // Set owner name from shard data
      );

      await repository.addVault(vault);
      Log.info('Created vault record for shared key: $vaultId ($vaultName)');
    } catch (e) {
      Log.error('Error creating vault record for $vaultId', e);
      // Don't throw - we don't want to fail shard storage just because vault creation failed
    }
  }

  /// Mark a share as received
  Future<void> markShareAsReceived(String vaultId) async {
    await initialize();

    final shard = _cachedShardData![vaultId];
    if (shard == null) {
      throw ArgumentError('No share found for vault: $vaultId');
    }

    // Update shard data with received information
    final updatedShard = copyShardData(
      shard,
      isReceived: true,
      receivedAt: DateTime.now(),
    );

    _cachedShardData![vaultId] = updatedShard;
    await _saveShardData();
    Log.info(
      'Marked share as received for vault $vaultId (event: ${shard.nostrEventId})',
    );
  }

  /// Mark a share as received by event ID
  Future<void> markShareAsReceivedByEventId(String nostrEventId) async {
    await initialize();

    for (final entry in _cachedShardData!.entries) {
      if (entry.value.nostrEventId == nostrEventId) {
        await markShareAsReceived(entry.key);
        return;
      }
    }

    throw ArgumentError('Share not found with nostr event ID: $nostrEventId');
  }

  /// Reassemble vault content from collected shares
  /// Note: This service now only stores a single shard per vault.
  /// For full recovery, you need to collect shards from multiple stewards.
  Future<String?> reassembleVaultContent(String vaultId) async {
    await initialize();

    final shard = _cachedShardData![vaultId];
    if (shard == null) {
      Log.warning('No shard found for vault $vaultId');
      return null;
    }

    Log.warning(
      'Cannot reassemble from single shard - need ${shard.threshold} shards from recovery process',
    );
    return null;
  }

  /// Check if we have a shard for this vault
  /// Note: This returns true if we have ANY shard, but doesn't indicate if we have sufficient shards for recovery
  Future<bool> hasShard(String vaultId) async {
    await initialize();
    return _cachedShardData!.containsKey(vaultId);
  }

  /// Get all collected shard data (returns all shards we hold as a steward)
  Future<List<ShardData>> getAllCollectedShards() async {
    await initialize();
    return _cachedShardData!.values.toList();
  }

  /// Get all vaults that have shares (indicating steward status)
  Future<List<String>> getVaultsWithShares() async {
    await initialize();
    return _cachedShardData!.keys.toList();
  }

  /// Check if user is a steward for a vault
  /// Now delegates to VaultService
  Future<bool> isKeyHolderForVault(String vaultId) async {
    return await repository.isKeyHolderForVault(vaultId);
  }

  /// Get shard count for a vault
  /// Now delegates to VaultService
  Future<int> getShardCount(String vaultId) async {
    final shards = await repository.getShardsForVault(vaultId);
    return shards.length;
  }

  /// Remove shard for a vault
  /// Now delegates to VaultService
  Future<void> removeVaultShare(String vaultId) async {
    await repository.clearShardsForVault(vaultId);
    Log.info('Removed all shards for vault $vaultId');
  }

  /// Remove a specific shard by nostr event ID
  Future<void> removeShareByEventId(String nostrEventId) async {
    await initialize();

    for (final entry in _cachedShardData!.entries) {
      if (entry.value.nostrEventId == nostrEventId) {
        await removeVaultShare(entry.key);
        return;
      }
    }

    throw ArgumentError('Share not found with nostr event ID: $nostrEventId');
  }

  /// Get total shard count across all vaults (equals number of vaults we're a steward for)
  Future<int> getTotalShardCount() async {
    await initialize();
    return _cachedShardData!.length;
  }

  // ========== Recovery Shard Methods ==========
  // These methods manage shards collected during recovery

  /// Add a recovery shard (for recovery initiator collecting shards from stewards)
  Future<void> addRecoveryShard(
    String recoveryRequestId,
    ShardData shardData,
  ) async {
    await initialize();

    // Validate shard data
    if (!shardData.isValid) {
      throw ArgumentError('Invalid shard data');
    }

    // Get existing shards for this recovery request
    final existingShards = _cachedRecoveryShards![recoveryRequestId] ?? [];

    // Check if shard with this nostrEventId already exists
    final existingIndex = existingShards.indexWhere(
      (s) => s.nostrEventId != null && s.nostrEventId == shardData.nostrEventId,
    );

    if (existingIndex != -1) {
      // Update existing shard
      existingShards[existingIndex] = shardData;
      Log.info(
        'Updated recovery shard for request $recoveryRequestId (event: ${shardData.nostrEventId})',
      );
    } else {
      // Add new shard
      existingShards.add(shardData);
      Log.info(
        'Added recovery shard for request $recoveryRequestId (event: ${shardData.nostrEventId}, total: ${existingShards.length})',
      );
    }

    _cachedRecoveryShards![recoveryRequestId] = existingShards;
    await _saveRecoveryShardData();
  }

  /// Get all recovery shards for a recovery request
  Future<List<ShardData>> getRecoveryShards(String recoveryRequestId) async {
    await initialize();

    final shards = _cachedRecoveryShards![recoveryRequestId];
    if (shards == null) return [];

    return List.unmodifiable(shards);
  }

  /// Get recovery shard count for a recovery request
  Future<int> getRecoveryShardCount(String recoveryRequestId) async {
    await initialize();

    final shards = _cachedRecoveryShards![recoveryRequestId];
    return shards?.length ?? 0;
  }

  /// Check if we have sufficient recovery shards for a recovery request
  Future<bool> hasSufficientRecoveryShards(
    String recoveryRequestId,
    int threshold,
  ) async {
    await initialize();

    final shards = _cachedRecoveryShards![recoveryRequestId];
    return (shards?.length ?? 0) >= threshold;
  }

  /// Remove all recovery shards for a recovery request
  Future<void> removeRecoveryShards(String recoveryRequestId) async {
    await initialize();

    if (_cachedRecoveryShards!.containsKey(recoveryRequestId)) {
      final count = _cachedRecoveryShards![recoveryRequestId]!.length;
      _cachedRecoveryShards!.remove(recoveryRequestId);
      await _saveRecoveryShardData();
      Log.info('Removed $count recovery shards for request $recoveryRequestId');
    }
  }

  /// Clear all shard data (for testing)
  Future<void> clearAll() async {
    _cachedShardData = {};
    _cachedRecoveryShards = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shardDataKey);
    await prefs.remove(_recoveryShardDataKey);
    _isInitialized = false;
    Log.info('Cleared all shard data and recovery shards');
  }

  /// Refresh the cached data from storage
  Future<void> refresh() async {
    _isInitialized = false;
    _cachedShardData = null;
    _cachedRecoveryShards = null;
    await initialize();
  }

  /// Process a steward removal event
  ///
  /// When a steward receives a removal event, they should:
  /// 1. Archive the vault (set isArchived=true, archivedAt=now, archivedReason="Removed by owner")
  /// 2. Delete their shard for that vault
  /// 3. Save the updated vault
  Future<void> processKeyHolderRemoval({required Nip01Event event}) async {
    try {
      // Validate event kind
      if (event.kind != NostrKind.keyHolderRemoved.value) {
        throw ArgumentError(
          'Invalid event kind: expected ${NostrKind.keyHolderRemoved.value}, got ${event.kind}',
        );
      }

      // Parse the removal data from the unwrapped content (already decrypted by NDK)
      Map<String, dynamic> payload;
      try {
        Log.debug('Key holder removed event content: ${event.content}');
        payload = json.decode(event.content) as Map<String, dynamic>;
        Log.debug(
          'Key holder removed event payload keys: ${payload.keys.toList()}',
        );
      } catch (e) {
        Log.error('Error parsing steward removed event JSON', e);
        throw Exception(
          'Failed to parse steward removed event content. The event may be corrupted or encrypted incorrectly: $e',
        );
      }

      // Extract vault ID from payload
      final vaultId = payload['vault_id'] as String?;
      if (vaultId == null || vaultId.isEmpty) {
        throw ArgumentError(
          'Missing vault_id in steward removed event payload',
        );
      }

      Log.info(
        'Processing steward removal for vault: ${vaultId.substring(0, 8)}...',
      );

      // Get the vault
      final vault = await repository.getVault(vaultId);
      if (vault == null) {
        Log.warning('Vault $vaultId not found - may have already been deleted');
        return;
      }

      // Archive the vault
      final archivedVault = vault.copyWith(
        isArchived: true,
        archivedAt: DateTime.now(),
        archivedReason: 'Removed by owner',
      );
      await repository.saveVault(archivedVault);
      Log.info('Archived vault $vaultId');

      // Delete the shard for this vault
      await removeVaultShare(vaultId);
      Log.info('Removed shard for archived vault $vaultId');

      Log.info('Successfully processed steward removal for vault $vaultId');
    } catch (e) {
      Log.error('Error processing steward removal event ${event.id}', e);
      rethrow;
    }
  }
}
