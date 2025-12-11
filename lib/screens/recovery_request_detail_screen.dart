import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/vault.dart';
import '../models/steward.dart';
import '../services/recovery_service.dart';
import '../providers/key_provider.dart';
import '../services/logger.dart';
import '../providers/recovery_provider.dart';
import '../providers/vault_provider.dart';
import '../widgets/row_button_stack.dart';

/// Screen for viewing and responding to a recovery request
class RecoveryRequestDetailScreen extends ConsumerStatefulWidget {
  final RecoveryRequest recoveryRequest;

  const RecoveryRequestDetailScreen({super.key, required this.recoveryRequest});

  @override
  ConsumerState<RecoveryRequestDetailScreen> createState() =>
      _RecoveryRequestDetailScreenState();
}

class _RecoveryRequestDetailScreenState
    extends ConsumerState<RecoveryRequestDetailScreen> {
  bool _isLoading = false;
  String? _currentPubkey;

  @override
  void initState() {
    super.initState();
    _loadCurrentPubkey();
  }

  Future<void> _loadCurrentPubkey() async {
    try {
      final loginService = ref.read(loginServiceProvider);
      final pubkey = await loginService.getCurrentPublicKey();
      if (mounted) {
        setState(() {
          _currentPubkey = pubkey;
        });
      }
    } catch (e) {
      Log.error('Error loading current pubkey', e);
    }
  }

  Future<void> _respondToRequest(RecoveryResponseStatus status) async {
    if (_currentPubkey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Could not load current user')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final approved = status == RecoveryResponseStatus.approved;

      // Use the convenience method that handles shard retrieval and Nostr sending
      await ref
          .read(recoveryServiceProvider)
          .respondToRecoveryRequestWithShard(
            widget.recoveryRequest.id,
            _currentPubkey!,
            approved,
          );

      if (mounted) {
        // Invalidate the recovery status provider to force a refresh when navigating back
        ref.invalidate(recoveryStatusProvider(widget.recoveryRequest.vaultId));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == RecoveryResponseStatus.approved
                  ? 'Recovery request approved and key sent'
                  : 'Recovery request denied',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Log.error('Error responding to recovery request', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showApprovalDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Recovery'),
        content: const Text(
          'Are you sure you want to approve this recovery request? '
          'This will share your key to the vault with the requester.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _respondToRequest(RecoveryResponseStatus.approved);
    }
  }

  Future<void> _showDenialDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny Recovery'),
        content: const Text(
          'Are you sure you want to deny this recovery request? '
          'The requester will not receive your key.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deny'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _respondToRequest(RecoveryResponseStatus.denied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.recoveryRequest;
    final vaultAsync = ref.watch(vaultProvider(request.vaultId));

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Request'), centerTitle: false),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : vaultAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Error loading vault: $error')),
              data: (vault) => _buildContent(context, request, vault),
            ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    RecoveryRequest request,
    Vault? vault,
  ) {
    // Get initiator name from vault shard data
    String? initiatorName;
    if (vault != null) {
      // First check vault ownerName
      if (vault.ownerPubkey == request.initiatorPubkey) {
        initiatorName = vault.ownerName;
      }

      // If not found and we have shards, check shard data
      if (initiatorName == null && vault.shards.isNotEmpty) {
        final firstShard = vault.shards.first;
        // Check if initiator is the owner
        if (firstShard.creatorPubkey == request.initiatorPubkey) {
          initiatorName = firstShard.ownerName ?? vault.ownerName;
        } else if (firstShard.peers != null) {
          // Check if initiator is in peers
          for (final peer in firstShard.peers!) {
            if (peer['pubkey'] == request.initiatorPubkey) {
              initiatorName = peer['name'];
              break;
            }
          }
        }
      }

      // Also check backupConfig
      if (initiatorName == null && vault.backupConfig != null) {
        try {
          final keyHolder = vault.backupConfig!.stewards.firstWhere(
            (kh) => kh.pubkey == request.initiatorPubkey,
          );
          initiatorName = keyHolder.displayName;
        } catch (e) {
          // Key holder not found in backupConfig
        }
      }
    }

    // Get instructions from vault
    String? instructions;
    if (vault != null) {
      // First try to get from backupConfig
      if (vault.backupConfig?.instructions != null &&
          vault.backupConfig!.instructions!.isNotEmpty) {
        instructions = vault.backupConfig!.instructions;
      } else if (vault.shards.isNotEmpty) {
        // Fallback to shard data
        instructions = vault.shards.first.instructions;
      }
    }

    // Get vault name and owner name
    final vaultName = vault?.name ?? 'Unknown Vault';
    final ownerName = vault?.ownerName ?? 'Unknown Owner';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Practice request banner
                if (request.isPractice) ...[
                  Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.school,
                            color: Theme.of(context).colorScheme.tertiary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Practice Request',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onTertiary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This is a practice request. No vault data will be shared.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onTertiaryContainer,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Alert card (neutral colors, no orange)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Someone is requesting recovery of a vault you have a key for',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Instructions section (moved up)
                if (instructions != null && instructions.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recovery Instructions (from owner)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            instructions,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Request details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Vault Name', vaultName),
                        _buildInfoRow('Owner Name', ownerName),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Initiator info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Initiator',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (initiatorName != null)
                                    Text(
                                      initiatorName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action buttons (RowButtonStack at bottom)
        if (request.status.isActive)
          RowButtonStack(
            buttons: [
              RowButtonConfig(
                onPressed: _showDenialDialog,
                icon: Icons.cancel,
                text: 'Deny',
              ),
              RowButtonConfig(
                onPressed: _showApprovalDialog,
                icon: Icons.check_circle,
                text: 'Approve',
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
