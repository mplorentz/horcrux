/// Enum representing the status of a steward
enum StewardStatus {
  /// Invitation sent, awaiting acceptance
  invited,

  /// Key share is being prepared for distribution OR invitation accepted, awaiting shard distribution
  awaitingKey,

  /// Steward has an old key but needs an updated one (after version increment)
  awaitingNewKey,

  /// Shard received and confirmed (steward is holding their key)
  holdingKey,

  /// Steward is unresponsive or offline
  inactive,

  /// Error occurred during invitation or shard processing
  error,

  /// Steward removed from backup configuration
  revoked,
}

/// Derives steward status from ack version vs the vault's current distribution.
///
/// Used when hydrating from DB ([VaultRepository._stewardFromRow]) and when
/// persisting kind-1342 confirmations so read and write paths stay aligned.
StewardStatus stewardStatusFromDistributionAck({
  required int? acknowledgedDistributionVersion,
  required int currentDistributionVersion,
}) {
  if (acknowledgedDistributionVersion != null &&
      acknowledgedDistributionVersion == currentDistributionVersion) {
    return StewardStatus.holdingKey;
  }
  if (acknowledgedDistributionVersion != null &&
      acknowledgedDistributionVersion < currentDistributionVersion) {
    return StewardStatus.awaitingNewKey;
  }
  return StewardStatus.awaitingKey;
}

/// Extension methods for StewardStatus
extension StewardStatusExtension on StewardStatus {
  /// Get a human-readable description of the status
  String get description {
    switch (this) {
      case StewardStatus.invited:
        return 'Invitation sent, awaiting acceptance';
      case StewardStatus.awaitingKey:
        return 'Awaiting key share distribution';
      case StewardStatus.awaitingNewKey:
        return 'Has old key, awaiting updated key share';
      case StewardStatus.holdingKey:
        return 'Steward has confirmed receipt of their key share';
      case StewardStatus.inactive:
        return 'Steward is unresponsive or offline';
      case StewardStatus.error:
        return 'Error occurred during invitation or share processing';
      case StewardStatus.revoked:
        return 'Steward has been removed from backup';
    }
  }

  /// Get a short label for the status
  String get label {
    switch (this) {
      case StewardStatus.invited:
        return 'Pending';
      case StewardStatus.awaitingKey:
        return 'Awaiting Key';
      case StewardStatus.awaitingNewKey:
        return 'Awaiting New Key';
      case StewardStatus.holdingKey:
        return 'Holding Key';
      case StewardStatus.inactive:
        return 'Inactive';
      case StewardStatus.error:
        return 'Error';
      case StewardStatus.revoked:
        return 'Revoked';
    }
  }

  /// Check if the steward is active (can participate in recovery)
  bool get isActive {
    return this == StewardStatus.awaitingKey ||
        this == StewardStatus.awaitingNewKey ||
        this == StewardStatus.holdingKey;
  }

  /// Check if the steward has confirmed receipt
  bool get hasConfirmed {
    return this == StewardStatus.holdingKey;
  }

  /// Check if the steward is available for recovery
  bool get isAvailable {
    return this == StewardStatus.awaitingKey ||
        this == StewardStatus.awaitingNewKey ||
        this == StewardStatus.holdingKey;
  }

  /// Check if the steward is problematic
  bool get isProblematic {
    return this == StewardStatus.inactive ||
        this == StewardStatus.revoked ||
        this == StewardStatus.error;
  }

  /// Check if the status is terminal (no further transitions expected)
  bool get isTerminal {
    return this == StewardStatus.holdingKey ||
        this == StewardStatus.revoked ||
        this == StewardStatus.error;
  }

  /// Get the appropriate color for UI display
  String get colorName {
    switch (this) {
      case StewardStatus.invited:
        return 'orange';
      case StewardStatus.awaitingKey:
        return 'blue';
      case StewardStatus.awaitingNewKey:
        return 'amber';
      case StewardStatus.holdingKey:
        return 'green';
      case StewardStatus.inactive:
        return 'grey';
      case StewardStatus.error:
        return 'red';
      case StewardStatus.revoked:
        return 'red';
    }
  }

  /// Get the appropriate icon name for UI display
  String get iconName {
    switch (this) {
      case StewardStatus.invited:
        return 'mail_outline';
      case StewardStatus.awaitingKey:
        return 'hourglass_empty';
      case StewardStatus.awaitingNewKey:
        return 'update';
      case StewardStatus.holdingKey:
        return 'check_circle';
      case StewardStatus.inactive:
        return 'pause_circle';
      case StewardStatus.error:
        return 'error_outline';
      case StewardStatus.revoked:
        return 'cancel';
    }
  }
}
