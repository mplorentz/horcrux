/// Nostr event kinds used in Horcrux
///
/// This enum defines all Nostr event kinds used throughout the application.
/// Standard NIP kinds and custom kinds for Horcrux-specific functionality.
enum NostrKind {
  /// NIP-59: Seal event
  /// Used as the inner layer of gift wraps for encryption
  seal(13),

  /// NIP-59: Gift wrap event
  /// Used for private, encrypted messages with sender anonymity
  giftWrap(1059),

  /// Horcrux custom: Shard data distribution
  /// Used to distribute Shamir secret shares to stewards
  shardData(1337),

  /// Horcrux custom: Recovery request
  /// Used when a user initiates vault recovery
  recoveryRequest(1338),

  /// Horcrux custom: Recovery response
  /// Used when a steward responds to a recovery request
  recoveryResponse(1339),

  /// Horcrux custom: Invitation Acceptance
  /// Used when an invitee accepts an invitation link
  invitationAcceptance(1340),

  /// Horcrux custom: Invitation denial
  /// Used when an invitee denies an invitation link
  invitationDenial(1341),

  /// Horcrux custom: Shard confirmation
  /// Used when a steward confirms successful receipt of a shard
  shardConfirmation(1342),

  /// Horcrux custom: Shard error
  /// Used when a steward reports an error processing a shard
  shardError(1343),

  /// Horcrux custom: Invitation invalid
  /// Used to notify invitee that an invitation code is invalid
  invitationInvalid(1344),

  /// Horcrux custom: Key holder removed
  /// Used to notify a steward when they are removed from a backup config
  keyHolderRemoved(1345);

  /// The numeric kind value
  final int value;

  const NostrKind(this.value);

  /// Get NostrKind from an integer value
  static NostrKind? fromValue(int value) {
    for (final kind in NostrKind.values) {
      if (kind.value == value) {
        return kind;
      }
    }
    return null;
  }

  /// Check if this kind is a Horcrux custom kind
  bool get isCustom {
    return value >= 1337 && value <= 1345;
  }

  /// Check if this kind is a standard NIP kind
  bool get isStandard {
    return !isCustom;
  }

  @override
  String toString() {
    return 'NostrKind.$name($value)';
  }
}

/// Extension to easily convert NostrKind to int for NDK usage
extension NostrKindExtension on NostrKind {
  /// Convert to int for use in NDK filters and events
  int toInt() => value;
}
