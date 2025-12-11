import '../utils/validators.dart';
import 'steward_status.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Represents a trusted contact who holds a backup key
///
/// This model contains information about a steward including
/// their Nostr public key, status, and acknowledgment details.
typedef Steward = ({
  String id, // Unique identifier for this steward
  String? pubkey, // Hex format - nullable for invited stewards
  String? name,
  String? inviteCode, // Invitation code for invited stewards (before they accept)
  StewardStatus status,
  DateTime? lastSeen,
  String? keyShare,
  String? giftWrapEventId,
  DateTime? acknowledgedAt,
  String? acknowledgmentEventId,
  int? acknowledgedDistributionVersion, // Version tracking for redistribution detection (nullable for backward compatibility)
  bool isOwner, // True when this steward is the vault owner
});

/// Create a new Steward with validation
Steward createSteward({
  required String pubkey, // Takes hex format directly
  String? name,
  String? id, // Optional - will be generated if not provided
  bool isOwner = false,
}) {
  if (!isValidHexPubkey(pubkey)) {
    throw ArgumentError('Invalid hex pubkey format: $pubkey');
  }

  return (
    id: id ?? _uuid.v4(),
    pubkey: pubkey,
    name: name,
    inviteCode: null,
    status: StewardStatus.awaitingKey,
    lastSeen: null,
    keyShare: null,
    giftWrapEventId: null,
    acknowledgedAt: null,
    acknowledgmentEventId: null,
    acknowledgedDistributionVersion: null,
    isOwner: isOwner,
  );
}

/// Create a new Steward for the vault owner (convenience factory)
Steward createOwnerSteward({
  required String pubkey, // Takes hex format directly
  String? name,
  String? id, // Optional - will be generated if not provided
}) {
  return createSteward(pubkey: pubkey, name: name ?? 'You', id: id, isOwner: true);
}

/// Create a new Steward for an invited person (no pubkey yet)
Steward createInvitedSteward({
  required String name,
  required String inviteCode,
  String? id, // Optional - will be generated if not provided
}) {
  return (
    id: id ?? _uuid.v4(),
    pubkey: null,
    name: name,
    inviteCode: inviteCode,
    status: StewardStatus.invited,
    lastSeen: null,
    keyShare: null,
    giftWrapEventId: null,
    acknowledgedAt: null,
    acknowledgmentEventId: null,
    acknowledgedDistributionVersion: null,
    isOwner: false,
  );
}

/// Create a copy of this Steward with updated fields
Steward copySteward(
  Steward steward, {
  String? id,
  String? pubkey, // Hex format
  String? name,
  String? inviteCode,
  StewardStatus? status,
  DateTime? lastSeen,
  String? keyShare,
  String? giftWrapEventId,
  DateTime? acknowledgedAt,
  String? acknowledgmentEventId,
  int? acknowledgedDistributionVersion,
  bool? isOwner,
}) {
  return (
    id: id ?? steward.id,
    pubkey: pubkey ?? steward.pubkey,
    name: name ?? steward.name,
    inviteCode: inviteCode ?? steward.inviteCode,
    status: status ?? steward.status,
    lastSeen: lastSeen ?? steward.lastSeen,
    keyShare: keyShare ?? steward.keyShare,
    giftWrapEventId: giftWrapEventId ?? steward.giftWrapEventId,
    acknowledgedAt: acknowledgedAt ?? steward.acknowledgedAt,
    acknowledgmentEventId: acknowledgmentEventId ?? steward.acknowledgmentEventId,
    acknowledgedDistributionVersion:
        acknowledgedDistributionVersion ?? steward.acknowledgedDistributionVersion,
    isOwner: isOwner ?? steward.isOwner,
  );
}

/// Extension methods for Steward
extension StewardExtension on Steward {
  /// Check if this steward is active
  bool get isActive {
    return status == StewardStatus.awaitingKey ||
        status == StewardStatus.awaitingNewKey ||
        status == StewardStatus.holdingKey;
  }

  /// Check if this steward has acknowledged receipt
  bool get hasAcknowledged {
    return status == StewardStatus.holdingKey && acknowledgedAt != null;
  }

  /// Check if this steward is responsive (seen recently)
  bool get isResponsive {
    if (lastSeen == null) return false;
    final now = DateTime.now();
    final timeSinceLastSeen = now.difference(lastSeen!);
    return timeSinceLastSeen.inHours < 24; // Consider responsive if seen within 24 hours
  }

  /// Check if this steward is invited (no pubkey yet)
  bool get isInvited {
    return status == StewardStatus.invited && pubkey == null;
  }

  /// Get the bech32-encoded npub for display
  String? get npub {
    if (pubkey == null) return null;
    // pubkey is already in hex format without 0x prefix (Nostr convention)
    return Helpers.encodeBech32(pubkey!, 'npub');
  }

  /// Get display name (name if available, otherwise truncated npub)
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    // For invited stewards without a real pubkey, show "Pending"
    if (isInvited) {
      return 'Pending';
    }
    final displayNpub = npub;
    if (displayNpub == null) {
      return 'Unknown';
    }
    return '${displayNpub.substring(0, 8)}...${displayNpub.substring(displayNpub.length - 8)}';
  }

  /// Get display subtitle (npub for real stewards, status for invited)
  String get displaySubtitle {
    if (isInvited) {
      return 'Pending';
    }
    return npub ?? 'No pubkey';
  }
}

/// Convert to JSON for storage
Map<String, dynamic> stewardToJson(Steward steward) {
  return {
    'id': steward.id,
    'pubkey': steward.pubkey, // Store hex format, nullable
    'name': steward.name,
    'inviteCode': steward.inviteCode,
    'status': steward.status.name,
    'lastSeen': steward.lastSeen?.toIso8601String(),
    'keyShare': steward.keyShare,
    'giftWrapEventId': steward.giftWrapEventId,
    'acknowledgedAt': steward.acknowledgedAt?.toIso8601String(),
    'acknowledgmentEventId': steward.acknowledgmentEventId,
    'acknowledgedDistributionVersion': steward.acknowledgedDistributionVersion,
    'isOwner': steward.isOwner,
  };
}

/// Create from JSON
Steward stewardFromJson(Map<String, dynamic> json) {
  return (
    id: json['id'] as String? ?? _uuid.v4(), // Generate ID if missing for backward compatibility
    pubkey: json['pubkey'] as String?, // Hex format without 0x prefix, nullable
    name: json['name'] as String?,
    inviteCode: json['inviteCode'] as String?, // Nullable for backward compatibility
    status: StewardStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => StewardStatus.awaitingKey,
    ),
    lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen'] as String) : null,
    keyShare: json['keyShare'] as String?,
    giftWrapEventId: json['giftWrapEventId'] as String?,
    acknowledgedAt:
        json['acknowledgedAt'] != null ? DateTime.parse(json['acknowledgedAt'] as String) : null,
    acknowledgmentEventId: json['acknowledgmentEventId'] as String?,
    acknowledgedDistributionVersion: json['acknowledgedDistributionVersion'] as int?,
    isOwner: json['isOwner'] as bool? ?? false, // Default to false for backward compatibility
  );
}

/// String representation of Steward
String stewardToString(Steward steward) {
  final pubkeyPreview = steward.pubkey != null ? '${steward.pubkey!.substring(0, 8)}...' : 'null';
  return 'Steward(id: ${steward.id}, pubkey: $pubkeyPreview, name: ${steward.name}, status: ${steward.status})';
}
