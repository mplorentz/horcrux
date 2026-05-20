import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ndk/ndk.dart';

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

  /// Wire-level "manifest-only" 1337: empty Shamir payload.
  ///
  /// Used when the owner is not a self-steward so relays can still carry a
  /// gift-wrapped recovery-plan snapshot to the owner's pubkey. A manifest
  /// share has empty content (the Nostr rumor content is ''), while real
  /// shares carry the raw Shamir payload as the rumor content.
  bool get isManifest => payload.isEmpty;

  /// Check if this share is valid
  bool get isValid {
    try {
      if (payload.isEmpty && !isManifest) {
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

      if (!isManifest && shareIndex < 0) {
        Log.error(
          'Share validation failed: shareIndex ($shareIndex) is negative',
        );
        return false;
      }

      if (isManifest && shareIndex != -1) {
        Log.error(
          'Share validation failed: manifest shares must use shareIndex -1 (got $shareIndex)',
        );
        return false;
      }

      if (!isManifest && shareIndex >= totalShares) {
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
          final shardSlot = steward['shard_index'];
          if (shardSlot != null && shardSlot.isNotEmpty) {
            final parsed = int.tryParse(shardSlot);
            if (parsed == null || parsed < 0) {
              Log.error(
                'Share validation failed: steward shard_index must be a non-negative int string',
              );
              return false;
            }
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
/// 2. When versions tie: if **both** shares have [Share.receivedAt], prefer the
///    later one (steward `held_shares` hydration often gives every row the same
///    [Share.createdAt] from the vault row, while [Share.receivedAt] is local
///    ingest time). If either side lacks `receivedAt`, compare [Share.createdAt]
///    only — do not prefer one-sided `receivedAt` over a higher wire
///    `created_at`.
/// 3. When both `receivedAt` are present but equal, use [Share.createdAt] as the
///    tie-breaker (Unix seconds).
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

    final cr = current.receivedAt;
    final nr = next.receivedAt;
    if (cr != null && nr != null) {
      if (cr.isAfter(nr)) return current;
      if (nr.isAfter(cr)) return next;
    }

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
      final shardSlot = steward['shard_index'];
      if (shardSlot != null && shardSlot.isNotEmpty) {
        final parsed = int.tryParse(shardSlot);
        if (parsed == null || parsed < 0) {
          throw ArgumentError('steward shard_index must be a non-negative int string');
        }
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

/// Normalizes embedded steward objects from wire JSON (mixed snake_case /
/// camelCase keys; numeric fields; optional ids) into [Share.stewards] maps.
///
/// Entries missing a non-empty name or pubkey are skipped (same practical
/// requirement as [Share.isValid]).
List<Map<String, String>>? _embeddedStewardMapsFromWire(Object? stewardsData) {
  if (stewardsData == null) return null;
  if (stewardsData is! List) return null;

  String? pickStr(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString();
      if (s.isEmpty) continue;
      return s;
    }
    return null;
  }

  final out = <Map<String, String>>[];
  for (final item in stewardsData) {
    if (item is! Map) continue;
    final m = Map<String, dynamic>.from(item);
    final name = pickStr(m, ['name']);
    final pubkey = pickStr(m, ['pubkey', 'pubKey']);
    if (name == null || pubkey == null) continue;

    final row = <String, String>{'name': name, 'pubkey': pubkey};
    final id = pickStr(m, ['id']);
    if (id != null) row['id'] = id;
    final contactInfo = pickStr(m, ['contact_info', 'contactInfo', 'contact']);
    if (contactInfo != null) row['contactInfo'] = contactInfo;
    final shardSlot = pickStr(m, ['shard_index', 'shardIndex']);
    if (shardSlot != null) row['shard_index'] = shardSlot;
    out.add(row);
  }
  return out.isEmpty ? null : out;
}

/// Create from JSON (Nostr / wire format: snake_case keys per project conventions).
Share shareFromJson(Map<String, dynamic> json) {
  final stewardsData = json['stewards'];

  final shareIndex = _readIntFlexible(json['shard_index']);
  final totalShares = _readIntFlexible(json['total_shards']);
  final createdAt = _readIntFlexible(json['created_at']);

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
    stewards: _embeddedStewardMapsFromWire(stewardsData),
    ownerName: json['owner_name'] as String?,
    instructions: json['instructions'] as String?,
    recipientPubkey: json['recipient_pubkey'] as String?,
    isReceived: _readBoolNullable(json['is_received']),
    receivedAt: json['received_at'] != null
        ? DateTime.parse(json['received_at'] as String)
        : null,
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

// ---------------------------------------------------------------------------
// Nostr wire format (canonical tag-based format)
// ---------------------------------------------------------------------------

/// Converts a steward map to a Nostr tag list entry.
///
/// Format: ["steward", "<slot>", "<name>", "<pubkey>", "<contact_info>"]
/// When [slot] is null or empty, the slot position is omitted (legacy compat).
List<String> stewardToNostrTag(Map<String, String> steward, {String? slot}) {
  final tag = <String>['steward'];
  if (slot != null && slot.isNotEmpty) {
    tag.add(slot);
  }
  tag.add(steward['name'] ?? '');
  tag.add(steward['pubkey'] ?? '');
  tag.add(steward['contactInfo'] ?? '');
  return tag;
}

/// Produces the Nostr rumor tag list for a [Share].
///
/// The content field should be set via [shareToNostrContent].
/// creatorPubkey comes from rumor.pubKey (set by caller).
/// recipientPubkey comes from gift wrap p-tag (set by caller).
List<List<String>> shareToNostrTags(Share share) {
  final tags = <List<String>>[];

  tags.add(['share_index', share.shareIndex.toString()]);
  tags.add(['total_shares', share.totalShares.toString()]);
  tags.add(['threshold', share.threshold.toString()]);
  tags.add(['prime_mod', share.primeMod]);

  if (share.vaultId != null && share.vaultId!.isNotEmpty) {
    tags.add(['vault_id', share.vaultId!]);
  }
  if (share.vaultName != null && share.vaultName!.isNotEmpty) {
    tags.add(['vault_name', share.vaultName!]);
  }
  if (share.ownerName != null && share.ownerName!.isNotEmpty) {
    tags.add(['owner_name', share.ownerName!]);
  }
  if (share.instructions != null && share.instructions!.isNotEmpty) {
    tags.add(['instructions', share.instructions!]);
  }
  if (share.distributionVersion != null) {
    tags.add(['distribution_version', share.distributionVersion.toString()]);
  }
  if (share.pushEnabled != null) {
    tags.add(['push_enabled', share.pushEnabled.toString()]);
  }

  // Repeated steward tags
  if (share.stewards != null) {
    for (int i = 0; i < share.stewards!.length; i++) {
      tags.add(stewardToNostrTag(share.stewards![i], slot: i.toString()));
    }
  }

  // Repeated relay tags
  if (share.relayUrls != null) {
    for (final url in share.relayUrls!) {
      tags.add(['relay', url]);
    }
  }

  return tags;
}

/// Returns the Nostr rumor content string for a [Share].
///
/// For a normal share, this is the raw Shamir payload.
/// For a manifest share (no local self-steward), this is empty string.
String shareToNostrContent(Share share) {
  return share.isManifest ? '' : share.payload;
}

/// Builds a [Share] from a Nostr rumor's tags and content.
///
/// [rumor] is the unwrapped inner event (not the gift wrap).
/// The rumor's pubKey becomes [Share.creatorPubkey].
/// The rumor's content is the raw Shamir payload (or empty for manifest).
/// [recipientPubkey] is extracted from the gift wrap p-tag and passed
/// separately since it is not in the rumor itself.
Share shareFromNostr(Nip01Event rumor, {String? recipientPubkey}) {
  // Helper: read first value of a tag by name
  String? tagValue(String name) {
    for (final tag in rumor.tags) {
      if (tag.isNotEmpty && tag[0] == name && tag.length >= 2) return tag[1];
    }
    return null;
  }

  // Helper: read all values of a repeated tag by name
  List<List<String>> tagValues(String name) {
    return rumor.tags
        .where((t) => t.isNotEmpty && t[0] == name && t.length >= 2)
        .map((t) => t.sublist(1))
        .toList();
  }

  final shareIndexStr = tagValue('share_index');
  final totalSharesStr = tagValue('total_shares');
  final thresholdStr = tagValue('threshold');
  final primeMod = tagValue('prime_mod');

  // Parse steward tags: ["steward", "<slot>", "<name>", "<pubkey>", "<contact_info>"]
  final stewardTagLists = tagValues('steward');
  List<Map<String, String>>? stewards;
  if (stewardTagLists.isNotEmpty) {
    stewards = [];
    for (final parts in stewardTagLists) {
      final map = <String, String>{};
      // parts[0] is the slot (numeric index)
      // parts[1] is the name
      // parts[2] is the pubkey
      // parts[3] is contactInfo (optional)
      if (parts.length >= 2 && parts[1].isNotEmpty) {
        map['name'] = parts[1];
      }
      if (parts.length >= 3 && parts[2].isNotEmpty) {
        map['pubkey'] = parts[2];
      }
      // Only add if we have both name and pubkey
      if (map.containsKey('name') && map.containsKey('pubkey')) {
        if (parts.length >= 4 && parts[3].isNotEmpty) {
          map['contactInfo'] = parts[3];
        }
        stewards.add(map);
      }
    }
    if (stewards.isEmpty) stewards = null;
  }

  // Parse relay tags: ["relay", "<url>"]
  final relayTagLists = tagValues('relay');
  List<String>? relayUrls;
  if (relayTagLists.isNotEmpty) {
    relayUrls = relayTagLists.map((parts) => parts[0]).toList();
  }

  final distributionVersionStr = tagValue('distribution_version');
  final pushEnabledStr = tagValue('push_enabled');

  final content = rumor.content;
  final shareIndex = shareIndexStr != null ? int.tryParse(shareIndexStr) ?? 0 : 0;
  final totalShares = totalSharesStr != null ? int.tryParse(totalSharesStr) ?? 1 : 1;
  final threshold = thresholdStr != null ? int.tryParse(thresholdStr) ?? 1 : 1;

  return Share(
    payload: content,
    threshold: threshold,
    shareIndex: shareIndex,
    totalShares: totalShares,
    primeMod: primeMod ?? '',
    creatorPubkey: rumor.pubKey,
    createdAt: rumor.createdAt,
    vaultId: tagValue('vault_id'),
    vaultName: tagValue('vault_name'),
    stewards: stewards,
    ownerName: tagValue('owner_name'),
    instructions: tagValue('instructions'),
    recipientPubkey: recipientPubkey,
    relayUrls: relayUrls,
    distributionVersion:
        distributionVersionStr != null ? int.tryParse(distributionVersionStr) : null,
    pushEnabled: pushEnabledStr != null ? pushEnabledStr == 'true' : null,
  );
}
