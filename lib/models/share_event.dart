import 'event_status.dart';

/// Represents a Nostr gift wrap event (kind 1059) carrying encrypted share material.
///
/// **Local JSON:** [shareEventToJson] keeps the `shardIndex` property name for
/// backward compatibility with any persisted maps.
typedef ShareEvent = ({
  String eventId,
  String recipientPubkey, // Hex format
  String encryptedContent,
  String backupConfigId,
  int shareIndex,
  DateTime createdAt,
  DateTime? publishedAt,
  EventStatus status,
});

/// Create a new [ShareEvent] with validation
ShareEvent createShareEvent({
  required String eventId,
  required String recipientPubkey, // Hex format
  required String encryptedContent,
  required String backupConfigId,
  required int shareIndex,
}) {
  if (!_isValidEventId(eventId)) {
    throw ArgumentError('Invalid event ID format: $eventId');
  }
  if (!_isValidHexPubkey(recipientPubkey)) {
    throw ArgumentError('Invalid recipient pubkey format: $recipientPubkey');
  }
  if (shareIndex < 0) {
    throw ArgumentError('Share index must be >= 0');
  }
  if (encryptedContent.isEmpty) {
    throw ArgumentError('Encrypted content cannot be empty');
  }

  return (
    eventId: eventId,
    recipientPubkey: recipientPubkey,
    encryptedContent: encryptedContent,
    backupConfigId: backupConfigId,
    shareIndex: shareIndex,
    createdAt: DateTime.now(),
    publishedAt: null,
    status: EventStatus.created,
  );
}

/// Create a copy of this [ShareEvent] with updated fields
ShareEvent copyShareEvent(
  ShareEvent event, {
  String? eventId,
  String? recipientPubkey, // Hex format
  String? encryptedContent,
  String? backupConfigId,
  int? shareIndex,
  DateTime? createdAt,
  DateTime? publishedAt,
  EventStatus? status,
}) {
  return (
    eventId: eventId ?? event.eventId,
    recipientPubkey: recipientPubkey ?? event.recipientPubkey,
    encryptedContent: encryptedContent ?? event.encryptedContent,
    backupConfigId: backupConfigId ?? event.backupConfigId,
    shareIndex: shareIndex ?? event.shareIndex,
    createdAt: createdAt ?? event.createdAt,
    publishedAt: publishedAt ?? event.publishedAt,
    status: status ?? event.status,
  );
}

/// Extension methods for [ShareEvent]
extension ShareEventExtension on ShareEvent {
  /// Check if this event has been published
  bool get isPublished {
    return status == EventStatus.published || status == EventStatus.confirmed;
  }

  /// Check if this event has been confirmed by recipient
  bool get isConfirmed {
    return status == EventStatus.confirmed;
  }

  /// Check if this event has failed
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

/// Convert to JSON for storage (legacy key `shardIndex` unchanged).
Map<String, dynamic> shareEventToJson(ShareEvent event) {
  return {
    'eventId': event.eventId,
    'recipientPubkey': event.recipientPubkey, // Store hex format
    'encryptedContent': event.encryptedContent,
    'backupConfigId': event.backupConfigId,
    'shardIndex': event.shareIndex,
    'createdAt': event.createdAt.toIso8601String(),
    'publishedAt': event.publishedAt?.toIso8601String(),
    'status': event.status.name,
  };
}

/// Create from JSON
ShareEvent shareEventFromJson(Map<String, dynamic> json) {
  return (
    eventId: json['eventId'] as String,
    recipientPubkey: json['recipientPubkey'] as String, // Read hex format
    encryptedContent: json['encryptedContent'] as String,
    backupConfigId: json['backupConfigId'] as String,
    shareIndex: json['shardIndex'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
    publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt'] as String) : null,
    status: EventStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => EventStatus.created,
    ),
  );
}

/// String representation of [ShareEvent]
String shareEventToString(ShareEvent event) {
  return 'ShareEvent(eventId: ${event.eventId.substring(0, 8)}..., '
      'recipient: ${event.recipientPubkey.substring(0, 8)}..., '
      'status: ${event.status}, shareIndex: ${event.shareIndex})';
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
