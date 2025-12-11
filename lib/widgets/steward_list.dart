import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/vault.dart';
import '../models/steward.dart';
import '../models/steward_status.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import '../screens/backup_config_screen.dart';

/// Widget for displaying list of stewards who have shards
class StewardList extends ConsumerWidget {
  final String vaultId;

  const StewardList({super.key, required this.vaultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(vaultProvider(vaultId));
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

    return vaultAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Stewards',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading stewards: $error',
                style: TextStyle(color: Colors.red[600]),
              ),
            ],
          ),
        ),
      ),
      data: (vault) {
        if (vault == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Vault not found'),
            ),
          );
        }

        return currentPubkeyAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading user info: $error'),
            ),
          ),
          data: (currentPubkey) =>
              _buildKeyHolderContent(context, ref, vault, currentPubkey),
        );
      },
    );
  }

  Widget _buildKeyHolderContent(
    BuildContext context,
    WidgetRef ref,
    Vault vault,
    String? currentPubkey,
  ) {
    final stewards = _extractStewards(vault, currentPubkey);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 4),
              Icon(Icons.people, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Text(
                'Stewards',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Only show settings button for owner
              if (currentPubkey != null && currentPubkey == vault.ownerPubkey)
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BackupConfigScreen(vaultId: vault.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (stewards.isEmpty) ...[
            // Empty state
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.key_off,
                    size: 48,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No stewards configured',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Change backup settings to add stewards',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Steward list with dividers
            Column(
              children: [
                for (int i = 0; i < stewards.length; i++) ...[
                  _buildStewardItem(context, stewards[i]),
                  if (i < stewards.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStewardItem(BuildContext context, StewardInfo steward) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colorScheme.surfaceContainer),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
            child: Icon(
              steward.isOwner ? Icons.person : Icons.key,
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        steward.displayName ??
                            (steward.pubkey != null
                                ? Helpers.encodeBech32(steward.pubkey!, 'npub')
                                : 'Unknown'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
                if (steward.isOwner) ...[
                  Text(
                    'Owner',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else if (steward.status != null) ...[
                  Text(
                    steward.status!.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Extract stewards from vault shard data
  List<StewardInfo> _extractStewards(Vault vault, String? currentPubkey) {
    // NEW: Try backupConfig first (owner will have this)
    if (vault.backupConfig != null) {
      final stewards = vault.backupConfig!.stewards.map((s) {
        final isCurrentUser =
            currentPubkey != null && s.pubkey == currentPubkey;
        final displayName = isCurrentUser
            ? 'You (${s.displayName})'
            : s.displayName;
        return StewardInfo(
          pubkey: s.pubkey,
          displayName: displayName,
          isOwner: s.pubkey != null && s.pubkey == vault.ownerPubkey,
          status: s.status, // Use actual status from Steward model
        );
      }).toList();

      // Sort: owner first, then others
      stewards.sort((a, b) {
        if (a.isOwner && !b.isOwner) return -1;
        if (!a.isOwner && b.isOwner) return 1;
        return 0;
      });

      return stewards;
    }

    // FALLBACK: Use shard peers (steward perspective)
    if (vault.shards.isEmpty) {
      return [];
    }

    final shard = vault.shards.first;
    final stewards = <StewardInfo>[];

    // Add owner first if ownerName is available
    if (shard.ownerName != null) {
      final isCurrentUser =
          currentPubkey != null && shard.creatorPubkey == currentPubkey;
      final ownerDisplayName = isCurrentUser
          ? 'You (${shard.ownerName})'
          : shard.ownerName;
      stewards.add(
        StewardInfo(
          pubkey: shard.creatorPubkey,
          displayName: ownerDisplayName,
          isOwner: true,
          status: StewardStatus.holdingKey,
        ),
      );
    }

    // Add peers (stewards) - now a list of maps with name and pubkey
    if (shard.peers != null) {
      for (final peer in shard.peers!) {
        final peerPubkey = peer['pubkey'];
        final peerName = peer['name'];
        if (peerPubkey == null) continue;

        final isCurrentUser =
            currentPubkey != null && peerPubkey == currentPubkey;
        final displayName = isCurrentUser && peerName != null
            ? 'You ($peerName)'
            : peerName;

        stewards.add(
          StewardInfo(
            pubkey: peerPubkey,
            displayName: displayName,
            isOwner: peerPubkey == vault.ownerPubkey,
            status:
                StewardStatus.holdingKey, // Default for stewards with shards
          ),
        );
      }
    }

    // Sort: owner first, then others
    stewards.sort((a, b) {
      if (a.isOwner && !b.isOwner) return -1;
      if (!a.isOwner && b.isOwner) return 1;
      return 0;
    });

    return stewards;
  }
}

/// Data class for steward information
class StewardInfo {
  final String? pubkey; // Nullable for invited stewards
  final String? displayName;
  final bool isOwner;
  final StewardStatus? status; // Status from Steward model

  StewardInfo({
    this.pubkey,
    this.displayName,
    required this.isOwner,
    this.status,
  });
}
