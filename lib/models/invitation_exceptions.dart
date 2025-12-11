/// Exception thrown when an invitation code is not found in storage
class InvitationNotFoundException implements Exception {
  final String inviteCode;

  InvitationNotFoundException(this.inviteCode);

  @override
  String toString() => 'InvitationNotFoundException: Invitation code not found: $inviteCode';
}

/// Exception thrown when an invitation code has already been redeemed
class InvitationAlreadyRedeemedException implements Exception {
  final String inviteCode;

  InvitationAlreadyRedeemedException(this.inviteCode);

  @override
  String toString() =>
      'InvitationAlreadyRedeemedException: Invitation code already redeemed: $inviteCode';
}

/// Exception thrown when an invitation code has been invalidated
class InvitationInvalidatedException implements Exception {
  final String inviteCode;
  final String reason;

  InvitationInvalidatedException(this.inviteCode, this.reason);

  @override
  String toString() =>
      'InvitationInvalidatedException: Invitation code invalidated: $inviteCode. Reason: $reason';
}

/// Exception thrown when an invitation link URL is malformed or invalid
class InvalidInvitationLinkException implements Exception {
  final String url;
  final String reason;

  InvalidInvitationLinkException(this.url, this.reason);

  @override
  String toString() =>
      'InvalidInvitationLinkException: Invalid invitation link: $url. Reason: $reason';
}
