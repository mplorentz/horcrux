import 'package:freezed_annotation/freezed_annotation.dart';

import 'steward.dart';
import 'steward_status.dart';
import 'vault.dart';

part 'backup_config.freezed.dart';

/// Backup configuration for a vault.
///
/// **Phase 1 hydration contract** (see `docs/data_layer_refactor_plan.md`):
/// `BackupConfig` is no longer persisted as a JSON blob. It is hydrated
/// on read from `vaults` + `owned_vaults` + active `stewards`
/// (`StewardDao.activeForVault`). Removed compared to the legacy record
/// typedef: `specVersion`, `totalKeys`, `lastUpdated`, `lastContentChange`,
/// `lastRedistribution`, `contentHash`, `status`. Each of those was either
/// pure decoration or derivable:
///
/// - `totalKeys` → `stewards.length` (derived getter).
/// - `lastRedistribution` / `lastUpdated` / `lastContentChange` → derived
///   from row timestamps in `distributions` and `vaults`. Phase 2/3 wires
///   these into the schema; Phase 1 exposes them via getters that key off
///   `distributionVersion` so existing UI keeps working.
/// - `status` → derived from steward statuses (Phase 1 fallback) and from
///   `distribution_shares` ack timestamps (Phase 2/3).
@freezed
class BackupConfig with _$BackupConfig {
  const factory BackupConfig({
    required String vaultId,
    required int threshold,
    required List<Steward> stewards,
    required List<String> relays,
    required DateTime createdAt,
    required int distributionVersion,
    String? instructions,
  }) = _BackupConfig;

  const BackupConfig._();

  /// Number of configured stewards.
  int get totalKeys => stewards.length;

  /// True once any distribution has been authored. Replaces
  /// `lastRedistribution != null` checks throughout the UI.
  bool get hasBeenDistributed => distributionVersion > 0;
}

/// Create a new BackupConfig with validation.
BackupConfig createBackupConfig({
  required String vaultId,
  required int threshold,
  required int totalKeys,
  required List<Steward> stewards,
  required List<String> relays,
  String? instructions,
}) {
  // Threshold must be >= 1 and <= max(1, totalKeys). A 0-steward plan
  // carries its recommended threshold (>= 1), inert — no crypto-facing code
  // reads it without first passing isValidForDistribution.
  final maxThreshold = totalKeys < 1 ? 1 : totalKeys;
  if (threshold < VaultBackupConstraints.minThreshold || threshold > maxThreshold) {
    throw ArgumentError(
      'Threshold must be >= ${VaultBackupConstraints.minThreshold} and <= totalKeys',
    );
  }
  if (totalKeys < 0 || totalKeys > VaultBackupConstraints.maxTotalKeys) {
    throw ArgumentError(
      'TotalKeys must be between 0 and ${VaultBackupConstraints.maxTotalKeys}',
    );
  }
  if (stewards.isNotEmpty && stewards.length != totalKeys) {
    throw ArgumentError('Stewards length must equal totalKeys');
  }
  if (relays.isEmpty) {
    throw ArgumentError('At least one relay must be provided');
  }

  final ids = stewards.map((h) => h.id).toSet();
  if (ids.length != stewards.length) {
    throw ArgumentError('All stewards must have unique IDs');
  }

  final stewardsWithPubkeys = stewards.where((h) => h.pubkey != null).toList();
  final npubs = stewardsWithPubkeys.map((h) => h.npub).where((n) => n != null).toSet();
  if (npubs.length != stewardsWithPubkeys.length) {
    throw ArgumentError('All stewards with pubkeys must have unique npubs');
  }

  for (final relay in relays) {
    if (!_isValidRelayUrl(relay)) {
      throw ArgumentError('Invalid relay URL: $relay');
    }
  }

  return BackupConfig(
    vaultId: vaultId,
    threshold: threshold,
    stewards: stewards,
    relays: relays,
    instructions: instructions,
    createdAt: DateTime.now(),
    distributionVersion: 0,
  );
}

bool hasOwnerSteward(BackupConfig config) {
  return config.stewards.any((s) => s.isOwner);
}

Steward? getOwnerSteward(BackupConfig config) {
  try {
    return config.stewards.firstWhere((s) => s.isOwner);
  } catch (e) {
    return null;
  }
}

