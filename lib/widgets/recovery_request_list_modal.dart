import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/vault.dart';
import '../providers/vault_provider.dart';
import '../screens/recovery_request_detail_screen.dart';
import '../services/recovery_service.dart';
import '../services/logger.dart';

/// Modal bottom sheet showing list of pending recovery requests
class RecoveryRequestListModal extends ConsumerWidget {
  final List<RecoveryRequest> requests;

  const RecoveryRequestListModal({
    super.key,
    required this.requests,
  });

  static void show(BuildContext context, List<RecoveryRequest> requests) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecoveryRequestListModal(requests: requests),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications,
                    size: 20,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recovery Requests',
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        '${requests.length} pending request${requests.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List of requests
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              itemCount: requests.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 0.5,
              ),
              itemBuilder: (context, index) {
                return _buildNotificationItem(context, ref, requests[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    RecoveryRequest request,
  ) {
    final vaultAsync = ref.watch(vaultProvider(request.vaultId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return vaultAsync.when(
      loading: () => ListTile(
        leading: const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Loading...', style: theme.textTheme.bodyLarge),
      ),
      error: (error, stack) => ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 20,
          ),
        ),
        title: Text(
          'Error loading vault',
          style: theme.textTheme.bodyLarge,
        ),
      ),
      data: (vault) {
        final vaultName = vault?.name ?? 'Unknown Vault';
        final initiatorName = _getInitiatorName(vault, request.initiatorPubkey);

        return InkWell(
          onTap: () => _viewNotification(context, ref, request),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.restore,
                    size: 20,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with practice badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Recovery Request',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (request.isPractice)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Practice',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Initiator
                      if (initiatorName != null)
                        Text(
                          'From: $initiatorName',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      // Vault name
                      Text(
                        'Vault: $vaultName',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      // Time
                      Text(
                        _formatDateTime(request.requestedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _getInitiatorName(Vault? vault, String initiatorPubkey) {
    if (vault == null) return null;

    final shard = vault.mostRecentShard;

    // First check vault ownerName
    if (vault.ownerPubkey == initiatorPubkey) {
      return vault.ownerName;
    }

    // If not found and we have shards, check shard data
    if (shard != null) {
      // Check if initiator is the owner
      if (shard.creatorPubkey == initiatorPubkey) {
        return shard.ownerName ?? vault.ownerName;
      } else if (shard.stewards != null) {
        // Check if initiator is in stewards
        for (final steward in shard.stewards!) {
          if (steward['pubkey'] == initiatorPubkey) {
            return steward['name'];
          }
        }
      }
    }

    // Also check backupConfig
    if (vault.backupConfig != null) {
      try {
        final keyHolder = vault.backupConfig!.stewards.firstWhere(
          (kh) => kh.pubkey == initiatorPubkey,
        );
        return keyHolder.displayName;
      } catch (e) {
        // Key holder not found in backupConfig
      }
    }

    return null;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _viewNotification(
    BuildContext context,
    WidgetRef ref,
    RecoveryRequest request,
  ) async {
    try {
      await ref.read(recoveryServiceProvider).markNotificationAsViewed(request.id);

      if (context.mounted) {
        Navigator.pop(context); // Close modal
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecoveryRequestDetailScreen(recoveryRequest: request),
          ),
        );
      }
    } catch (e) {
      Log.error('Error viewing notification', e);
    }
  }
}
