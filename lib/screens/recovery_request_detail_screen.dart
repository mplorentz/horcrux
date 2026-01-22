import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/vault.dart';
import '../services/recovery_service.dart';
import '../providers/key_provider.dart';
import '../services/logger.dart';
import '../providers/recovery_provider.dart';
import '../providers/vault_provider.dart';
import '../widgets/row_button_stack.dart';
import '../widgets/horcrux_scaffold.dart';

/// Screen for viewing and responding to a recovery request
class RecoveryRequestDetailScreen extends ConsumerStatefulWidget {
  final RecoveryRequest recoveryRequest;

  const RecoveryRequestDetailScreen({super.key, required this.recoveryRequest});

  @override
  ConsumerState<RecoveryRequestDetailScreen> createState() => _RecoveryRequestDetailScreenState();
}

class _RecoveryRequestDetailScreenState extends ConsumerState<RecoveryRequestDetailScreen> {
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
      await ref.read(recoveryServiceProvider).respondToRecoveryRequestWithShard(
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

    return HorcruxScaffold(
      appBar: AppBar(
        title: const Text(
          'Recovery Request',
          overflow: TextOverflow.visible,
          maxLines: 2,
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : vaultAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error loading vault: $error')),
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
      final shard = vault.mostRecentShard;

      // First check vault ownerName
      if (vault.ownerPubkey == request.initiatorPubkey) {
        initiatorName = vault.ownerName;
      }

      // If not found and we have shards, check shard data
      if (initiatorName == null && shard != null) {
        // Check if initiator is the owner
        if (shard.creatorPubkey == request.initiatorPubkey) {
          initiatorName = shard.ownerName ?? vault.ownerName;
        } else if (shard.stewards != null) {
          // Check if initiator is in stewards
          for (final steward in shard.stewards!) {
            if (steward['pubkey'] == request.initiatorPubkey) {
              initiatorName = steward['name'];
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
        instructions = vault.mostRecentShard?.instructions;
      }
    }

    // Get vault name and owner name
    final vaultName = vault?.name ?? 'Unknown Vault';
    final ownerName = vault?.ownerName ?? 'Unknown Owner';

    // Get initiator contact info from vault shard data
    String? initiatorContactInfo;
    if (vault != null) {
      // First check backupConfig
      if (vault.backupConfig != null) {
        try {
          final steward = vault.backupConfig!.stewards.firstWhere(
            (s) => s.pubkey == request.initiatorPubkey,
          );
          initiatorContactInfo = steward.contactInfo;
        } catch (e) {
          // Steward not found in backupConfig
        }
      }

      // Fallback to shard data
      if (initiatorContactInfo == null) {
        final shard = vault.mostRecentShard;
        if (shard?.stewards != null) {
          for (final steward in shard!.stewards!) {
            if (steward['pubkey'] == request.initiatorPubkey) {
              initiatorContactInfo = steward['contactInfo'];
              break;
            }
          }
        }
      }
    }

    // Get threshold from request
    final threshold = request.threshold;

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
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onTertiary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This is a practice request. No vault data will be shared.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                // Alert card with updated messaging
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                initiatorName != null
                                    ? '$initiatorName is trying to open $ownerName\'s vault named $vaultName.'
                                    : 'Someone is trying to open $ownerName\'s vault named $vaultName.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          initiatorName != null
                              ? 'You hold one of the keys to this vault. If you approve this request $initiatorName will receive your key. They need $threshold total keys to open the vault.'
                              : 'You hold one of the keys to this vault. If you approve this request the requester will receive your key. They need $threshold total keys to open the vault.',
                          style: Theme.of(context).textTheme.bodyMedium,
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
                              Expanded(
                                child: Text(
                                  'Here are the instructions that $ownerName gave when setting up the vault:',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
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

                // Contact info section (if available)
                if (initiatorContactInfo != null &&
                    initiatorContactInfo.isNotEmpty &&
                    initiatorName != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.contact_mail,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Contact Information',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Here is the contact info for $initiatorName. We recommend getting in touch with them to confirm their identity.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              initiatorContactInfo,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),

        // Action buttons (RowButtonStack at bottom)
        if (request.status.isActive)
          RowButtonStack(
            buttons: [
              RowButtonConfig(
                onPressed: () => Navigator.pop(context),
                icon: Icons.arrow_back,
                text: 'Go Back',
              ),
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
}
