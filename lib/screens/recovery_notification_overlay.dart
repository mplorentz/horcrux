import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/vault.dart';
import '../models/steward.dart';
import '../services/recovery_service.dart';
import '../services/logger.dart';
import '../providers/vault_provider.dart';
import 'recovery_request_detail_screen.dart';

/// Overlay widget for displaying recovery request notifications
class RecoveryNotificationOverlay extends ConsumerStatefulWidget {
  const RecoveryNotificationOverlay({super.key});

  @override
  ConsumerState<RecoveryNotificationOverlay> createState() => _RecoveryNotificationOverlayState();
}

class _RecoveryNotificationOverlayState extends ConsumerState<RecoveryNotificationOverlay> {
  List<RecoveryRequest> _pendingNotifications = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _listenToNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await ref.read(recoveryServiceProvider).getPendingNotifications();
      if (mounted) {
        setState(() {
          _pendingNotifications = notifications;
        });
      }
    } catch (e) {
      Log.error('Error loading notifications', e);
    }
  }

  void _listenToNotifications() {
    ref.read(recoveryServiceProvider).notificationStream.listen((
      notifications,
    ) {
      if (mounted) {
        setState(() {
          _pendingNotifications = notifications;
        });
      }
    });
  }

  Future<void> _viewNotification(RecoveryRequest request) async {
    try {
      await ref.read(recoveryServiceProvider).markNotificationAsViewed(request.id);

      if (mounted) {
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

  Future<void> _dismissNotification(RecoveryRequest request) async {
    try {
      await ref.read(recoveryServiceProvider).markNotificationAsViewed(request.id);
    } catch (e) {
      Log.error('Error dismissing notification', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingNotifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isExpanded ? 300 : 80,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        '${_pendingNotifications.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recovery Requests',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${_pendingNotifications.length} pending request${_pendingNotifications.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.expand_more : Icons.expand_less,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),

            // Notification list (when expanded)
            if (_isExpanded)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _pendingNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _pendingNotifications[index];
                    return _buildNotificationItem(notification);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(RecoveryRequest request) {
    final vaultAsync = ref.watch(vaultProvider(request.vaultId));

    return vaultAsync.when(
      loading: () => const Card(
        margin: EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircularProgressIndicator(strokeWidth: 2),
          title: Text('Loading...'),
        ),
      ),
      error: (error, stack) => const Card(
        margin: EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(Icons.error, color: Colors.red),
          title: Text('Error loading vault'),
        ),
      ),
      data: (vault) {
        final vaultName = vault?.name ?? 'Unknown Vault';
        final initiatorName = _getInitiatorName(vault, request.initiatorPubkey);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange[100],
              child: const Icon(Icons.lock_open, color: Colors.orange),
            ),
            title: Row(
              children: [
                const Text(
                  'Recovery Request',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (request.isPractice) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text(
                      'Practice',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'From: ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Expanded(
                      child: Text(
                        initiatorName ?? request.initiatorPubkey,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Vault: $vaultName',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  _formatDateTime(request.requestedAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => _dismissNotification(request),
                  tooltip: 'Dismiss',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () => _viewNotification(request),
                  color: Theme.of(context).primaryColor,
                  tooltip: 'View',
                ),
              ],
            ),
            onTap: () => _viewNotification(request),
          ),
        );
      },
    );
  }

  String? _getInitiatorName(Vault? vault, String initiatorPubkey) {
    if (vault == null) return null;

    // First check vault ownerName
    if (vault.ownerPubkey == initiatorPubkey) {
      return vault.ownerName;
    }

    // If not found and we have shards, check shard data
    if (vault.shards.isNotEmpty) {
      final firstShard = vault.shards.first;
      // Check if initiator is the owner
      if (firstShard.creatorPubkey == initiatorPubkey) {
        return firstShard.ownerName ?? vault.ownerName;
      } else if (firstShard.peers != null) {
        // Check if initiator is in peers
        for (final peer in firstShard.peers!) {
          if (peer['pubkey'] == initiatorPubkey) {
            return peer['name'];
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
}
