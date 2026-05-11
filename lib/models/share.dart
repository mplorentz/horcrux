import 'package:freezed_annotation/freezed_annotation.dart';

import 'vault.dart';
import '../services/logger.dart';
import '../utils/date_time_extensions.dart';

part 'share.freezed.dart';

/// Represents the decrypted Shamir share material contained within a share event.
///
/// Extended with optional recovery metadata for vault recovery feature.
///
/// **Wire format:** Nostr JSON uses `shard`, `shard_index`, `total_shards`, etc.
/// ([shareToJson] / [shareFromJson]). Those keys stay stable for the protocol.
@freezed
class Share with _$Share {
  const factory Share({
    /// Shamir share bytes (encoding depends on generator); Nostr key `shard`.
    required String payload,
    required int threshold,
    required int shareIndex,
    required int totalShares,
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
    // Nullable for backward compatibility: pre-push shares arrive without this
    // field, in which case receivers should preserve whatever push setting
    // their local Vault already has (don't silently flip anything). When the
    // owner re-distributes after changing the flag, the new value overrides.
    // The owner is the only party whose opinion matters here because they are
    // the one whose pubkey/IP/contact-graph leaks to the notifier.
    bool? pushEnabled,
  }) = _Share;

  const Share._();

  /// Check if this share is valid
  bool get isValid {
    try {
      if (payload.isEmpty) {
        Log.error('Share validation failed: payload is empty');
        return false;
      }

      if (threshold < VaultBackupConstraints.minThreshold) {
        Log.error(
          'Share validation failed: threshold ($threshold) is below minimum '
          '(${VaultBackupConstraints.minThreshold})',
        );
        return false;
      }

      if (threshold > totalShares) {
        Log.error(
          'Share validation failed: threshold ($threshold) exceeds totalShares ($totalShares)',
        );
        return false;
      }

      if (shareIndex < 0) {
        Log.error(
          'Share validation failed: shareIndex ($shareIndex) is negative',
        );
        return false;
      }

      if (shareIndex >= totalShares) {
        Log.error(
          'Share validation failed: shareIndex ($shareIndex) is out of bounds (should be 0 to ${totalShares - 1})',
        );
        return false;
      }

      if (primeMod.isEmpty) {
        Log.error('Share validation failed: primeMod is empty');
        return false;
      }

      if (creatorPubkey.isEmpty) {
        Log.error('Share validation failed: creatorPubkey is empty');
        return false;
      }

      if (createdAt <= 0) {
        Log.error(
          'Share validation failed: createdAt ($createdAt) is invalid (must be > 0)',
        );
        return false;
      }

      // Validate stewards if provided
      if (stewards != null) {
        for (final steward in stewards!) {
          if (!steward.containsKey('name') || !steward.containsKey('pubkey')) {
            Log.error(
              'Share validation failed: All stewards must have both "name" and "pubkey" keys',
            );
            return false;
          }
          final pubkey = steward['pubkey']!;
          if (pubkey.length != 64 || !_isHexString(pubkey)) {
            Log.error(
              'Share validation failed: All steward pubkeys must be valid hex format (64 characters): $pubkey',
            );
            return false;
          }
          if (steward['name'] == null || steward['name']!.isEmpty) {
            Log.error('Share validation failed: All stewards must have a non-empty name');
            return false;
          }
          // contactInfo is optional, but if present, validate length
          final contactInfo = steward['contactInfo'];
          if (contactInfo != null && contactInfo.length > 500) {
            Log.error(
              'Share validation failed: Steward contactInfo exceeds maximum length of 500 characters',
            );
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      Log.error('Share validation failed with exception', e);
      return false;
    }
  }

  /// Get the age of this share in seconds
  int get ageInSeconds {
    final now = secondsSinceEpoch();
    return now - createdAt;
  }

  /// Get the age of this share in hours
  double get ageInHours {
    return ageInSeconds / 3600.0;
  }

  /// Check if this share is recent (less than 24 hours old)
  bool get isRecent {
    return ageInHours < 24.0;
  }
}

/// Returns the most-recently-distributed share from [shares], or null when the
/// list is empty.
///
/// Selection order:
/// 1. Higher [Share.distributionVersion] wins (null treated as -1 so that
///    unversioned/legacy shares sort before any explicitly-versioned share).
/// 2. Higher [Share.createdAt] (Unix seconds) breaks ties within the same
///    version.
///
/// This is the single authoritative implementation of the "pick most recent
/// share" policy.  All call sites in [VaultShareService] and [RecoveryService]
/// delegate here rather than re-implementing the reduce inline.
Share? latestShare(List<Share> shares) {
  if (shares.isEmpty) return null;
  return shares.reduce((current, next) {
    final cv = current.distributionVersion ?? -1;
    final nv = next.distributionVersion ?? -1;
    if (cv != nv) return nv > cv ? next : current;
    return next.createdAt > current.createdAt ? next : current;
  });
}

/// Helper to validate hex strings
bool _isHexString(String str) {
  return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
}

/// Create a new [Share] with validation
Share createShare({
  required String payload,
  required int threshold,
  required int shareIndex,
  required int totalShares,
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
  if (payload.isEmpty) {
    throw ArgumentError('Share payload cannot be empty');
  }
  if (threshold < VaultBackupConstraints.minThreshold || threshold > totalShares) {
    throw ArgumentError(
      'Threshold must be >= ${VaultBackupConstraints.minThreshold} and <= totalShares',
    );
  }
  if (shareIndex < 0 || shareIndex >= totalShares) {
    throw ArgumentError('shareIndex must be >= 0 and < totalShares');
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

  return Share(
    payload: payload,
    threshold: threshold,
    shareIndex: shareIndex,
    totalShares: totalShares,
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

/// Nostr / wire format: snake_case keys; Shamir material remains `shard`,
/// indexes remain `shard_*` / `total_shards` per protocol stability.
Map<String, dynamic> shareToJson(Share share) {
  return {
    'shard': share.payload,
    'threshold': share.threshold,
    'shard_index': share.shareIndex,
    'total_shards': share.totalShares,
    'prime_mod': share.primeMod,
    'creator_pubkey': share.creatorPubkey,
    'created_at': share.createdAt,
    if (share.vaultId != null) 'vault_id': share.vaultId,
    if (share.vaultName != null) 'vault_name': share.vaultName,
    if (share.stewards != null) 'stewards': share.stewards,
    if (share.ownerName != null) 'owner_name': share.ownerName,
    if (share.instructions != null) 'instructions': share.instructions,
    if (share.recipientPubkey != null) 'recipient_pubkey': share.recipientPubkey,
    if (share.isReceived != null) 'is_received': share.isReceived,
    if (share.receivedAt != null) 'received_at': share.receivedAt!.toIso8601String(),
    if (share.nostrEventId != null) 'nostr_event_id': share.nostrEventId,
    if (share.relayUrls != null) 'relay_urls': share.relayUrls,
    if (share.distributionVersion != null) 'distribution_version': share.distributionVersion,
    if (share.pushEnabled != null) 'push_enabled': share.pushEnabled,
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

/// Create from JSON (Nostr / wire format: snake_case keys per project conventions).
Share shareFromJson(Map<String, dynamic> json) {
  final stewardsData = json['stewards'];

  final shareIndex = _readIntFlexible(json['shard_index']);
  final totalShares = _readIntFlexible(json['total_shards']);
  final createdAt = _readIntFlexible(json['created_at']);

  final receivedRaw = json['received_at'];

  return Share(
    payload: json['shard'] as String,
    threshold: _readIntFlexible(json['threshold']),
    shareIndex: shareIndex,
    totalShares: totalShares,
    primeMod: json['prime_mod'] as String,
    creatorPubkey: json['creator_pubkey'] as String,
    createdAt: createdAt,
    vaultId: json['vault_id'] as String?,
    vaultName: json['vault_name'] as String?,
    stewards: stewardsData != null
        ? (stewardsData as List).map((e) => Map<String, String>.from(e as Map)).toList()
        : null,
    ownerName: json['owner_name'] as String?,
    instructions: json['instructions'] as String?,
    recipientPubkey: json['recipient_pubkey'] as String?,
    isReceived: _readBoolNullable(json['is_received']),
    receivedAt: receivedRaw != null ? DateTime.parse(receivedRaw as String) : null,
    nostrEventId: json['nostr_event_id'] as String?,
    relayUrls: json['relay_urls'] != null ? List<String>.from(json['relay_urls'] as List) : null,
    distributionVersion: _readIntFlexibleNullable(
      json['distribution_version'],
    ),
    pushEnabled: _readBoolNullable(json['push_enabled']),
  );
}

/// String representation of [Share]
String shareToString(Share share) {
  return 'Share(shareIndex: ${share.shareIndex}/${share.totalShares}, '
      'threshold: ${share.threshold}, creator: ${share.creatorPubkey.substring(0, 8)}...)';
}
