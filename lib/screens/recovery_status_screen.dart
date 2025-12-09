import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../providers/recovery_provider.dart';
import '../providers/vault_provider.dart';
import '../services/recovery_service.dart';
import '../widgets/recovery_progress_widget.dart';
import '../widgets/recovery_stewards_widget.dart';

/// Screen for displaying recovery request status and steward responses
class RecoveryStatusScreen extends ConsumerStatefulWidget {
  final String recoveryRequestId;

  const RecoveryStatusScreen({super.key, required this.recoveryRequestId});

  @override
  ConsumerState<RecoveryStatusScreen> createState() => _RecoveryStatusScreenState();
}

class _RecoveryStatusScreenState extends ConsumerState<RecoveryStatusScreen> {
  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(
      recoveryRequestByIdProvider(widget.recoveryRequestId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery'),
        centerTitle: false,
      ),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (request) {
          if (request == null) {
            return const Center(child: Text('Recovery request not found'));
          }

          // Get vault to extract instructions
          final vaultAsync = ref.watch(vaultProvider(request.vaultId));

          return vaultAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading vault: $error')),
            data: (vault) {
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

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Practice mode banner
                    if (request.isPractice) ...[
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.school,
                                color: Colors.blue[700],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Practice Recovery',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900],
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This is a practice recovery session. No vault data will be shared.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.blue[700],
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
                    // Instructions section
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
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Steward Instructions',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
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
                    RecoveryProgressWidget(
                      recoveryRequestId: widget.recoveryRequestId,
                    ),
                    const SizedBox(height: 16),
                    RecoveryStewardsWidget(
                      recoveryRequestId: widget.recoveryRequestId,
                    ),
                    const SizedBox(height: 16),
                    if (request.status.isActive) _buildCancelButton(),
                    if (request.status == RecoveryRequestStatus.completed)
                      _buildExitRecoveryButton(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildExitRecoveryButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _exitRecoveryMode,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.exit_to_app),
        label: const Text('End Recovery'),
      ),
    );
  }

  Future<void> _exitRecoveryMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Recovery'),
        content: const Text(
          'This will archive the recovery request and delete the recovered content and steward keys. '
          'Your own key to the vault will be preserved.\n\n'
          'Are you sure you want to end recovery?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('End Recovery'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Get vaultId before exiting recovery mode
        final request =
            await ref.read(recoveryServiceProvider).getRecoveryRequest(widget.recoveryRequestId);
        final vaultId = request?.vaultId;

        await ref.read(recoveryServiceProvider).exitRecoveryMode(widget.recoveryRequestId);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Ended recovery')));
          // Invalidate providers to refresh the UI
          ref.invalidate(recoveryRequestByIdProvider(widget.recoveryRequestId));
          if (vaultId != null) {
            ref.invalidate(vaultProvider(vaultId));
          }
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _cancelRecovery,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.cancel),
        label: const Text('Cancel Recovery Request'),
      ),
    );
  }

  Future<void> _cancelRecovery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Recovery'),
        content: const Text(
          'Are you sure you want to cancel this recovery request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Get vaultId before canceling recovery request
        final request =
            await ref.read(recoveryServiceProvider).getRecoveryRequest(widget.recoveryRequestId);
        final vaultId = request?.vaultId;

        await ref.read(recoveryServiceProvider).cancelRecoveryRequest(widget.recoveryRequestId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recovery request cancelled')),
          );
          // Invalidate providers to refresh the UI
          ref.invalidate(recoveryRequestByIdProvider(widget.recoveryRequestId));
          if (vaultId != null) {
            ref.invalidate(vaultProvider(vaultId));
            ref.invalidate(recoveryStatusProvider(vaultId));
          }
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
