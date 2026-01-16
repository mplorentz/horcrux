import 'package:freezed_annotation/freezed_annotation.dart';

import 'shard_data.dart';

part 'recovery_request.freezed.dart';

/// Recovery request status enum
enum RecoveryRequestStatus {
  pending, // Request created but not yet sent
  sent, // Request sent to stewards via Nostr
  inProgress, // Responses being collected
  completed, // Recovery successful, content reassembled
  failed, // Recovery failed (insufficient shares or timeout)
  cancelled, // Request cancelled by user
  archived, // Recovery completed and user exited recovery mode
}

/// Recovery response status enum
enum RecoveryResponseStatus {
  pending, // No response yet
  approved, // Key holder approved and shared key
  denied, // Key holder denied the request
  timeout, // No response within timeout period
  error, // Error processing response (e.g., version mismatch)
}

/// Extension methods for RecoveryRequestStatus
extension RecoveryRequestStatusExtension on RecoveryRequestStatus {
  String get displayName {
    switch (this) {
      case RecoveryRequestStatus.pending:
        return 'Pending';
      case RecoveryRequestStatus.sent:
        return 'Sent';
      case RecoveryRequestStatus.inProgress:
        return 'In Progress';
      case RecoveryRequestStatus.completed:
        return 'Completed';
      case RecoveryRequestStatus.failed:
        return 'Failed';
      case RecoveryRequestStatus.cancelled:
        return 'Cancelled';
      case RecoveryRequestStatus.archived:
        return 'Archived';
    }
  }

  bool get isActive {
    return this == RecoveryRequestStatus.pending ||
        this == RecoveryRequestStatus.sent ||
        this == RecoveryRequestStatus.inProgress;
  }

  bool get isTerminal {
    return this == RecoveryRequestStatus.completed ||
        this == RecoveryRequestStatus.failed ||
        this == RecoveryRequestStatus.cancelled ||
        this == RecoveryRequestStatus.archived;
  }
}

/// Extension methods for RecoveryResponseStatus
extension RecoveryResponseStatusExtension on RecoveryResponseStatus {
  String get displayName {
    switch (this) {
      case RecoveryResponseStatus.pending:
        return 'Pending';
      case RecoveryResponseStatus.approved:
        return 'Approved';
      case RecoveryResponseStatus.denied:
        return 'Denied';
      case RecoveryResponseStatus.timeout:
        return 'Timeout';
      case RecoveryResponseStatus.error:
        return 'Error';
    }
  }

  bool get isResolved {
    return this != RecoveryResponseStatus.pending;
  }
}

/// Represents a steward's response to a recovery request
@freezed
class RecoveryResponse with _$RecoveryResponse {
  const factory RecoveryResponse({
    required String pubkey, // hex format, 64 characters
    required bool approved, // Whether the steward approved the request
    DateTime? respondedAt,
    ShardData? shardData, // Actual shard data for reassembly (if approved)
    String? nostrEventId,
    String? errorMessage, // Error message if status is error
  }) = _RecoveryResponse;

  const RecoveryResponse._();

  /// Validate the recovery response
  bool get isValid {
    // Pubkey must be valid hex format (64 characters)
    if (pubkey.length != 64 || !_isHexString(pubkey)) {
      return false;
    }

    // RespondedAt must be in the past if provided
    if (respondedAt != null && respondedAt!.isAfter(DateTime.now())) {
      return false;
    }

    // ShardData must be present if approved
    if (approved && shardData == null) {
      return false;
    }

    return true;
  }

