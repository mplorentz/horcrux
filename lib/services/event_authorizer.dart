import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';

import '../database/app_database.dart';
import '../database/app_database_provider.dart';
import '../models/nostr_kinds.dart';
import '../models/share.dart';
import '../models/vault.dart';
import '../providers/vault_provider.dart';

final eventAuthorizerProvider = Provider<EventAuthorizer>((ref) {
  return EventAuthorizer(
    ref.read(vaultRepositoryProvider),
    ref.watch(appDatabaseProvider),
  );
});

enum AuthDecision { allow, deny }

/// Authorizes unwrapped Horcrux Nostr events before they reach service handlers.
///
/// Each routed kind is listed explicitly. Unknown or unrouted kinds deny by
/// default so newly introduced handlers must add a reviewed policy first.
class EventAuthorizer {
  EventAuthorizer(this._vaultRepository, this._db);

  final VaultRepository _vaultRepository;
  final AppDatabase _db;

  Future<AuthDecision> authorize({
    required Nip01Event rumor,
    required String verifiedSenderPubkey,
  }) async {
    final kind = NostrKind.fromValue(rumor.kind);
    switch (kind) {
      case NostrKind.shareData:
        return _authorizeShareData(rumor, verifiedSenderPubkey);
      case NostrKind.invitationAcceptance:
        return _authorizeInvitation(rumor, verifiedSenderPubkey);
      case NostrKind.invitationDenial:
        return _authorizeInvitation(rumor, verifiedSenderPubkey);
      case NostrKind.recoveryRequest:
        return _authorizeStewardOrOwner(rumor, verifiedSenderPubkey);
      case NostrKind.recoveryResponse:
        return _authorizeRecoveryResponder(rumor, verifiedSenderPubkey);
      case NostrKind.shareConfirmation:
        return _authorizeKnownSteward(rumor, verifiedSenderPubkey);
      case NostrKind.keyHolderRemoved:
        return _authorizeOwnerOnly(rumor, verifiedSenderPubkey);

      // deny all kinds without handlers in NdkService.
      case NostrKind.seal:
      case NostrKind.giftWrap:
      case NostrKind.httpAuth:
      case NostrKind.shareError:
      case NostrKind.invitationInvalid:
      case null:
        return AuthDecision.deny;
    }
  }

  Future<AuthDecision> _authorizeShareData(Nip01Event rumor, String verifiedSenderPubkey) async {
    final share = shareFromNostr(rumor);
    final vaultId = share.vaultId;
    if (vaultId == null || vaultId.isEmpty) return AuthDecision.deny;
    if (verifiedSenderPubkey != share.creatorPubkey) return AuthDecision.deny;

    final existingVault = await _vaultRepository.getVault(vaultId);
    if (existingVault != null && share.creatorPubkey != existingVault.ownerPubkey) {
      return AuthDecision.deny;
    }
    return AuthDecision.allow;
  }

  Future<AuthDecision> _authorizeInvitation(
    Nip01Event rumor,
    String verifiedSenderPubkey,
  ) async {
    final inviteCode = _firstTagValue(rumor.tags, 'invite_code');
    if (inviteCode == null) return AuthDecision.deny;

    final invitation = await _db.invitationDao.getByCode(inviteCode);
    if (invitation == null) return AuthDecision.deny;
    final redeemedBy = invitation.acceptedByPubkey;
    if (redeemedBy != null && redeemedBy != verifiedSenderPubkey) {
      return AuthDecision.deny;
    }
    return AuthDecision.allow;
  }

  Future<AuthDecision> _authorizeOwnerOnly(Nip01Event rumor, String verifiedSenderPubkey) async {
    final vault = await _vaultFromEvent(rumor);
    if (vault == null) return AuthDecision.deny;
    return vault.ownerPubkey == verifiedSenderPubkey ? AuthDecision.allow : AuthDecision.deny;
  }

  Future<AuthDecision> _authorizeKnownSteward(Nip01Event rumor, String verifiedSenderPubkey) async {
    final vault = await _vaultFromEvent(rumor);
    if (vault == null) return AuthDecision.deny;
    return _isKnownSteward(vault, verifiedSenderPubkey) ? AuthDecision.allow : AuthDecision.deny;
  }

  Future<AuthDecision> _authorizeStewardOrOwner(
    Nip01Event rumor,
    String verifiedSenderPubkey,
  ) async {
    final vault = await _vaultFromEvent(rumor);
    if (vault == null) return AuthDecision.deny;
    final isMember =
        vault.ownerPubkey == verifiedSenderPubkey || _isKnownSteward(vault, verifiedSenderPubkey);
    return isMember ? AuthDecision.allow : AuthDecision.deny;
  }

  Future<AuthDecision> _authorizeRecoveryResponder(
    Nip01Event rumor,
    String verifiedSenderPubkey,
  ) async {
    final vaultId = _firstTagValue(rumor.tags, 'vault_id');
    final recoveryRequestId = _firstTagValue(rumor.tags, 'recovery_request_id');
    if (vaultId == null || recoveryRequestId == null) return AuthDecision.deny;

    final requests = await _vaultRepository.getRecoveryRequestsForVault(vaultId);
    for (final request in requests) {
      if (request.id == recoveryRequestId &&
          request.stewardPubkeys.contains(verifiedSenderPubkey)) {
        return AuthDecision.allow;
      }
    }
    return AuthDecision.deny;
  }

  Future<Vault?> _vaultFromEvent(Nip01Event rumor) async {
    final vaultId = _firstTagValue(rumor.tags, 'vault_id');
    if (vaultId == null) return null;
    return _vaultRepository.getVault(vaultId);
  }

  bool _isKnownSteward(Vault vault, String verifiedSenderPubkey) {
    final stewards = vault.backupConfig?.stewards ?? const [];
    return stewards.any((steward) => steward.pubkey == verifiedSenderPubkey);
  }

  String? _firstTagValue(List<List<String>> tags, String name) {
    for (final tag in tags) {
      if (tag.length >= 2 && tag[0] == name) {
        final value = tag[1];
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }
}
