/// Represents the current state of a recovery process
class RecoveryStatus {
  final String recoveryRequestId;
  final int totalStewards;
  final int respondedCount;
  final int approvedCount;
  final int deniedCount;
  final List<String> collectedShardIds; // List of shard data IDs
  final int threshold;
  final bool canRecover;
  final DateTime lastUpdated;

  const RecoveryStatus({
    required this.recoveryRequestId,
    required this.totalStewards,
    required this.respondedCount,
    required this.approvedCount,
    required this.deniedCount,
    required this.collectedShardIds,
    required this.threshold,
    required this.canRecover,
    required this.lastUpdated,
  });

  /// Validate the recovery status
  bool get isValid {
    // TotalStewards must be positive
    if (totalStewards <= 0) return false;

    // RespondedCount must be <= totalStewards
    if (respondedCount > totalStewards) return false;

    // ApprovedCount + deniedCount must be <= respondedCount
    if (approvedCount + deniedCount > respondedCount) return false;

    // Threshold must be positive and <= totalStewards
    if (threshold <= 0 || threshold > totalStewards) return false;

    // CanRecover must be true when approvedCount >= threshold
    if (approvedCount >= threshold && !canRecover) return false;

    // CollectedShardIds count should match approvedCount
    if (collectedShardIds.length != approvedCount) return false;

    return true;
  }

  /// Get the completion percentage
  double get completionPercentage {
    if (totalStewards == 0) return 0.0;
    return (respondedCount / totalStewards) * 100.0;
  }

  /// Get the recovery progress (based on threshold)
  double get recoveryProgress {
    if (threshold == 0) return 0.0;
    final progress = (approvedCount / threshold) * 100.0;
    return progress > 100.0 ? 100.0 : progress;
  }

  /// Check if recovery is complete
  bool get isComplete {
    return canRecover && approvedCount >= threshold;
  }

  /// Check if recovery has failed
  bool get hasFailed {
    final maxPossibleApprovals = totalStewards - deniedCount;
    return maxPossibleApprovals < threshold;
  }

  /// Get the number of pending responses
  int get pendingCount {
    return totalStewards - respondedCount;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'recoveryRequestId': recoveryRequestId,
      'totalStewards': totalStewards,
      'respondedCount': respondedCount,
      'approvedCount': approvedCount,
      'deniedCount': deniedCount,
      'collectedShardIds': collectedShardIds,
      'threshold': threshold,
      'canRecover': canRecover,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON
  factory RecoveryStatus.fromJson(Map<String, dynamic> json) {
    return RecoveryStatus(
      recoveryRequestId: json['recoveryRequestId'] as String,
      totalStewards: json['totalStewards'] as int,
      respondedCount: json['respondedCount'] as int,
      approvedCount: json['approvedCount'] as int,
      deniedCount: json['deniedCount'] as int,
      collectedShardIds:
          (json['collectedShardIds'] as List<dynamic>).map((e) => e as String).toList(),
      threshold: json['threshold'] as int,
      canRecover: json['canRecover'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  RecoveryStatus copyWith({
    String? recoveryRequestId,
    int? totalStewards,
    int? respondedCount,
    int? approvedCount,
    int? deniedCount,
    List<String>? collectedShardIds,
    int? threshold,
    bool? canRecover,
    DateTime? lastUpdated,
  }) {
    return RecoveryStatus(
      recoveryRequestId: recoveryRequestId ?? this.recoveryRequestId,
      totalStewards: totalStewards ?? this.totalStewards,
      respondedCount: respondedCount ?? this.respondedCount,
      approvedCount: approvedCount ?? this.approvedCount,
      deniedCount: deniedCount ?? this.deniedCount,
      collectedShardIds: collectedShardIds ?? this.collectedShardIds,
      threshold: threshold ?? this.threshold,
      canRecover: canRecover ?? this.canRecover,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'RecoveryStatus(requestId: $recoveryRequestId, progress: ${recoveryProgress.toStringAsFixed(1)}%, canRecover: $canRecover)';
  }
}
