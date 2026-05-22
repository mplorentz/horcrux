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

  /// NIP-98: HTTP Auth
  /// Used to authenticate HTTP requests by signing an ephemeral event
  /// whose pubkey is the authenticated principal. Attached to the request
  /// as `Authorization: Nostr <base64>`.
  httpAuth(27235),

  /// Horcrux custom: Share distribution (Nostr kind 713; internal name only).
  /// Used to distribute Shamir secret shares to stewards
  shareData(713),

  /// Horcrux custom: Recovery request
  /// Used when a user initiates vault recovery
  recoveryRequest(714),

  /// Horcrux custom: Recovery response
  /// Used when a steward responds to a recovery request
  recoveryResponse(715),

  /// Horcrux custom: Invitation Acceptance
  /// Used when an invitee accepts an invitation link
  invitationAcceptance(716),

  /// Horcrux custom: Invitation denial
  /// Used when an invitee denies an invitation link
  invitationDenial(717),

  /// Horcrux custom: Share confirmation (kind 718).
  /// Used when a steward confirms successful receipt of share material
  shareConfirmation(718),

  /// Horcrux custom: Share error (kind 719).
  /// Used when a steward reports an error processing share material
  shareError(719),

  /// Horcrux custom: Invitation invalid
  /// Used to notify invitee that an invitation code is invalid
  invitationInvalid(720),

  /// Horcrux custom: Key holder removed
  /// Used to notify a steward when they are removed from a backup config
  keyHolderRemoved(721);

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
    return value >= 713 && value <= 721;
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
