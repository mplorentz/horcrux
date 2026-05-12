import 'backup_config.dart';
import 'recovery_request.dart';
import 'share.dart';
import 'steward.dart';

/// Role-typed read model for a vault entry on the current device.
///
/// Two concrete types mirror the two persistent storage roles:
/// - [OwnedVaultDetail]: this device holds the `owned_vaults` row — the user
///   is the vault owner and can read the NIP-44 [content].
/// - [StewardedVaultDetail]: this device holds a `held_shares` row — the user
///   is a steward. [latestShare] is null when the invite was accepted but the
///   share event has not arrived yet (awaiting state).
///
/// Both types expose the shared core (name, owner identity, threshold,
/// active [stewards]) so widgets can render common UI without switching on
/// role. Pattern-match on the concrete type to route role-specific behaviour.
///
/// See `docs/data_layer_refactor_plan.md` Phase 6 for the authoritative
/// description.
sealed class VaultDetail {
  const VaultDetail();

  String get id;
  String get name;
  String get ownerPubkey;
  String? get ownerName;
  int get threshold;
  int get totalShares;

  /// Active stewards for this vault (left_at IS NULL in DB).
  List<Steward> get stewards;

  /// In-flight recovery requests. Always empty until Phase 3 ships the
  /// `recovery_requests` table; kept here so [hasActiveRecovery] and
  /// [manageableRecoveryFor] work uniformly once Phase 3 lands.
  List<RecoveryRequest> get recoveryRequests;

  bool get pushEnabled;
  DateTime get createdAt;
  DateTime? get archivedAt;
  String? get archivedReason;

  /// Owner-side backup plan; non-null when [threshold] > 0 or stewards exist.
  BackupConfig? get backupConfig;

  bool get isArchived => archivedAt != null;

  /// True when at least one recovery request is active.
  bool get hasActiveRecovery => recoveryRequests.any((r) => r.status.isActive);

  /// Whether [hexPubkey] is the vault owner.
  bool isVaultOwner(String hexPubkey) => ownerPubkey == hexPubkey;

  /// Returns the most recent manageable [RecoveryRequest] for [pubkey].
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

/// Vault detail for the device that owns the vault.
///
/// [content] is the NIP-44 ciphertext stored in `owned_vaults.content`.
/// [selfHeldShare] is the owner's own Shamir share (owner-as-steward
/// carve-out from the data layer design); it is null when the owner has not
/// yet distributed keys to themselves.
final class OwnedVaultDetail extends VaultDetail {
  const OwnedVaultDetail({
    required this.id,
    required this.name,
    required this.ownerPubkey,
    required this.ownerName,
    required this.threshold,
    required this.totalShares,
    required this.stewards,
    required this.recoveryRequests,
    required this.pushEnabled,
    required this.createdAt,
    required this.archivedAt,
    required this.archivedReason,
    required this.backupConfig,
    required this.content,
    required this.selfHeldShare,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String ownerPubkey;
  @override
  final String? ownerName;
  @override
  final int threshold;
  @override
  final int totalShares;
  @override
  final List<Steward> stewards;
  @override
  final List<RecoveryRequest> recoveryRequests;
  @override
  final bool pushEnabled;
  @override
  final DateTime createdAt;
  @override
  final DateTime? archivedAt;
  @override
  final String? archivedReason;
  @override
  final BackupConfig? backupConfig;

  /// NIP-44 ciphertext of the vault secret.
  final String content;

  /// Owner's own Shamir share when the owner is also their own steward.
  /// Null until keys have been distributed for the first time.
  final Share? selfHeldShare;
}

/// Vault detail for a steward device (does not own the vault).
///
/// [latestShare] is the most-recently-received [Share] for this vault, or
/// null when the invitation was accepted but the share event has not arrived
/// yet (awaiting-share state).
final class StewardedVaultDetail extends VaultDetail {
  const StewardedVaultDetail({
    required this.id,
    required this.name,
    required this.ownerPubkey,
    required this.ownerName,
    required this.threshold,
    required this.totalShares,
    required this.stewards,
    required this.recoveryRequests,
    required this.pushEnabled,
    required this.createdAt,
    required this.archivedAt,
    required this.archivedReason,
    required this.backupConfig,
    required this.latestShare,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String ownerPubkey;
  @override
  final String? ownerName;
  @override
  final int threshold;
  @override
  final int totalShares;
  @override
  final List<Steward> stewards;
  @override
  final List<RecoveryRequest> recoveryRequests;
  @override
  final bool pushEnabled;
  @override
  final DateTime createdAt;
  @override
  final DateTime? archivedAt;
  @override
  final String? archivedReason;
  @override
  final BackupConfig? backupConfig;

  /// Most recently received share for this vault. Null when the steward has
  /// accepted an invite but not yet received a share event (awaiting-share state).
  final Share? latestShare;
}
