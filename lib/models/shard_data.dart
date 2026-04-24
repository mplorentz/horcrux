import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault.dart';
import '../services/logger.dart';
import '../utils/date_time_extensions.dart';

part 'shard_data.freezed.dart';

/// Represents the decrypted shard data contained within a ShardEvent
///
/// This model contains the actual Shamir share data that is encrypted
/// and stored in the ShardEvent for distribution to stewards.
///
/// Extended with optional recovery metadata for vault recovery feature.
@freezed
class ShardData with _$ShardData {
  const factory ShardData({
    required String shard,
    required int threshold,
    required int shardIndex,
    required int totalShards,
    required String primeMod,
    required String creatorPubkey,
    required int createdAt,
    // Recovery metadata (optional fields)
    String? vaultId,
    String? vaultName,
    List<Map<String, String>>?
        stewards, // List of maps with 'name', 'pubkey', and optionally 'contactInfo' for OTHER stewards (excludes creatorPubkey)
    String? ownerName, // Name of the vault owner (creator)
    String? instructions, // Instructions for stewards
    String? recipientPubkey,
    bool? isReceived,
    DateTime? receivedAt,
    String? nostrEventId,
    List<String>? relayUrls, // Relay URLs from backup config for sending confirmations
    int?
        distributionVersion, // Version tracking for redistribution detection (nullable for backward compatibility)
    // Whether the vault owner has push notifications enabled for this vault.
    //
    // Nullable for backward compatibility: pre-push shards arrive without this
    // field, in which case receivers should preserve whatever push setting
    // their local Vault already has (don't silently flip anything). When the
    // owner re-distributes after changing the flag, the new value overrides.
    // The owner is the only party whose opinion matters here because they are
    // the one whose pubkey/IP/contact-graph leaks to the notifier.
    bool? pushEnabled,
  }) = _ShardData;

  const ShardData._();