extension BackupConfigExtension on BackupConfig {
  /// Structural validity: relays are valid, ids are unique, and threshold
  /// is in [1, max(1, n)]. A 0-steward plan with valid relays is valid.
  bool get isValidForSave {
    try {
      if (relays.isEmpty) return false;
      if (threshold < VaultBackupConstraints.minThreshold) return false;

      // When there are stewards, threshold must not exceed stewards count.
      if (stewards.isNotEmpty && threshold > totalKeys) return false;

      final ids = stewards.map((h) => h.id).toSet();
      if (ids.length != stewards.length) return false;

      final stewardsWithPubkeys = stewards.where((h) => h.pubkey != null).toList();
      final npubs = stewardsWithPubkeys.map((h) => h.npub).where((n) => n != null).toSet();
      if (npubs.length != stewardsWithPubkeys.length) {
        return false;
      }

      for (final relay in relays) {
        if (!_isValidRelayUrl(relay)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Whether this config can actually have its keys distributed.
  ///
  /// Distribution requires a real Shamir split: at least
  /// [VaultBackupConstraints.minStewardsForDistribution] stewards and a
  /// threshold of at least 2. A structurally valid plan with fewer stewards
  /// is still a legitimate thing to *save* — it is simply not finished yet.
  bool get isValidForDistribution {
    if (stewards.length < VaultBackupConstraints.minStewardsForDistribution) {
      return false;
    }
    if (threshold < VaultBackupConstraints.minStewardsForDistribution) {
      return false;
    }
    return isValidForSave;
  }

  int get activeStewardsCount {
    return stewards.where((h) => h.isActive).length;
  }

  int get acknowledgedStewardsCount {
    return stewards.where((h) => h.status == StewardStatus.holdingKey).length;
  }

  /// Backup is ready when every active steward holds the current
  /// distribution and threshold is met. Replaces the old `status == active`
  /// check (status is no longer persisted).
  bool get isReady {
    if (stewards.isEmpty) return false;
    return hasBeenDistributed && acknowledgedStewardsCount >= threshold;
  }

  bool get canDistribute {
    if (stewards.isEmpty) return false;
    return stewards.every((h) => h.pubkey != null);
  }

  int get pendingInvitationsCount {
    return stewards.where((h) => h.status == StewardStatus.invited && h.pubkey == null).length;
  }

  /// True when the owner still needs to publish shards for the current
  /// [distributionVersion].
  ///
  /// Stewards stay `awaitingKey` or `awaitingNewKey` both before publish (must
  /// distribute) and after publish until they acknowledge — those states must
  /// not be conflated. Phase 1 records the gift-wrap event id on each steward
  /// when publish succeeds ([Steward.giftWrapEventId]); redistribution resets
  /// it so a missing id means send is still pending.
  bool get needsRedistribution {
    if (stewards.isEmpty) return false;
    if (!hasBeenDistributed) return true;
    return stewards.any((s) {
      if (s.pubkey == null) return false;
      final awaitingSend =
          s.status == StewardStatus.awaitingKey || s.status == StewardStatus.awaitingNewKey;
      return awaitingSend && s.giftWrapEventId == null;
    });
  }

  bool get hasVersionMismatch {
    return stewards.any(
      (h) =>
          h.acknowledgedDistributionVersion != null &&
          h.acknowledgedDistributionVersion != distributionVersion,
    );
  }

  bool get allStewardsHoldingCurrentKey {
    if (stewards.isEmpty) return false;

    final stewardsWithPubkeys = stewards.where((s) => s.pubkey != null);
    if (stewardsWithPubkeys.isEmpty) return false;

    return stewardsWithPubkeys.every(
      (s) =>
          s.status == StewardStatus.holdingKey &&
          s.acknowledgedDistributionVersion == distributionVersion,
    );
  }

  bool configParamsDifferFrom(BackupConfig other) {
    if (threshold != other.threshold) return true;
    if (!_areRelaysEqual(relays, other.relays)) return true;
    if (instructions != other.instructions) return true;

    final thisIds = stewards.map((h) => h.id).toSet();
    final otherIds = other.stewards.map((h) => h.id).toSet();
    if (thisIds.length != otherIds.length) return true;
    if (!thisIds.containsAll(otherIds)) return true;

    return false;
  }

  bool _areRelaysEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    final set1 = Set<String>.from(list1);
    final set2 = Set<String>.from(list2);
    return set1.containsAll(set2) && set2.containsAll(set1);
  }
}

String backupConfigToString(BackupConfig config) {
  return 'BackupConfig(vaultId: ${config.vaultId}, threshold: ${config.threshold}/${config.totalKeys}, '
      'stewards: ${config.stewards.length})';
}

bool _isValidRelayUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.scheme == 'wss' || uri.scheme == 'ws';
  } catch (e) {
    return false;
  }
}
