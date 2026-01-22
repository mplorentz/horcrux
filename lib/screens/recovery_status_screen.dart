import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../providers/recovery_provider.dart';
import '../providers/vault_provider.dart';
import '../services/recovery_service.dart';
import '../widgets/recovery_stewards_widget.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button.dart';
import '../widgets/vault_owner_display.dart';

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

    return HorcruxScaffold(
      appBar: AppBar(
        title: const Text(
          'Recovering Vault',
          maxLines: 2,
          overflow: TextOverflow.visible,
        ),
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
                  instructions = vault.mostRecentShard?.instructions;
                }
              }

              // Calculate keys needed
              final approvedCount = request.approvedCount;
              final threshold = request.threshold;
              final keysNeeded = (threshold - approvedCount).clamp(0, threshold);

              return Column(
                children: [
                  // Practice mode banner - always show below app bar
                  if (request.isPractice)
                    Card(
                      margin: EdgeInsets.zero,
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
                                    'Practice Recovery',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onTertiary,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'This is a practice recovery session. No vault data will be shared.',
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vault name and owner
                          if (vault != null) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vault name:',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vault.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 16),
                                VaultOwnerDisplay(vault: vault, includePadding: false),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Keys needed text or success message
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: approvedCount >= threshold
                                ? Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.green),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Success! You have assembled enough keys to open the vault.',
                                            style: TextStyle(
                                              color: Colors.green[900],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    'You need $keysNeeded more key${keysNeeded == 1 ? '' : 's'} from vault stewards to open this vault.',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                          ),
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
                                          'Instructions from Owner',
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
                          // Summary text for practice recovery
                          if (request.isPractice) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${request.respondedCount} of ${request.totalStewards} stewards responded',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          RecoveryStewardsWidget(
                            recoveryRequestId: widget.recoveryRequestId,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  // Buttons at bottom
                  if (approvedCount >= threshold) ...[
                    // Open Vault button (top button when keys are sufficient)
                    _buildOpenVaultButton(
                      request.isPractice,
                      addBottomSafeArea: request.status != RecoveryRequestStatus.completed,
                    ),
                    if (request.status == RecoveryRequestStatus.completed)
                      _buildExitRecoveryButton(request.isPractice),
                  ] else if (request.status.isActive)
                    _buildCancelButton()
                  else if (request.status == RecoveryRequestStatus.completed)
                    _buildExitRecoveryButton(request.isPractice),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildExitRecoveryButton([bool isPractice = false]) {
    return RowButton(
      onPressed: _exitRecoveryMode,
      icon: Icons.exit_to_app,
      text: isPractice ? 'End Practice' : 'End Recovery',
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 20,
        left: 20,
        right: 0,
      ),
      addBottomSafeArea: true,
    );
  }

  Widget _buildOpenVaultButton(bool isPractice, {bool addBottomSafeArea = false}) {
    return RowButton(
      onPressed: () => _performRecovery(isPractice),
      icon: Icons.lock_open,
      text: 'Open Vault',
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 20,
        left: 20,
        right: 0,
      ),
      addBottomSafeArea: addBottomSafeArea,
    );
  }

  Future<void> _performRecovery(bool isPractice) async {
    if (isPractice) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success!'),
          content: const Text(
            "Because this is only practice mode we can't show the real vault contents.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Get the vault to access owner name
    final requestAsync = ref.read(
      recoveryRequestByIdProvider(widget.recoveryRequestId),
    );
    final request = requestAsync.value;
    if (request == null) return;

    final vaultAsync = ref.read(vaultProvider(request.vaultId));
    final vault = vaultAsync.valueOrNull;
    final ownerName = vault?.ownerName ?? 'the owner';

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recover Vault'),
        content: Text(
          'This will recover and unlock $ownerName\'s vault using the collected keys. '
          'The vault contents will now be displayed. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recover'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Perform the recovery
      final service = ref.read(recoveryServiceProvider);
      final content = await service.performRecovery(widget.recoveryRequestId);

      if (mounted) {
        // Show the recovered content in a dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Vault Recovered!'),
            content: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vault successfully recovered!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _exitRecoveryMode() async {
    // Get request to check if it's practice
    final requestAsync = ref.read(
      recoveryRequestByIdProvider(widget.recoveryRequestId),
    );
    final request = requestAsync.value;
    final isPractice = request?.isPractice ?? false;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPractice ? 'End Practice' : 'End Recovery'),
        content: Text(
          isPractice
              ? 'This will archive the practice recovery request.\n\n'
                  'Are you sure you want to end practice recovery?'
              : 'This will archive the recovery request and delete the recovered content and steward keys. '
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
            child: Text(isPractice ? 'End Practice' : 'End Recovery'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Get vaultId before exiting recovery mode
        final requestForVaultId =
            await ref.read(recoveryServiceProvider).getRecoveryRequest(widget.recoveryRequestId);
        final vaultId = requestForVaultId?.vaultId;

        await ref.read(recoveryServiceProvider).exitRecoveryMode(widget.recoveryRequestId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPractice ? 'Ended practice recovery' : 'Ended recovery',
              ),
            ),
          );
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
    return RowButton(
      onPressed: _cancelRecovery,
      icon: Icons.cancel,
      text: 'Cancel Recovery Request',
      padding: const EdgeInsets.only(
        top: 20,
        bottom: 20,
        left: 20,
        right: 0,
      ),
      addBottomSafeArea: true,
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
