import 'invitation_status.dart';
import '../utils/validators.dart';

/// Default vault name used when no specific vault name is provided
const String defaultVaultName = 'Shared Vault';

/// Represents a generated invitation link that can be shared with an invitee
///
/// Public keys are stored in hex format (64 characters) internally.
/// Relay URLs must be valid WebSocket URLs (wss:// or ws://).
typedef InvitationLink = ({
  String inviteCode, // Base64URL encoded 32-byte random string
  String vaultId, // ID of the vault being shared
  String vaultName, // Name of the vault being shared (null when not available)
  String ownerPubkey, // Hex format (64 chars) - vault owner's public key
  List<String> relayUrls, // Up to 3 relay URLs for communication
  String? inviteeName, // Name entered by vault owner (null when received via deep link)
  DateTime createdAt, // When invitation was generated
  InvitationStatus status, // Current status of invitation
  String? redeemedBy, // Hex pubkey of redeemer (null if not redeemed)
  DateTime? redeemedAt, // When invitation was redeemed (null if not redeemed)
});

/// Creates a new invitation link with the given parameters
InvitationLink createInvitationLink({
  required String inviteCode,
  required String vaultId,
  required String ownerPubkey,
  required List<String> relayUrls,
  String? vaultName,
  String? inviteeName,
}) {
  return (
    inviteCode: inviteCode,
    vaultId: vaultId,
    vaultName: vaultName ?? defaultVaultName,
    ownerPubkey: ownerPubkey,
    relayUrls: relayUrls,
    inviteeName: inviteeName,
    createdAt: DateTime.now(),
    status: InvitationStatus.created,
    redeemedBy: null,
    redeemedAt: null,
  );
}

/// Extension methods for InvitationLink
extension InvitationLinkExtension on InvitationLink {
  /// Updates the invitation status and optional redemption information
  InvitationLink updateStatus(
    InvitationStatus status, {
    String? redeemedBy,
    DateTime? redeemedAt,
  }) {
    return (
      inviteCode: inviteCode,
      vaultId: vaultId,
      vaultName: vaultName,
      ownerPubkey: ownerPubkey,
      relayUrls: relayUrls,
      inviteeName: inviteeName,
      createdAt: createdAt,
      status: status,
      redeemedBy: redeemedBy,
      redeemedAt: redeemedAt,
    );
  }

  /// Generates an invitation URL from this InvitationLink
  ///
  /// Format: horcrux://horcrux.app/invite/{inviteCode}?vault={vaultId}&name={vaultName}&owner={ownerPubkey}&relays={relayUrls}
  /// Relay URLs are comma-separated and URL-encoded.
  String toUrl() {
    final baseUrl = 'horcrux://horcrux.app/invite/$inviteCode';
    final params = <String>[];

    params.add('vault=${Uri.encodeComponent(vaultId)}');
    params.add('name=${Uri.encodeComponent(vaultName)}');
    params.add('owner=${Uri.encodeComponent(ownerPubkey)}');

    if (relayUrls.isNotEmpty) {
      final encodedRelays = relayUrls.map((url) => Uri.encodeComponent(url)).join(',');
      params.add('relays=$encodedRelays');
    }

    return '$baseUrl?${params.join('&')}';
  }
}

/// Converts an InvitationLink to JSON for storage
Map<String, dynamic> invitationLinkToJson(InvitationLink link) {
  return {
    'inviteCode': link.inviteCode,
    'vaultId': link.vaultId,
    'vaultName': link.vaultName,
    'ownerPubkey': link.ownerPubkey,
    'relayUrls': link.relayUrls,
    'inviteeName': link.inviteeName,
    'createdAt': link.createdAt.toIso8601String(),
    'status': link.status.name,
    'redeemedBy': link.redeemedBy,
    'redeemedAt': link.redeemedAt?.toIso8601String(),
  };
}

/// Converts JSON to an InvitationLink
InvitationLink invitationLinkFromJson(Map<String, dynamic> json) {
  return (
    inviteCode: json['inviteCode'] as String,
    vaultId: json['vaultId'] as String,
    vaultName: json['vaultName'] as String? ?? defaultVaultName,
    ownerPubkey: json['ownerPubkey'] as String,
    relayUrls: List<String>.from(json['relayUrls'] as List),
    inviteeName: json['inviteeName'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    status: InvitationStatus.values.firstWhere(
      (e) => e.name == json['status'] as String,
    ),
    redeemedBy: json['redeemedBy'] as String?,
    redeemedAt: json['redeemedAt'] != null ? DateTime.parse(json['redeemedAt'] as String) : null,
  );
}

/// Validation functions for InvitationLink fields

/// Validates all relay URLs in a list
///
/// Returns true if all URLs are valid, false otherwise
bool areValidRelayUrls(List<String> relayUrls) {
  if (relayUrls.isEmpty) return false;
  if (relayUrls.length > 3) return false; // Max 3 relay URLs

  return relayUrls.every((url) => isValidRelayUrl(url));
}

/// Validates an InvitationLink's core fields
///
/// Checks invite code format, owner pubkey format, and relay URLs
/// Throws ArgumentError with descriptive message if validation fails
void validateInvitationLink(InvitationLink link) {
  if (!isValidInviteCode(link.inviteCode)) {
    throw ArgumentError(
      'Invalid invite code format: must be Base64URL encoded',
    );
  }

  if (!isValidHexPubkey(link.ownerPubkey)) {
    throw ArgumentError('Invalid owner pubkey: must be 64 hex characters');
  }

  if (!areValidRelayUrls(link.relayUrls)) {
    throw ArgumentError(
      'Invalid relay URLs: must be 1-3 valid WebSocket URLs (wss:// or ws://)',
    );
  }

  // inviteeName can be null (for received invitations), but if provided, must not be empty
  if (link.inviteeName != null && link.inviteeName!.trim().isEmpty) {
    throw ArgumentError('Invitee name cannot be empty');
  }

  if (link.redeemedBy != null && !isValidHexPubkey(link.redeemedBy!)) {
    throw ArgumentError(
      'Invalid redeemed-by pubkey: must be 64 hex characters',
    );
  }
}
