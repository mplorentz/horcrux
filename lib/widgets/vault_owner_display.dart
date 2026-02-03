import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault.dart';
import '../providers/key_provider.dart';
import 'person_display.dart';

/// Widget that displays the vault owner information above the status banner
class VaultOwnerDisplay extends ConsumerWidget {
  final Vault vault;
  final bool includePadding;

  const VaultOwnerDisplay({
    super.key,
    required this.vault,
    this.includePadding = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

    return currentPubkeyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (currentPubkey) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isCurrentUser = currentPubkey != null && vault.isOwned(currentPubkey);

        // Get owner display name
        final ownerDisplayName = isCurrentUser ? (vault.ownerName ?? 'You') : vault.ownerName;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Owner',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            PersonDisplay(
              name: ownerDisplayName,
              pubkey: vault.ownerPubkey,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

        if (includePadding) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon in square background with rounded corners
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                // Text content
                Expanded(
                  child: content,
                ),
              ],
            ),
          );
        }

        return content;
      },
    );
  }
}
