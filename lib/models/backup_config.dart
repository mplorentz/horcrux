import 'steward.dart';
import 'steward_status.dart';
import 'backup_status.dart';
import 'vault.dart';

/// Represents the backup configuration for a vault
///
/// This model contains all the settings and metadata needed to configure
/// distributed backup using Shamir's Secret Sharing and Nostr protocol.
typedef BackupConfig = ({
  String vaultId,
  String specVersion,
  int threshold,
  int totalKeys,
  List<Steward> stewards,
  List<String> relays,
  String? instructions,
  DateTime createdAt,
  DateTime lastUpdated,
  DateTime? lastContentChange,
  DateTime? lastRedistribution,
  String? contentHash,
  BackupStatus status,
  int distributionVersion, // Version tracking for redistribution detection
});

/// Create a new BackupConfig with validation
BackupConfig createBackupConfig({
  required String vaultId,
  required int threshold,
  required int totalKeys,
  required List<Steward> stewards,
  required List<String> relays,
  String? instructions,
  String? contentHash,
}) {
  // Validate inputs
  if (threshold < VaultBackupConstraints.minThreshold || threshold > totalKeys) {
    throw ArgumentError(
      'Threshold must be >= ${VaultBackupConstraints.minThreshold} and <= totalKeys',
    );
  }
  if (totalKeys < threshold || totalKeys > VaultBackupConstraints.maxTotalKeys) {
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

  // Validate stewards have unique IDs
  final ids = stewards.map((h) => h.id).toSet();
  if (ids.length != stewards.length) {
    throw ArgumentError('All stewards must have unique IDs');
  }

  // Validate stewards with pubkeys have unique npubs
  final stewardsWithPubkeys = stewards.where((h) => h.pubkey != null).toList();
  final npubs = stewardsWithPubkeys.map((h) => h.npub).where((n) => n != null).toSet();
  if (npubs.length != stewardsWithPubkeys.length) {
    throw ArgumentError('All stewards with pubkeys must have unique npubs');
  }

  // Validate relay URLs
  for (final relay in relays) {
    if (!_isValidRelayUrl(relay)) {
      throw ArgumentError('Invalid relay URL: $relay');
    }
  }

  final now = DateTime.now();
  return (
    vaultId: vaultId,
    specVersion: '1.0.0', // Current specification version
    threshold: threshold,
    totalKeys: totalKeys,
    stewards: stewards,
    relays: relays,
    instructions: instructions,
    createdAt: now,
    lastUpdated: now,
    lastContentChange: null,
    lastRedistribution: null,
    contentHash: contentHash,
    status: BackupStatus.pending,
    distributionVersion: 0, // Initialize to version 0
  );
}

/// Create a copy of this BackupConfig with updated fields
BackupConfig copyBackupConfig(
  BackupConfig config, {
  String? vaultId,
  String? specVersion,
  int? threshold,
  int? totalKeys,
  List<Steward>? stewards,
  List<String>? relays,
  String? instructions,
  DateTime? createdAt,
  DateTime? lastUpdated,
  DateTime? lastContentChange,
  DateTime? lastRedistribution,
  String? contentHash,
  BackupStatus? status,
  int? distributionVersion,
}) {
  return (
    vaultId: vaultId ?? config.vaultId,
    specVersion: specVersion ?? config.specVersion,
    threshold: threshold ?? config.threshold,
    totalKeys: totalKeys ?? config.totalKeys,
    stewards: stewards ?? config.stewards,
    relays: relays ?? config.relays,
    instructions: instructions ?? config.instructions,
    createdAt: createdAt ?? config.createdAt,
    lastUpdated: lastUpdated ?? config.lastUpdated,
    lastContentChange: lastContentChange ?? config.lastContentChange,
    lastRedistribution: lastRedistribution ?? config.lastRedistribution,
    contentHash: contentHash ?? config.contentHash,
    status: status ?? config.status,
    distributionVersion: distributionVersion ?? config.distributionVersion,
  );
}

/// Extension methods for BackupConfig
extension BackupConfigExtension on BackupConfig {
  /// Check if this backup configuration is valid
  bool get isValid {
    try {
      if (threshold < VaultBackupConstraints.minThreshold || threshold > totalKeys) {
        return false;
      }
      if (totalKeys < threshold || totalKeys > VaultBackupConstraints.maxTotalKeys) {
        return false;
      }
      if (stewards.length != totalKeys) return false;
      if (relays.isEmpty) return false;

      // Check for unique IDs
      final ids = stewards.map((h) => h.id).toSet();
      if (ids.length != stewards.length) return false;

      // Check for unique npubs (only for stewards with pubkeys)
      final stewardsWithPubkeys = stewards.where((h) => h.pubkey != null).toList();
      final npubs = stewardsWithPubkeys.map((h) => h.npub).where((n) => n != null).toSet();
      if (npubs.length != stewardsWithPubkeys.length) {
        return false;
      }

      // Check relay URLs
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

  /// Check if content has changed since last redistribution
  bool get hasContentChanged {
    if (lastContentChange == null || lastRedistribution == null) {
      return lastContentChange != null;
    }
    return lastContentChange!.isAfter(lastRedistribution!);
  }

  /// Get the number of active stewards
  int get activeStewardsCount {
    return stewards.where((h) => h.isActive).length;
  }

  /// Get the number of acknowledged stewards
  int get acknowledgedStewardsCount {
    return stewards.where((h) => h.status == StewardStatus.holdingKey).length;
  }

  /// Check if backup is ready (all stewards acknowledged)
  bool get isReady {
    return status == BackupStatus.active && acknowledgedStewardsCount >= threshold;
  }

  /// Check if all stewards are ready for distribution (have pubkeys)
  bool get canDistribute {
    return stewards.every((h) => h.pubkey != null);
  }

  /// Get the number of stewards still pending (invited but not accepted)
  int get pendingInvitationsCount {
    return stewards.where((h) => h.status == StewardStatus.invited && h.pubkey == null).length;
  }

  /// Check if redistribution is needed (config changed but not redistributed)
  bool get needsRedistribution {
    // Never distributed
    if (lastRedistribution == null) {
      return status == BackupStatus.pending || status == BackupStatus.active;
    }

    // Config updated after last redistribution
    return lastUpdated.isAfter(lastRedistribution!);
  }

  /// Check if there are version mismatches with stewards
  bool get hasVersionMismatch {
    return stewards.any(
      (h) =>
          h.acknowledgedDistributionVersion != null &&
          h.acknowledgedDistributionVersion != distributionVersion,
    );
  }

  /// Check if config parameters differ from another config
  /// Compares threshold, relays, instructions, and steward IDs (not status/acknowledgments)
  bool configParamsDifferFrom(BackupConfig other) {
    if (threshold != other.threshold) return true;
    if (!_areRelaysEqual(relays, other.relays)) return true;
    if (instructions != other.instructions) return true;

    // Compare steward IDs (not full stewards, since status may differ)
    final thisIds = stewards.map((h) => h.id).toSet();
    final otherIds = other.stewards.map((h) => h.id).toSet();
    if (thisIds.length != otherIds.length) return true;
    if (!thisIds.containsAll(otherIds)) return true;

    return false;
  }

  /// Helper to compare relay lists
  bool _areRelaysEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    final set1 = Set<String>.from(list1);
    final set2 = Set<String>.from(list2);
    return set1.containsAll(set2) && set2.containsAll(set1);
  }
}

/// Convert to JSON for storage
Map<String, dynamic> backupConfigToJson(BackupConfig config) {
  return {
    'vaultId': config.vaultId,
    'specVersion': config.specVersion,
    'threshold': config.threshold,
    'totalKeys': config.totalKeys,
    'stewards': config.stewards.map((h) => stewardToJson(h)).toList(),
    'relays': config.relays,
    if (config.instructions != null) 'instructions': config.instructions,
    'createdAt': config.createdAt.toIso8601String(),
    'lastUpdated': config.lastUpdated.toIso8601String(),
    'lastContentChange': config.lastContentChange?.toIso8601String(),
    'lastRedistribution': config.lastRedistribution?.toIso8601String(),
    'contentHash': config.contentHash,
    'status': config.status.name,
    'distributionVersion': config.distributionVersion,
  };
}

/// Create from JSON
BackupConfig backupConfigFromJson(Map<String, dynamic> json) {
  return (
    vaultId: json['vaultId'] as String,
    specVersion: json['specVersion'] as String,
    threshold: json['threshold'] as int,
    totalKeys: json['totalKeys'] as int,
    stewards:
        (json['stewards'] as List).map((h) => stewardFromJson(h as Map<String, dynamic>)).toList(),
    relays: (json['relays'] as List).cast<String>(),
    instructions: json['instructions'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    lastContentChange: json['lastContentChange'] != null
        ? DateTime.parse(json['lastContentChange'] as String)
        : null,
    lastRedistribution: json['lastRedistribution'] != null
        ? DateTime.parse(json['lastRedistribution'] as String)
        : null,
    contentHash: json['contentHash'] as String?,
    status: BackupStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => BackupStatus.pending,
    ),
    distributionVersion:
        json['distributionVersion'] as int? ?? 1, // Default to 1 for backward compatibility
  );
}

/// String representation of BackupConfig
String backupConfigToString(BackupConfig config) {
  return 'BackupConfig(vaultId: ${config.vaultId}, threshold: ${config.threshold}/${config.totalKeys}, '
      'status: ${config.status}, stewards: ${config.stewards.length})';
}

/// Validate relay URL format
bool _isValidRelayUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.scheme == 'wss' || uri.scheme == 'ws';
  } catch (e) {
    return false;
  }
}