  /// Check if this shard data is valid
  bool get isValid {
    try {
      if (shard.isEmpty) {
        Log.error('ShardData validation failed: shard is empty');
        return false;
      }

      if (threshold < VaultBackupConstraints.minThreshold) {
        Log.error(
          'ShardData validation failed: threshold ($threshold) is below minimum '
          '(${VaultBackupConstraints.minThreshold})',
        );
        return false;
      }

      if (threshold > totalShards) {
        Log.error(
          'ShardData validation failed: threshold ($threshold) exceeds totalShards ($totalShards)',
        );
        return false;
      }

      if (shardIndex < 0) {
        Log.error(
          'ShardData validation failed: shardIndex ($shardIndex) is negative',
        );
        return false;
      }

      if (shardIndex >= totalShards) {
        Log.error(
          'ShardData validation failed: shardIndex ($shardIndex) is out of bounds (should be 0 to ${totalShards - 1})',
        );
        return false;
      }

      if (primeMod.isEmpty) {
        Log.error('ShardData validation failed: primeMod is empty');
        return false;
      }

      if (creatorPubkey.isEmpty) {
        Log.error('ShardData validation failed: creatorPubkey is empty');
        return false;
      }

      if (createdAt <= 0) {
        Log.error(
          'ShardData validation failed: createdAt ($createdAt) is invalid (must be > 0)',
        );
        return false;
      }

      // Validate stewards if provided
      if (stewards != null) {
        for (final steward in stewards!) {
          if (!steward.containsKey('name') || !steward.containsKey('pubkey')) {
            Log.error(
              'ShardData validation failed: All stewards must have both "name" and "pubkey" keys',
            );
            return false;
          }
          final pubkey = steward['pubkey']!;
          if (pubkey.length != 64 || !_isHexString(pubkey)) {
            Log.error(
              'ShardData validation failed: All steward pubkeys must be valid hex format (64 characters): $pubkey',
            );
            return false;
          }
          if (steward['name'] == null || steward['name']!.isEmpty) {
            Log.error('ShardData validation failed: All stewards must have a non-empty name');
            return false;
          }
          // contactInfo is optional, but if present, validate length
          final contactInfo = steward['contactInfo'];
          if (contactInfo != null && contactInfo.length > 500) {
            Log.error(
              'ShardData validation failed: Steward contactInfo exceeds maximum length of 500 characters',
            );
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      Log.error('ShardData validation failed with exception', e);
      return false;
    }
  }

  /// Get the age of this shard data in seconds
  int get ageInSeconds {
    final now = secondsSinceEpoch();
    return now - createdAt;
  }

  /// Get the age of this shard data in hours
  double get ageInHours {
    return ageInSeconds / 3600.0;
  }

  /// Check if this shard data is recent (less than 24 hours old)
  bool get isRecent {
    return ageInHours < 24.0;
  }
}

/// Helper to validate hex strings
bool _isHexString(String str) {
  return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
}

/// Create a new ShardData with validation
ShardData createShardData({
  required String shard,
  required int threshold,
  required int shardIndex,
  required int totalShards,
  required String primeMod,
  required String creatorPubkey,
  String? vaultId,
  String? vaultName,
  List<Map<String, String>>? stewards,
  String? ownerName,
  String? instructions,
  String? recipientPubkey,
  bool? isReceived,
  DateTime? receivedAt,
  String? nostrEventId,
  List<String>? relayUrls,
  int? distributionVersion,
  bool? pushEnabled,
}) {
  if (shard.isEmpty) {
    throw ArgumentError('Shard cannot be empty');
  }
  if (threshold < VaultBackupConstraints.minThreshold || threshold > totalShards) {
    throw ArgumentError(
      'Threshold must be >= ${VaultBackupConstraints.minThreshold} and <= totalShards',
    );
  }
  if (shardIndex < 0 || shardIndex >= totalShards) {
    throw ArgumentError('ShardIndex must be >= 0 and < totalShards');
  }
  if (primeMod.isEmpty) {
    throw ArgumentError('PrimeMod cannot be empty');
  }
  if (creatorPubkey.isEmpty) {
    throw ArgumentError('CreatorPubkey cannot be empty');
  }

  // Validate recovery metadata if provided
  if (recipientPubkey != null && (recipientPubkey.length != 64 || !_isHexString(recipientPubkey))) {
    throw ArgumentError(
      'RecipientPubkey must be valid hex format (64 characters)',
    );
  }
  if (isReceived == true && receivedAt != null && receivedAt.isAfter(DateTime.now())) {
    throw ArgumentError('ReceivedAt must be in the past if isReceived is true');
  }
  if (stewards != null) {
    for (final steward in stewards) {
      if (!steward.containsKey('name') || !steward.containsKey('pubkey')) {
        throw ArgumentError(
          'All stewards must have both "name" and "pubkey" keys',
        );
      }
      final pubkey = steward['pubkey']!;
      if (pubkey.length != 64 || !_isHexString(pubkey)) {
        throw ArgumentError(
          'All steward pubkeys must be valid hex format (64 characters): $pubkey',
        );
      }
      if (steward['name'] == null || steward['name']!.isEmpty) {
        throw ArgumentError('All stewards must have a non-empty name');
      }
      // contactInfo is optional, but if present, validate length
      final contactInfo = steward['contactInfo'];
      if (contactInfo != null && contactInfo.length > 500) {
        throw ArgumentError(
          'Steward contactInfo exceeds maximum length of 500 characters',
        );
      }
    }
  }

  return ShardData(
    shard: shard,
    threshold: threshold,
    shardIndex: shardIndex,
    totalShards: totalShards,
    primeMod: primeMod,
    creatorPubkey: creatorPubkey,
    createdAt: secondsSinceEpoch(),
    vaultId: vaultId,
    vaultName: vaultName,
    stewards: stewards,
    ownerName: ownerName,
    instructions: instructions,
    recipientPubkey: recipientPubkey,
    isReceived: isReceived,
    receivedAt: receivedAt,
    nostrEventId: nostrEventId,
    relayUrls: relayUrls,
    distributionVersion: distributionVersion,
    pushEnabled: pushEnabled,
  );
}

/// Nostr / wire format: snake_case keys (see project Nostr payload conventions).
Map<String, dynamic> shardDataToJson(ShardData shardData) {
  return {
    'shard': shardData.shard,
    'threshold': shardData.threshold,
    'shard_index': shardData.shardIndex,
    'total_shards': shardData.totalShards,
    'prime_mod': shardData.primeMod,
    'creator_pubkey': shardData.creatorPubkey,
    'created_at': shardData.createdAt,
    if (shardData.vaultId != null) 'vault_id': shardData.vaultId,
    if (shardData.vaultName != null) 'vault_name': shardData.vaultName,
    if (shardData.stewards != null) 'stewards': shardData.stewards,
    if (shardData.ownerName != null) 'owner_name': shardData.ownerName,
    if (shardData.instructions != null) 'instructions': shardData.instructions,
    if (shardData.recipientPubkey != null) 'recipient_pubkey': shardData.recipientPubkey,
    if (shardData.isReceived != null) 'is_received': shardData.isReceived,
    if (shardData.receivedAt != null) 'received_at': shardData.receivedAt!.toIso8601String(),
    if (shardData.nostrEventId != null) 'nostr_event_id': shardData.nostrEventId,
    if (shardData.relayUrls != null) 'relay_urls': shardData.relayUrls,
    if (shardData.distributionVersion != null)
      'distribution_version': shardData.distributionVersion,
    if (shardData.pushEnabled != null) 'push_enabled': shardData.pushEnabled,
  };
}

int _readIntFlexible(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw TypeError();
}

int? _readIntFlexibleNullable(Object? value) {
  if (value == null) return null;
  return _readIntFlexible(value);
}

bool? _readBoolNullable(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  throw TypeError();
}

/// Create from JSON (prefers snake_case; falls back to legacy camelCase for old vault files / peers).
ShardData shardDataFromJson(Map<String, dynamic> json) {
  final stewardsData = json['stewards'];

  final shardIndex = _readIntFlexible(json['shard_index'] ?? json['shardIndex']);
  final totalShards = _readIntFlexible(json['total_shards'] ?? json['totalShards']);
  final createdAt = _readIntFlexible(json['created_at'] ?? json['createdAt']);

  final receivedRaw = json['received_at'] ?? json['receivedAt'];

  return ShardData(
    shard: json['shard'] as String,
    threshold: _readIntFlexible(json['threshold']),
    shardIndex: shardIndex,
    totalShards: totalShards,
    primeMod: (json['prime_mod'] ?? json['primeMod']) as String,
    creatorPubkey: (json['creator_pubkey'] ?? json['creatorPubkey']) as String,
    createdAt: createdAt,
    vaultId: json['vault_id'] as String? ?? json['vaultId'] as String?,
    vaultName: json['vault_name'] as String? ?? json['vaultName'] as String?,
    stewards: stewardsData != null
        ? (stewardsData as List).map((e) => Map<String, String>.from(e as Map)).toList()
        : null,
    ownerName: json['owner_name'] as String? ?? json['ownerName'] as String?,
    instructions: json['instructions'] as String?,
    recipientPubkey: json['recipient_pubkey'] as String? ?? json['recipientPubkey'] as String?,
    isReceived: _readBoolNullable(json['is_received'] ?? json['isReceived']),
    receivedAt: receivedRaw != null ? DateTime.parse(receivedRaw as String) : null,
    nostrEventId: json['nostr_event_id'] as String? ?? json['nostrEventId'] as String?,
    relayUrls: json['relay_urls'] != null
        ? List<String>.from(json['relay_urls'] as List)
        : json['relayUrls'] != null
            ? List<String>.from(json['relayUrls'] as List)
            : null,
    distributionVersion: _readIntFlexibleNullable(
      json['distribution_version'] ?? json['distributionVersion'],
    ),
    pushEnabled: _readBoolNullable(json['push_enabled'] ?? json['pushEnabled']),
  );
}

/// String representation of ShardData
String shardDataToString(ShardData shardData) {
  return 'ShardData(shardIndex: ${shardData.shardIndex}/${shardData.totalShards}, '
      'threshold: ${shardData.threshold}, creator: ${shardData.creatorPubkey.substring(0, 8)}...)';
}
