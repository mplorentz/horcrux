import 'package:horcrux/models/steward.dart';
import 'package:horcrux/models/steward_status.dart';

/// Creates a test steward for use in tests.
///
/// This helper function consolidates steward creation logic that was previously
/// duplicated across multiple test files. It provides sensible defaults while
/// allowing customization of all steward properties.
///
/// Example usage:
/// ```dart
/// final steward = createTestSteward(
///   pubkey: TestHexPubkeys.alice,
///   name: 'Alice',
///   contactInfo: 'alice@example.com',
/// );
/// ```
///
/// Parameters:
/// - [pubkey] - The hex-encoded public key (required)
/// - [name] - Optional name for the steward
/// - [status] - Steward status (defaults to [StewardStatus.holdingKey])
/// - [contactInfo] - Optional contact information (defaults to null)
/// - [acknowledgedAt] - Optional acknowledgment timestamp. If null, defaults to
///   1 hour ago for stewards with status [StewardStatus.holdingKey], otherwise null.
///   Pass `null` explicitly to set it to null (useful for some test scenarios).
/// - [acknowledgedDistributionVersion] - Optional distribution version. If null,
///   defaults to 1 for stewards with status [StewardStatus.holdingKey], otherwise null.
///   Pass `null` explicitly to set it to null (useful for some test scenarios).
/// - [isOwner] - Whether this steward is the vault owner (defaults to false)
Steward createTestSteward({
  required String pubkey,
  String? name,
  StewardStatus status = StewardStatus.holdingKey,
  String? contactInfo,
  DateTime? acknowledgedAt,
  int? acknowledgedDistributionVersion,
  bool isOwner = false,
}) {
  // Default acknowledgedAt to 1 hour ago for stewards holding keys
  // Note: In Dart, we can't distinguish between "not provided" and "explicitly null"
  // So if null is explicitly passed, it will still use the default for holdingKey status
  final effectiveAcknowledgedAt = acknowledgedAt ??
      (status == StewardStatus.holdingKey
          ? DateTime.now().subtract(const Duration(hours: 1))
          : null);

  // Default distribution version to 1 for stewards holding keys, null otherwise
  // Note: In Dart, we can't distinguish between "not provided" and "explicitly null"
  // So if null is explicitly passed, it will still use the default for holdingKey status
  final effectiveDistributionVersion =
      acknowledgedDistributionVersion ?? (status == StewardStatus.holdingKey ? 1 : null);

  return Steward(
    id: pubkey.substring(0, 16),
    pubkey: pubkey,
    name: name,
    inviteCode: null,
    status: status,
    lastSeen: null,
    keyShare: null,
    giftWrapEventId: null,
    acknowledgedAt: effectiveAcknowledgedAt,
    acknowledgmentEventId: null,
    acknowledgedDistributionVersion: effectiveDistributionVersion,
    isOwner: isOwner,
    contactInfo: contactInfo,
  );
}

/// Creates a test steward for an invited steward (no pubkey yet).
///
/// This helper is specifically for creating stewards that have been invited
/// but haven't yet accepted the invitation.
///
/// Example usage:
/// ```dart
/// final invitedSteward = createTestInvitedSteward(
///   name: 'Bob',
///   inviteCode: 'abc123',
///   contactInfo: 'bob@example.com',
/// );
/// ```
///
/// Parameters:
/// - [name] - The name of the invited steward (required)
/// - [inviteCode] - The invitation code (required)
/// - [contactInfo] - Optional contact information (defaults to null)
Steward createTestInvitedSteward({
  required String name,
  required String inviteCode,
  String? contactInfo,
}) {
  return createInvitedSteward(
    name: name,
    inviteCode: inviteCode,
    contactInfo: contactInfo,
  );
}
