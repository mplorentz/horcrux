import 'event_status.dart';

/// Lightweight tracking record for a distributed share gift wrap.
///
/// Carries only what's needed after publishing - the encrypted content
/// lives on the relay as a gift wrap event. [backupConfigId] was removed
/// because it was always equal to vaultId. [encryptedContent] was removed
/// because the gift wrap on the relay IS the ciphertext; storing it locally
/// is redundant and a security concern.
///
/// JSON serialization methods (shareEventToJson/shareEventFromJson) were
/// removed because no callers used them - the DB tracks steward status via
/// steward records, so ShareEvent is an in-memory tracking type only.
typedef ShareEvent = ({
  String giftWrapEventId,
  String recipientPubkey, // Hex format
  int shareIndex,
  DateTime createdAt,
  DateTime? publishedAt,
  EventStatus status,
});
