import 'event_status.dart';

/// Represents a Nostr gift wrap event (kind 1059) containing an encrypted shard
///
/// This model contains information about a shard event that was published
/// to Nostr relays for a specific steward.
typedef ShardEvent = ({
  String eventId,
  String recipientPubkey, // Hex format
  String encryptedContent,
  String backupConfigId,
  int shardIndex,
  DateTime createdAt,
  DateTime? publishedAt,
  EventStatus status,
});

/// Create a new ShardEvent with validation
ShardEvent createShardEvent({
  required String eventId,
  required String recipientPubkey, // Hex format
  required String encryptedContent,
  required String backupConfigId,
  required int shardIndex,
}) {
  if (!_isValidEventId(eventId)) {
    throw ArgumentError('Invalid event ID format: $eventId');
  }
  if (!_isValidHexPubkey(recipientPubkey)) {
    throw ArgumentError('Invalid recipient pubkey format: $recipientPubkey');
  }
  if (shardIndex < 0) {
    throw ArgumentError('Shard index must be >= 0');
  }
  if (encryptedContent.isEmpty) {
    throw ArgumentError('Encrypted content cannot be empty');
  }

  return (
    eventId: eventId,
    recipientPubkey: recipientPubkey,
    encryptedContent: encryptedContent,
    backupConfigId: backupConfigId,
    shardIndex: shardIndex,
    createdAt: DateTime.now(),
    publishedAt: null,
    status: EventStatus.created,
  );
}

/// Create a copy of this ShardEvent with updated fields
ShardEvent copyShardEvent(
  ShardEvent event, {
  String? eventId,
  String? recipientPubkey, // Hex format
  String? encryptedContent,
  String? backupConfigId,
  int? shardIndex,
  DateTime? createdAt,
  DateTime? publishedAt,
  EventStatus? status,
}) {
  return (
    eventId: eventId ?? event.eventId,
    recipientPubkey: recipientPubkey ?? event.recipientPubkey,
    encryptedContent: encryptedContent ?? event.encryptedContent,
    backupConfigId: backupConfigId ?? event.backupConfigId,
    shardIndex: shardIndex ?? event.shardIndex,
    createdAt: createdAt ?? event.createdAt,
    publishedAt: publishedAt ?? event.publishedAt,
    status: status ?? event.status,
  );
}

/// Extension methods for ShardEvent
extension ShardEventExtension on ShardEvent {
  /// Check if this event has been published
  bool get isPublished {
    return status == EventStatus.published || status == EventStatus.confirmed;
  }

  /// Check if this event has been confirmed by recipient
  bool get isConfirmed {
    return status == EventStatus.confirmed;
  }

  /// Check if this event failed
  bool get hasFailed {
    return status == EventStatus.failed;
  }

  /// Get the time since creation
  Duration get age {
    return DateTime.now().difference(createdAt);
  }

  /// Get the time since publication (if published)
  Duration? get timeSincePublished {
    if (publishedAt == null) return null;
    return DateTime.now().difference(publishedAt!);
  }
}

/// Convert to JSON for storage
Map<String, dynamic> shardEventToJson(ShardEvent event) {
  return {
    'eventId': event.eventId,
    'recipientPubkey': event.recipientPubkey, // Store hex format
    'encryptedContent': event.encryptedContent,
    'backupConfigId': event.backupConfigId,
    'shardIndex': event.shardIndex,
    'createdAt': event.createdAt.toIso8601String(),
    'publishedAt': event.publishedAt?.toIso8601String(),
    'status': event.status.name,
  };
}

/// Create from JSON
ShardEvent shardEventFromJson(Map<String, dynamic> json) {
  return (
    eventId: json['eventId'] as String,
    recipientPubkey: json['recipientPubkey'] as String, // Read hex format
    encryptedContent: json['encryptedContent'] as String,
    backupConfigId: json['backupConfigId'] as String,
    shardIndex: json['shardIndex'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt'] as String) : null,
    status: EventStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => EventStatus.created,
    ),
  );
}

/// String representation of ShardEvent
String shardEventToString(ShardEvent event) {
  return 'ShardEvent(eventId: ${event.eventId.substring(0, 8)}..., '
      'recipient: ${event.recipientPubkey.substring(0, 8)}..., '
      'status: ${event.status}, shardIndex: ${event.shardIndex})';
}

/// Validate event ID format (64-character hex string)
bool _isValidEventId(String eventId) {
  if (eventId.length != 64) return false;
  return RegExp(r'^[0-9a-fA-F]+$').hasMatch(eventId);
}

/// Validate hex pubkey format (64 characters, no 0x prefix)
bool _isValidHexPubkey(String pubkey) {
  if (pubkey.length != 64) return false; // 64 hex chars, no 0x prefix
  return RegExp(r'^[0-9a-fA-F]+$').hasMatch(pubkey);
}
