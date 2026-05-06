import 'package:freezed_annotation/freezed_annotation.dart';

import 'backup_config.dart';
import 'backup_status.dart';
import 'recovery_request.dart';
import 'shard_data.dart';
import 'steward.dart';

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
    @Default(false) bool isArchived, // Whether this vault is archived
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
  /// only; leave it null to consider **both** kinds independently and return the
  /// single newer of the two manageable sessions (so the status banner stays in
  /// sync with the bottom actions).
  ///
  /// Selection is **per kind** (real vs practice): among matching requests we
  /// take the **most recent** by [RecoveryRequest.requestedAt]. If the newest
  /// request for that kind is `cancelled` or `archived`, we return null for that
  /// kind so an older `completed` row does not keep "Manage recovery" visible
  /// after the user cancels their latest attempt.
  ///
  /// Other users' requests are ignored ([initiatorPubkey] must match).
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

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'ownerPubkey': ownerPubkey,
      if (ownerName != null) 'ownerName': ownerName,
      'shards': shards.map((shard) => shardDataToJson(shard)).toList(),
      'recoveryRequests': recoveryRequests.map((request) => request.toJson()).toList(),
      'backupConfig': backupConfig != null ? backupConfigToJson(backupConfig!) : null,
      'isArchived': isArchived,
      if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
      if (archivedReason != null) 'archivedReason': archivedReason,
      'pushEnabled': pushEnabled,
    };
  }

  /// Create from JSON
  factory Vault.fromJson(Map<String, dynamic> json) {
    return Vault(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      ownerPubkey: json['ownerPubkey'] as String,
      ownerName: json['ownerName'] as String?,
      shards: json['shards'] != null
          ? (json['shards'] as List)
              .map(
                (shardJson) => shardDataFromJson(shardJson as Map<String, dynamic>),
              )
              .toList()
          : [],
      recoveryRequests: json['recoveryRequests'] != null
          ? (json['recoveryRequests'] as List)
              .map(
                (reqJson) => RecoveryRequest.fromJson(reqJson as Map<String, dynamic>),
              )
              .toList()
          : [],
      backupConfig: json['backupConfig'] != null
          ? backupConfigFromJson(json['backupConfig'] as Map<String, dynamic>)
          : null,
      isArchived: json['isArchived'] as bool? ?? false,
      archivedAt: json['archivedAt'] != null ? DateTime.parse(json['archivedAt'] as String) : null,
      archivedReason: json['archivedReason'] as String?,
      // Legacy vaults (persisted before `pushEnabled` existed) default to
      // `false`. The owner opts in explicitly -- their metadata is what
      // leaks to the notifier, so we never turn push on for an existing
      // vault without their say-so.
      pushEnabled: json['pushEnabled'] as bool? ?? false,
    );
  }

  /// Create a copy with content explicitly cleared (set to null)
  /// This preserves shards, backup config, and other data
  Vault copyWithContentDeleted() {
    return copyWith(content: null); // Explicitly clear content
  }
}
