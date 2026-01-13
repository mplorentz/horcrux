import 'vault.dart';
import '../services/logger.dart';

/// Represents the decrypted shard data contained within a ShardEvent
///
/// This model contains the actual Shamir share data that is encrypted
/// and stored in the ShardEvent for distribution to stewards.
///
/// Extended with optional recovery metadata for vault recovery feature.
typedef ShardData = ({
  String shard,
  int threshold,
  int shardIndex,
  int totalShards,
  String primeMod,
  String creatorPubkey,
  int createdAt,
  // Recovery metadata (optional fields)
  String? vaultId,
  String? vaultName,
  List<
      Map<String,
          String>>? peers, // List of maps with 'name' and 'pubkey' for OTHER stewards (excludes creatorPubkey)
  String? ownerName, // Name of the vault owner (creator)
  String? instructions, // Instructions for stewards
  String? recipientPubkey,
  bool? isReceived,
  DateTime? receivedAt,
  String? nostrEventId,
  List<String>? relayUrls, // Relay URLs from backup config for sending confirmations
  int? distributionVersion, // Version tracking for redistribution detection (nullable for backward compatibility)
});

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
  List<Map<String, String>>? peers,
  String? ownerName,
  String? instructions,
  String? recipientPubkey,
  bool? isReceived,
  DateTime? receivedAt,
  String? nostrEventId,
  List<String>? relayUrls,
  int? distributionVersion,
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
  if (peers != null) {
    for (final peer in peers) {
      if (!peer.containsKey('name') || !peer.containsKey('pubkey')) {
        throw ArgumentError(
          'All peers must have both "name" and "pubkey" keys',
        );
      }
      final pubkey = peer['pubkey']!;
      if (pubkey.length != 64 || !_isHexString(pubkey)) {
        throw ArgumentError(
          'All peer pubkeys must be valid hex format (64 characters): $pubkey',
        );
      }
      if (peer['name'] == null || peer['name']!.isEmpty) {
        throw ArgumentError('All peers must have a non-empty name');
      }
    }
  }

  return (
    shard: shard,
    threshold: threshold,
    shardIndex: shardIndex,
    totalShards: totalShards,
    primeMod: primeMod,
    creatorPubkey: creatorPubkey,
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unix timestamp
    vaultId: vaultId,
    vaultName: vaultName,
    peers: peers,
    ownerName: ownerName,
    instructions: instructions,
    recipientPubkey: recipientPubkey,
    isReceived: isReceived,
    receivedAt: receivedAt,
    nostrEventId: nostrEventId,
    relayUrls: relayUrls,
    distributionVersion: distributionVersion,
  );
}

/// Helper to validate hex strings
bool _isHexString(String str) {
  return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
}

/// Create a copy of this ShardData with updated fields
ShardData copyShardData(
  ShardData shardData, {
  String? shard,
  int? threshold,
  int? shardIndex,
  int? totalShards,
  String? primeMod,
  String? creatorPubkey,
  int? createdAt,
  String? vaultId,
  String? vaultName,
  List<Map<String, String>>? peers,
  String? ownerName,
  String? instructions,
  String? recipientPubkey,
  bool? isReceived,
  DateTime? receivedAt,
  String? nostrEventId,
  List<String>? relayUrls,
  int? distributionVersion,
}) {
  return (
    shard: shard ?? shardData.shard,
    threshold: threshold ?? shardData.threshold,
    shardIndex: shardIndex ?? shardData.shardIndex,
    totalShards: totalShards ?? shardData.totalShards,
    primeMod: primeMod ?? shardData.primeMod,
    creatorPubkey: creatorPubkey ?? shardData.creatorPubkey,
    createdAt: createdAt ?? shardData.createdAt,
    vaultId: vaultId ?? shardData.vaultId,
    vaultName: vaultName ?? shardData.vaultName,
    peers: peers ?? shardData.peers,
    ownerName: ownerName ?? shardData.ownerName,
    instructions: instructions ?? shardData.instructions,
    recipientPubkey: recipientPubkey ?? shardData.recipientPubkey,
    isReceived: isReceived ?? shardData.isReceived,
    receivedAt: receivedAt ?? shardData.receivedAt,
    nostrEventId: nostrEventId ?? shardData.nostrEventId,
    relayUrls: relayUrls ?? shardData.relayUrls,
    distributionVersion: distributionVersion ?? shardData.distributionVersion,
  );
}

/// Extension methods for ShardData
extension ShardDataExtension on ShardData {
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

      return true;
    } catch (e) {
      Log.error('ShardData validation failed with exception', e);
      return false;
    }
  }

  /// Get the age of this shard data in seconds
  int get ageInSeconds {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
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

/// Convert to JSON for storage
Map<String, dynamic> shardDataToJson(ShardData shardData) {
  return {
    'shard': shardData.shard,
    'threshold': shardData.threshold,
    'shardIndex': shardData.shardIndex,
    'totalShards': shardData.totalShards,
    'primeMod': shardData.primeMod,
    'creatorPubkey': shardData.creatorPubkey,
    'createdAt': shardData.createdAt,
    if (shardData.vaultId != null) 'vaultId': shardData.vaultId,
    if (shardData.vaultName != null) 'vaultName': shardData.vaultName,
    if (shardData.peers != null) 'peers': shardData.peers,
    if (shardData.ownerName != null) 'ownerName': shardData.ownerName,
    if (shardData.instructions != null) 'instructions': shardData.instructions,
    if (shardData.recipientPubkey != null) 'recipientPubkey': shardData.recipientPubkey,
    if (shardData.isReceived != null) 'isReceived': shardData.isReceived,
    if (shardData.receivedAt != null) 'receivedAt': shardData.receivedAt!.toIso8601String(),
    if (shardData.nostrEventId != null) 'nostrEventId': shardData.nostrEventId,
    if (shardData.relayUrls != null) 'relayUrls': shardData.relayUrls,
    if (shardData.distributionVersion != null) 'distributionVersion': shardData.distributionVersion,
  };
}

/// Create from JSON
ShardData shardDataFromJson(Map<String, dynamic> json) {
  return (
    shard: json['shard'] as String,
    threshold: json['threshold'] as int,
    shardIndex: json['shardIndex'] as int,
    totalShards: json['totalShards'] as int,
    primeMod: json['primeMod'] as String,
    creatorPubkey: json['creatorPubkey'] as String,
    createdAt: json['createdAt'] as int,
    vaultId: json['vaultId'] as String?,
    vaultName: json['vaultName'] as String?,
    peers: json['peers'] != null
        ? (json['peers'] as List).map((e) => Map<String, String>.from(e as Map)).toList()
        : null,
    ownerName: json['ownerName'] as String?,
    instructions: json['instructions'] as String?,
    recipientPubkey: json['recipientPubkey'] as String?,
    isReceived: json['isReceived'] as bool?,
    receivedAt: json['receivedAt'] != null ? DateTime.parse(json['receivedAt'] as String) : null,
    nostrEventId: json['nostrEventId'] as String?,
    relayUrls: json['relayUrls'] != null ? List<String>.from(json['relayUrls'] as List) : null,
    distributionVersion: json['distributionVersion'] as int?,
  );
}

/// String representation of ShardData
String shardDataToString(ShardData shardData) {
  return 'ShardData(shardIndex: ${shardData.shardIndex}/${shardData.totalShards}, '
      'threshold: ${shardData.threshold}, creator: ${shardData.creatorPubkey.substring(0, 8)}...)';
}
