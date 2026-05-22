import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault_detail.dart';
import '../providers/key_provider.dart';
import '../screens/vault_detail_screen.dart';
import 'name_label.dart';

/// A card widget displaying a vault summary for use in vault lists.
///
/// Shows the vault name, owner, and state icon. Tapping navigates to [VaultDetailScreen].
class VaultCard extends ConsumerWidget {
  final VaultDetail vault;

  const VaultCard({super.key, required this.vault});

  /// Returns display name for the vault owner. When [vault.ownerName] is null
  /// (e.g. not included in invitation link), returns null so [NameLabel] falls
  /// back to showing the npub.
  String? _getOwnerDisplayName(String? currentPubkey) {
    if (currentPubkey == vault.ownerPubkey) {
      return 'You';
    }
    return vault.ownerName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Show tombstone card for archived vaults
    if (vault.isArchived) {
      final reasonText = vault.archivedReason ?? 'Removed by owner';
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VaultDetailScreen(vaultId: vault.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.archive_outlined,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vault.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reasonText,
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);
    final currentPubkey = currentPubkeyAsync.maybeWhen(
      data: (pubkey) => pubkey,
      orElse: () => null,
    );
    final isVaultOwner = currentPubkey != null && vault.isVaultOwner(currentPubkey);

    // Stewards holding a share see a key icon; the vault owner who has deleted
    // their local content (travel mode) sees a closed lock instead of lock_open.
    final IconData stateIcon;
    Color? iconColor;

    switch (vault) {
      case OwnedVaultDetail():
        stateIcon = Icons.lock_open;
      case StewardedVaultDetail(:final latestShare) when latestShare != null:
        stateIcon = isVaultOwner ? Icons.lock : Icons.key;
      case StewardedVaultDetail():
        stateIcon = Icons.hourglass_empty;
    }
    final ownerDisplayName = _getOwnerDisplayName(currentPubkey);
    final (ownerText, ownerStyle) = NameLabel.getDisplayContent(
      name: ownerDisplayName,
      pubkey: vault.ownerPubkey,
      baseStyle: textTheme.bodySmall,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VaultDetailScreen(vaultId: vault.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              // Icon container with state-based icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  stateIcon,
                  color: iconColor ?? theme.colorScheme.onSurface,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vault.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Owner: ',
                                  style: textTheme.bodySmall,
                                ),
                                TextSpan(
                                  text: ownerText,
                                  style: ownerStyle ?? textTheme.bodySmall,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Date on the right
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
