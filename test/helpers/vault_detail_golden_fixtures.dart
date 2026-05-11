import 'package:horcrux/models/share.dart';
import 'package:horcrux/models/vault.dart';
import 'package:horcrux/models/vault_detail.dart';

/// Builds an [OwnedVaultDetail] from a legacy [Vault] golden fixture so tests
/// can override [vaultDetailProvider] instead of the removed [vaultProvider]
/// read path on detail-oriented widgets.
OwnedVaultDetail ownedVaultDetailFromVault(
  Vault vault, {
  String content = 'placeholder-ciphertext',
  Share? selfHeldShare,
}) {
  final bc = vault.backupConfig;
  return OwnedVaultDetail(
    id: vault.id,
    name: vault.name,
    ownerPubkey: vault.ownerPubkey,
    ownerName: vault.ownerName,
    threshold: bc?.threshold ?? 0,
    totalShares: bc?.totalKeys ?? 0,
    stewards: bc?.stewards ?? const [],
    recoveryRequests: vault.recoveryRequests,
    pushEnabled: vault.pushEnabled,
    createdAt: vault.createdAt,
    archivedAt: vault.archivedAt,
    archivedReason: vault.archivedReason,
    backupConfig: vault.backupConfig,
    content: content,
    selfHeldShare: selfHeldShare,
  );
}

/// Builds a [StewardedVaultDetail] for steward-side golden fixtures.
StewardedVaultDetail stewardedVaultDetailFromVault(
  Vault vault, {
  required Share? latestShare,
}) {
  final bc = vault.backupConfig;
  return StewardedVaultDetail(
    id: vault.id,
    name: vault.name,
    ownerPubkey: vault.ownerPubkey,
    ownerName: vault.ownerName,
    threshold: bc?.threshold ?? 0,
    totalShares: bc?.totalKeys ?? 0,
    stewards: bc?.stewards ?? const [],
    recoveryRequests: vault.recoveryRequests,
    pushEnabled: vault.pushEnabled,
    createdAt: vault.createdAt,
    archivedAt: vault.archivedAt,
    archivedReason: vault.archivedReason,
    backupConfig: vault.backupConfig,
    latestShare: latestShare,
  );
}
