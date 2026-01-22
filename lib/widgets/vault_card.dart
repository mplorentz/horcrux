import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/vault.dart';
import '../providers/key_provider.dart';
import '../screens/vault_detail_screen.dart';

class VaultCard extends ConsumerWidget {
  final Vault vault;

  const VaultCard({super.key, required this.vault});

  String _getOwnerDisplayText(String? currentPubkey) {
    if (currentPubkey == null) {
      return Helpers.encodeBech32(vault.ownerPubkey, 'npub');
    }
    if (currentPubkey == vault.ownerPubkey) {
      return 'You';
    }
    if (vault.ownerName != null && vault.ownerName!.isNotEmpty) {
      return vault.ownerName!;
    }
    return Helpers.encodeBech32(vault.ownerPubkey, 'npub');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Determine icon based on vault state
    // Note: Recovery state is user-specific and not part of vault.state anymore
    IconData stateIcon;
    Color? iconColor;

    switch (vault.state) {
      case VaultState.owned:
        stateIcon = Icons.lock_open;
        break;
      case VaultState.steward:
        stateIcon = Icons.key;
        break;
      case VaultState.awaitingKey:
        stateIcon = Icons.hourglass_empty;
        break;
    }

    // Get current user's pubkey and determine owner display
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);
    final currentPubkey = currentPubkeyAsync.maybeWhen(
      data: (pubkey) => pubkey,
      orElse: () => null,
    );
    final ownerDisplayText = _getOwnerDisplayText(currentPubkey);
    // Use monospace font only for npub display (not for names or "You")
    final isNpubDisplay = ownerDisplayText.startsWith('npub');

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
                    Text(
                      "Owner: $ownerDisplayText",
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: isNpubDisplay ? 'RobotoMono' : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
