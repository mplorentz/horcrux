import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault.dart';
import '../models/vault_detail.dart';
import '../models/steward_status.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import 'name_label.dart';
import 'steward_details_dialog.dart';

/// Widget for displaying list of stewards who have shards
class StewardList extends ConsumerWidget {
  final String vaultId;

  const StewardList({super.key, required this.vaultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(vaultDetailProvider(vaultId));
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
          data: (currentPubkey) {
            // Hide steward list when vault is awaiting a shard and current user is a steward
            // (not the owner) — stewards waiting for their shard shouldn't see an empty steward list
            final isOwner = currentPubkey != null && vault.isVaultOwner(currentPubkey);
            if (vault.state == VaultState.awaitingShare && !isOwner) {
              // Return empty widget - background fill handled at screen level
              return const SizedBox.shrink();
            }
            return _buildKeyHolderContent(context, ref, vault, currentPubkey);
          },
        );
      },
    );
  }

  Widget _buildKeyHolderContent(
    BuildContext context,
    WidgetRef ref,
    VaultDetail vault,
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
                    'Add stewards in your recovery plan',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Steward list with dividers
            // Only show steward status if current user is the owner
            // Stewards can't read confirmation events from other stewards
            Builder(
              builder: (context) {
                final isOwner = currentPubkey != null && currentPubkey == vault.ownerPubkey;
                return Column(
                  children: [
                    for (int i = 0; i < stewards.length; i++) ...[
                      _buildStewardItem(context, stewards[i], isOwner: isOwner),
                      if (i < stewards.length - 1) const Divider(height: 1),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStewardItem(
    BuildContext context,
    StewardInfo steward, {
    required bool isOwner,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          StewardDetailsDialog.show(
            context,
            pubkey: steward.pubkey,
            displayName: steward.displayName,
            contactInfo: steward.contactInfo,
            isOwner: steward.isOwner,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(12),
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
                          child: NameLabel(
                            name: steward.displayName,
                            pubkey: steward.pubkey,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
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
                    ] else if (steward.status != null && isOwner) ...[
                      // Only show steward status if current user is the owner
                      // Stewards can't read confirmation events from other stewards
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
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Extract stewards from normalized vault metadata.
  List<StewardInfo> _extractStewards(VaultDetail vault, String? currentPubkey) {
    final normalizedStewards = (vault.backupConfig?.stewards.isNotEmpty == true)
        ? vault.backupConfig!.stewards
        : vault.stewards;

    if (normalizedStewards.isNotEmpty) {
      final stewards = normalizedStewards.where((s) {
        // Show invited stewards (no pubkey yet) so owners can see pending invitees.
        if (s.pubkey == null) {
          return true;
        }
        if (s.isOwner) {
          return s.status == StewardStatus.holdingKey;
        }
        return true;
      }).map((s) {
        final isCurrentUser = currentPubkey != null && s.pubkey == currentPubkey;
        final displayName = isCurrentUser ? '${s.displayName} (You)' : s.displayName;
        return StewardInfo(
          pubkey: s.pubkey,
          displayName: displayName,
          // TODO(Phase 3): gate contactInfo on vault.hasActiveRecovery once the
          // recovery_requests table is populated by VaultDetailRepository. Until
          // then recoveryRequests is always empty, so hasActiveRecovery is always
          // false and contact info would be unconditionally hidden.
          contactInfo: s.contactInfo,
          isOwner: s.isOwner,
          status: s.status,
        );
      }).toList();

      stewards.sort((a, b) {
        if (a.isOwner && !b.isOwner) return -1;
        if (!a.isOwner && b.isOwner) return 1;
        return 0;
      });

      return stewards;
    }

    return [];
  }
}

/// Data class for steward information
class StewardInfo {
  final String? pubkey; // Nullable for invited stewards
  final String? displayName;
  final String? contactInfo;
  final bool isOwner;
  final StewardStatus? status; // Status from Steward model

  StewardInfo({
    this.pubkey,
    this.displayName,
    this.contactInfo,
    required this.isOwner,
    this.status,
  });
}
