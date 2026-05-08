import 'package:freezed_annotation/freezed_annotation.dart';

import 'backup_config.dart';
import 'recovery_request.dart';
import 'shard_data.dart';

part 'vault.freezed.dart';

/// Backup configuration constraints
class VaultBackupConstraints {
  /// Minimum threshold value for Shamir's Secret Sharing
  static const int minThreshold = 1;

  /// Maximum number of total keys/shards for backup distribution
  static const int maxTotalKeys = 10;

  /// Default threshold value for new backups
  static const int defaultThreshold = 2;

  /// Default total keys value for new backups
  static const int defaultTotalKeys = 3;
}

/// Local vault material state for the current device (not who owns the vault).
///
/// - [unlocked]: decrypted vault content is present locally.
/// - [holdingShard]: at least one shard is stored locally but content is not decrypted.
/// - [awaitingShard]: no local content and no shards yet (e.g. invite accepted, shard not received).
enum VaultState {
  unlocked,
  holdingShard,
  awaitingShard,
}

/// Data model for a secure vault containing encrypted text content
///
/// **Archival:** archived state is defined only by [archivedAt] (and optional
/// [archivedReason]). Use [isArchived] as a convenience read for
/// `archivedAt != null`.
@freezed
class Vault with _$Vault {
  const factory Vault({
    required String id,
    required String name,
    String? content, // Nullable - null when content is not decrypted
    required DateTime createdAt,
    required String ownerPubkey, // Hex format, 64 characters
    String? ownerName, // Name of the vault owner
    @Default([])
    List<ShardData> shards, // List of shards (single as steward, multiple during recovery)
    @Default([]) List<RecoveryRequest> recoveryRequests, // Embedded recovery requests
    BackupConfig? backupConfig, // Optional backup configuration
    DateTime? archivedAt, // When the vault was archived
    String? archivedReason, // Reason for archiving
    // Whether the vault owner has opted this vault into push notifications.
    //
    // This is independent of the per-user global opt-in (see
    // `PushNotificationReceiver.optInFlagKey`): a user who has never opted
    // into push notifications will simply never send or receive any, even
    // for vaults where `pushEnabled` is `true`.
    //
    // Defaults to `true` for newly-created vaults (set on the recovery plan
    // screen) and `false` for vaults persisted before this field existed --
    // legacy vaults stay off until the owner explicitly turns push on.
    @Default(true) bool pushEnabled,
  }) = _Vault;

  const Vault._();

  /// True when this vault is archived (see [archivedAt]).
  bool get isArchived => archivedAt != null;

  /// Derives [VaultState] from locally stored content and shards (see [VaultState]).
  ///
  /// Recovery state is user-specific (only for the initiator) and should be checked with
  /// [recoveryStatusProvider], not here.
  VaultState get state {
    if (content != null) {
      return VaultState.unlocked;
    }
    if (shards.isNotEmpty) {
      return VaultState.holdingShard;
    }
    return VaultState.awaitingShard;
  }

  /// Whether [hexPubkey] (hex-encoded Nostr public key) is this vault's owner.
  bool isVaultOwner(String hexPubkey) => ownerPubkey == hexPubkey;

  /// Check if we are a steward for this vault (have shards)
  bool get isSteward => shards.isNotEmpty;

  /// Get the most recent shard from this vault's shards.
  /// Returns null if there are no shards.
  /// Prefers shards with higher distributionVersion, then newer createdAt timestamp.
  ShardData? get mostRecentShard {
    if (shards.isEmpty) {
      return null;
    }
    return shards.reduce((current, next) {
      // Compare distributionVersion (null treated as -1, meaning older)
      final currentVersion = current.distributionVersion ?? -1;
      final nextVersion = next.distributionVersion ?? -1;

      if (currentVersion != nextVersion) {
        return nextVersion > currentVersion ? next : current;
      }

      return next.createdAt > current.createdAt ? next : current;
    });
  }

  /// Check if this vault has an active recovery request
  bool get hasActiveRecovery {
    return recoveryRequests.any((request) => request.status.isActive);
  }

  /// Get the active recovery request if one exists
  RecoveryRequest? get activeRecoveryRequest {
    try {
      return recoveryRequests.firstWhere((request) => request.status.isActive);
    } catch (e) {
      return null;
    }
  }

  /// Return the recovery request the given user is currently entitled to manage
  /// from this vault, or null. "Manageable" mirrors `recoveryStatusProvider`:
  /// any in-flight status (`isActive`) plus `completed`, since users finalize a
  /// recovery from the same Manage screen once enough stewards have approved.
  ///
  /// Pass [isPractice] to filter to real (`false`) or practice (`true`) sessions
  /// only; leave it null to match either kind. Per-user exclusivity guarantees
  /// at most one match per (kind), so callers do not need to disambiguate.
  ///
  /// This intentionally does NOT consult the most-recent request on the vault
  /// (as `recoveryStatusProvider` does) because in multi-initiator scenarios
  /// that representative may belong to another user, hiding the current user's
  /// own manageable session.
  RecoveryRequest? manageableRecoveryFor(String? pubkey, {bool? isPractice}) {
    if (pubkey == null) return null;
    for (final r in recoveryRequests) {
      if (r.initiatorPubkey != pubkey) continue;
      if (!(r.status.isActive || r.status == RecoveryRequestStatus.completed)) {
        continue;
      }
      if (isPractice != null && r.isPractice != isPractice) continue;
      return r;
    }
    return null;
  }

  /// Create a copy with content explicitly cleared (set to null)
  /// This preserves shards, backup config, and other data
  Vault copyWithContentDeleted() {
    return copyWith(content: null); // Explicitly clear content
  }
}
