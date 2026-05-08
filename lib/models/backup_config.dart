import 'steward.dart';
import 'steward_status.dart';
import 'vault.dart';

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
class BackupConfig {
  final String vaultId;
  final int threshold;
  final List<Steward> stewards;
  final List<String> relays;
  final String? instructions;
  final DateTime createdAt;
  final int distributionVersion;

  const BackupConfig({
    required this.vaultId,
    required this.threshold,
    required this.stewards,
    required this.relays,
    required this.createdAt,
    required this.distributionVersion,
    this.instructions,
  });

  /// Number of configured stewards (replaces the dropped `totalKeys` field —
  /// it duplicated `stewards.length`).
  int get totalKeys => stewards.length;

  /// True once any distribution has been authored. Replaces
  /// `lastRedistribution != null` checks throughout the UI.
  bool get hasBeenDistributed => distributionVersion > 0;

  BackupConfig copyWith({
    String? vaultId,
    int? threshold,
    List<Steward>? stewards,
    List<String>? relays,
    String? instructions,
    DateTime? createdAt,
    int? distributionVersion,
  }) {
    return BackupConfig(
      vaultId: vaultId ?? this.vaultId,
      threshold: threshold ?? this.threshold,
      stewards: stewards ?? this.stewards,
      relays: relays ?? this.relays,
      instructions: instructions ?? this.instructions,
      createdAt: createdAt ?? this.createdAt,
      distributionVersion: distributionVersion ?? this.distributionVersion,
    );
  }
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
  if (threshold < VaultBackupConstraints.minThreshold ||
      threshold > totalKeys) {
    throw ArgumentError(
      'Threshold must be >= ${VaultBackupConstraints.minThreshold} and <= totalKeys',
    );
  }
  if (totalKeys < threshold ||
      totalKeys > VaultBackupConstraints.maxTotalKeys) {
    throw ArgumentError(
      'TotalKeys must be >= threshold and <= ${VaultBackupConstraints.maxTotalKeys}',
    );
  }
  if (stewards.length != totalKeys) {
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
  final npubs = stewardsWithPubkeys
      .map((h) => h.npub)
      .where((n) => n != null)
      .toSet();
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

/// Create a copy of this BackupConfig with updated fields.
BackupConfig copyBackupConfig(
  BackupConfig config, {
  String? vaultId,
  int? threshold,
  List<Steward>? stewards,
  List<String>? relays,
  String? instructions,
  DateTime? createdAt,
  int? distributionVersion,
}) {
  return config.copyWith(
    vaultId: vaultId,
    threshold: threshold,
    stewards: stewards,
    relays: relays,
    instructions: instructions,
    createdAt: createdAt,
    distributionVersion: distributionVersion,
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
  bool get isValid {
    try {
      if (threshold < VaultBackupConstraints.minThreshold ||
          threshold > totalKeys) {
        return false;
      }
      if (totalKeys < threshold ||
          totalKeys > VaultBackupConstraints.maxTotalKeys) {
        return false;
      }
      if (relays.isEmpty) return false;

      final ids = stewards.map((h) => h.id).toSet();
      if (ids.length != stewards.length) return false;

      final stewardsWithPubkeys = stewards
          .where((h) => h.pubkey != null)
          .toList();
      final npubs = stewardsWithPubkeys
          .map((h) => h.npub)
          .where((n) => n != null)
          .toSet();
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
    return hasBeenDistributed && acknowledgedStewardsCount >= threshold;
  }

  bool get canDistribute {
    return stewards.every((h) => h.pubkey != null);
  }

  int get pendingInvitationsCount {
    return stewards
        .where((h) => h.status == StewardStatus.invited && h.pubkey == null)
        .length;
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
    if (!hasBeenDistributed) return true;
    return stewards.any((s) {
      if (s.pubkey == null) return false;
      final awaitingSend =
          s.status == StewardStatus.awaitingKey ||
          s.status == StewardStatus.awaitingNewKey;
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
