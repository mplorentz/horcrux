import 'package:ndk/shared/nips/nip01/helpers.dart';

import '../models/backup_config.dart';
import '../models/vault.dart';
import '../models/vault_detail.dart';
import 'validators.dart';

/// Short npub-style label (`npub1abcd...wxyz`) from a 64-character hex pubkey.
///
/// Used when no human-readable name is available; matches the fallback in
/// [Steward.displayName].
String shortNpub(String hexPubkey) {
  if (!isValidHexPubkey(hexPubkey)) {
    return 'Unknown';
  }
  try {
    final npub = Helpers.encodeBech32(hexPubkey, 'npub');
    if (npub.length <= 16) {
      return npub;
    }
    return '${npub.substring(0, 8)}...${npub.substring(npub.length - 8)}';
  } catch (_) {
    return '${hexPubkey.substring(0, 8)}...';
  }
}

/// Explicit name from [vault] for [hexPubkey], or null if none (no vault or no metadata name).
///
/// Uses non-empty [Vault.ownerName], [Steward.name] in [Vault.backupConfig], and names from
/// the newest shard's creator / embedded stewards only (no [shortNpub] fallback).
String? displayNameFromPubkeyOrNull(Vault? vault, String hexPubkey) {
  if (vault == null) return null;
  return _nameFromComponents(vault.ownerPubkey, vault.ownerName, vault.backupConfig, hexPubkey);
}

/// Display label for [hexPubkey] using [vault] when non-null; otherwise [shortNpub].
String displayNameFromPubkey(Vault? vault, String hexPubkey) {
  return displayNameFromPubkeyOrNull(vault, hexPubkey) ?? shortNpub(hexPubkey);
}

/// Explicit name from [vault] (a [VaultDetail]) for [hexPubkey], or null.
///
/// Mirrors [displayNameFromPubkeyOrNull] for the [VaultDetail] read model.
String? displayNameFromDetailOrNull(VaultDetail? vault, String hexPubkey) {
  if (vault == null) return null;
  return _nameFromComponents(vault.ownerPubkey, vault.ownerName, vault.backupConfig, hexPubkey);
}

String? _nameFromComponents(
  String ownerPubkey,
  String? ownerName,
  BackupConfig? backupConfig,
  String hexPubkey,
) {
  if (ownerPubkey == hexPubkey) {
    final n = ownerName;
    if (n != null && n.isNotEmpty) return n;
  }
  final configStewards = backupConfig?.stewards;
  if (configStewards != null) {
    for (final s in configStewards) {
      if (s.pubkey == hexPubkey) {
        final n = s.name;
        if (n != null && n.isNotEmpty) return n;
        break;
      }
    }
  }
  return null;
}
