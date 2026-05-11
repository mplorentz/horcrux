import 'package:freezed_annotation/freezed_annotation.dart';

import 'backup_config.dart';
import 'recovery_request.dart';

part 'vault.freezed.dart';

/// Backup configuration constraints
class VaultBackupConstraints {
  /// Minimum threshold value for Shamir's Secret Sharing
  static const int minThreshold = 1;

  /// Maximum number of total keys / shares for backup distribution
  static const int maxTotalKeys = 10;

  /// Default threshold value for new backups
  static const int defaultThreshold = 2;

  /// Default total keys value for new backups
  static const int defaultTotalKeys = 3;
}

/// Local vault material state for the current device (not who owns the vault).
///
/// **Phase 6 note**: This enum will be dropped when all UI sites migrate to
/// pattern-matching on [VaultDetail]. Until then, [VaultDetail.state] exposes
/// it for incremental migration.
///
/// - [unlocked]: this device owns the vault (OwnedVaultDetail).
/// - [holdingShare]: this device holds a steward share (StewardedVaultDetail
///   with a non-null latestShare).
/// - [awaitingShare]: invite accepted but share not yet received
///   (StewardedVaultDetail with latestShare == null).
enum VaultState {
  unlocked,
  holdingShare,
  awaitingShare,
}

/// Shared data model for a vault entry on the current device.
///
/// **Phase 2c**: [content] and [shares] have been removed. Role-specific data
/// (vault content for owners, held share for stewards) now lives exclusively
/// in [VaultDetail] (see [vaultDetailProvider]).
///
/// **Archival:** archived state is defined only by [archivedAt] (and optional
/// [archivedReason]). Use [isArchived] as a convenience for
/// `archivedAt != null`.
@freezed
class Vault with _$Vault {
  const factory Vault({
    required String id,
    required String name,
    required DateTime createdAt,
    required String ownerPubkey,
    String? ownerName,
    @Default([]) List<RecoveryRequest> recoveryRequests,
    BackupConfig? backupConfig,
    DateTime? archivedAt,
    String? archivedReason,
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

  /// Whether [hexPubkey] (hex-encoded Nostr public key) is this vault's owner.
  bool isVaultOwner(String hexPubkey) => ownerPubkey == hexPubkey;

  /// True when at least one recovery request is active.
  bool get hasActiveRecovery {
    return recoveryRequests.any((request) => request.status.isActive);
  }

  /// The active recovery request if one exists, else null.
  RecoveryRequest? get activeRecoveryRequest {
    try {
      return recoveryRequests.firstWhere((request) => request.status.isActive);
    } catch (e) {
      return null;
    }
  }

  /// Returns the most recent manageable [RecoveryRequest] for [pubkey].
  ///
  /// "Manageable" means any in-flight status (`isActive`) plus `completed`.
  /// Pass [isPractice] to limit to one kind; omit to return the newer of the
  /// two kinds. Returns null when no manageable request exists.
  RecoveryRequest? manageableRecoveryFor(String? pubkey, {bool? isPractice}) {
    if (pubkey == null) return null;
    if (isPractice != null) {
      return _manageableRecoveryForKind(pubkey, isPractice);
    }
    final real = _manageableRecoveryForKind(pubkey, false);
    final practice = _manageableRecoveryForKind(pubkey, true);
    if (real == null) return practice;
    if (practice == null) return real;
    return real.requestedAt.isAfter(practice.requestedAt) ? real : practice;
  }

  RecoveryRequest? _manageableRecoveryForKind(String pubkey, bool isPractice) {
    final mine = recoveryRequests
        .where((r) => r.initiatorPubkey == pubkey && r.isPractice == isPractice)
        .toList();
    if (mine.isEmpty) return null;
    mine.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    final latest = mine.first;
    if (latest.status == RecoveryRequestStatus.cancelled ||
        latest.status == RecoveryRequestStatus.archived) {
      return null;
    }
    final manageable = mine
        .where(
          (r) => r.status.isActive || r.status == RecoveryRequestStatus.completed,
        )
        .toList();
    if (manageable.isEmpty) return null;
    manageable.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return manageable.first;
  }
}
