import 'package:freezed_annotation/freezed_annotation.dart';
import 'shard_data.dart';
import 'recovery_request.dart';
import 'backup_config.dart';

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

/// Vault state enum indicating the current state of a vault
enum VaultState {
  recovery, // Active recovery in progress
  owned, // Has decrypted content
  steward, // Has shard but no content
  awaitingKey, // Invitee has accepted invitation but hasn't received shard yet
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
    @Default([]) List<ShardData> shards, // List of shards (single as steward, multiple during recovery)
    @Default([]) List<RecoveryRequest> recoveryRequests, // Embedded recovery requests
    BackupConfig? backupConfig, // Optional backup configuration
    @Default(false) bool isArchived, // Whether this vault is archived
    DateTime? archivedAt, // When the vault was archived
    String? archivedReason, // Reason for archiving
  }) = _Vault;

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
    );
  }
}

/// Extension methods for Vault
extension VaultExtension on Vault {
  /// Get the state of this vault based on priority:
  /// 1. Recovery (if has active recovery request)
  /// 2. Owned (if has decrypted content)
  /// 3. Steward (if has shards but no content)
  /// 4. Awaiting key (if no content and no shards - invitee waiting for shard)
  VaultState get state {
    if (hasActiveRecovery) {
      return VaultState.recovery;
    }
    if (content != null) {
      return VaultState.owned;
    }
    if (shards.isNotEmpty) {
      return VaultState.steward;
    }
    // No content and no shards - invitee is awaiting key distribution
    return VaultState.awaitingKey;
  }

  /// Check if the given hex key is the owner of this vault
  bool isOwned(String hexKey) => ownerPubkey == hexKey;

  /// Check if we are a steward for this vault (have shards)
  bool get isSteward => shards.isNotEmpty;

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
    };
  }

  /// Create a copy with content explicitly cleared (set to null)
  /// This preserves shards, backup config, and other data
  Vault copyWithContentDeleted() {
    return copyWith(content: null);
  }
}
