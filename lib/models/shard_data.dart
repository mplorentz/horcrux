import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault.dart';
import '../services/logger.dart';

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
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unix timestamp
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
  );
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
    if (shardData.stewards != null) 'stewards': shardData.stewards,
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
  final stewardsData = json['stewards'];

  return ShardData(
    shard: json['shard'] as String,
    threshold: json['threshold'] as int,
    shardIndex: json['shardIndex'] as int,
    totalShards: json['totalShards'] as int,
    primeMod: json['primeMod'] as String,
    creatorPubkey: json['creatorPubkey'] as String,
    createdAt: json['createdAt'] as int,
    vaultId: json['vaultId'] as String?,
    vaultName: json['vaultName'] as String?,
    stewards: stewardsData != null
        ? (stewardsData as List).map((e) => Map<String, String>.from(e as Map)).toList()
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