  /// Status helper for backwards compatibility
  RecoveryResponseStatus get status {
    if (errorMessage != null) return RecoveryResponseStatus.error;
    if (respondedAt == null) return RecoveryResponseStatus.pending;
    return approved ? RecoveryResponseStatus.approved : RecoveryResponseStatus.denied;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'pubkey': pubkey,
      'approved': approved,
      'respondedAt': respondedAt?.toIso8601String(),
      'shardData': shardData != null ? shardDataToJson(shardData!) : null,
      'nostrEventId': nostrEventId,
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory RecoveryResponse.fromJson(Map<String, dynamic> json) {
    return RecoveryResponse(
      pubkey: json['pubkey'] as String,
      approved: json['approved'] as bool? ?? false,
      respondedAt:
          json['respondedAt'] != null ? DateTime.parse(json['respondedAt'] as String) : null,
      shardData: json['shardData'] != null
          ? shardDataFromJson(json['shardData'] as Map<String, dynamic>)
          : null,
      nostrEventId: json['nostrEventId'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  String toString() {
    return 'RecoveryResponse(pubkey: ${pubkey.substring(0, 8)}..., status: ${status.displayName})';
  }
}

/// Represents a request to recover a vault
@freezed
class RecoveryRequest with _$RecoveryRequest {
  const factory RecoveryRequest({
    required String id,
    required String vaultId,
    required String initiatorPubkey, // hex format, 64 characters
    required DateTime requestedAt,
    required RecoveryRequestStatus status,
    required int threshold, // Shamir threshold needed for recovery
    String? nostrEventId,
    DateTime? expiresAt,
    @Default({}) Map<String, RecoveryResponse> stewardResponses, // pubkey -> response
    String? errorMessage, // Error message if status is failed
    @Default(false) bool isPractice, // True for practice recovery sessions
  }) = _RecoveryRequest;

  const RecoveryRequest._();

  /// Validate the recovery request
  bool get isValid {
    // ID must be non-empty
    if (id.isEmpty) return false;

    // VaultId must be non-empty
    if (vaultId.isEmpty) return false;

    // InitiatorPubkey must be valid hex format (64 characters)
    if (initiatorPubkey.length != 64 || !_isHexString(initiatorPubkey)) {
      return false;
    }

    // RequestedAt must be in the past
    if (requestedAt.isAfter(DateTime.now())) {
      return false;
    }

    // ExpiresAt must be in the future if set
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) {
      return false;
    }

    return true;
  }

  /// Check if the request has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get the count of responses by status
  int getResponseCount(RecoveryResponseStatus status) {
    return stewardResponses.values.where((r) => r.status == status).length;
  }

  /// Get total number of stewards
  int get totalStewards => stewardResponses.length;

  /// Get number of responses received
  int get respondedCount => stewardResponses.values.where((r) => r.status.isResolved).length;

  /// Get number of approvals
  int get approvedCount => getResponseCount(RecoveryResponseStatus.approved);

  /// Get number of denials
  int get deniedCount => getResponseCount(RecoveryResponseStatus.denied);

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vaultId': vaultId,
      'initiatorPubkey': initiatorPubkey,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.name,
      'threshold': threshold,
      'nostrEventId': nostrEventId,
      'expiresAt': expiresAt?.toIso8601String(),
      'stewardResponses': stewardResponses.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'errorMessage': errorMessage,
      'isPractice': isPractice,
    };
  }

  /// Create from JSON
  factory RecoveryRequest.fromJson(Map<String, dynamic> json) {
    final responsesJson = json['stewardResponses'] as Map<String, dynamic>?;
    final responses = responsesJson?.map(
          (key, value) => MapEntry(
            key,
            RecoveryResponse.fromJson(value as Map<String, dynamic>),
          ),
        ) ??
        {};

    return RecoveryRequest(
      id: json['id'] as String,
      vaultId: json['vaultId'] as String,
      initiatorPubkey: json['initiatorPubkey'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      status: RecoveryRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RecoveryRequestStatus.pending,
      ),
      threshold: json['threshold'] as int? ??
          1, // Default to 1 if not present (for backwards compatibility)
      nostrEventId: json['nostrEventId'] as String?,
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
      stewardResponses: responses,
      errorMessage: json['errorMessage'] as String?,
      isPractice: json['isPractice'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'RecoveryRequest(id: $id, vaultId: $vaultId, status: ${status.displayName})';
  }
}

/// Helper to validate hex strings
bool _isHexString(String str) {
  return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
}
