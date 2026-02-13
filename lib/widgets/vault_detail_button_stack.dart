import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault.dart';
import '../models/backup_config.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import '../providers/recovery_provider.dart';
import '../widgets/row_button_stack.dart';
import '../widgets/instructions_dialog.dart';
import '../services/recovery_service.dart';
import '../services/logger.dart';
import '../screens/backup_config_screen.dart';
import '../screens/edit_vault_screen.dart';
import '../screens/recovery_status_screen.dart';
import '../screens/practice_recovery_info_screen.dart';

/// Button stack widget for vault detail screen
class VaultDetailButtonStack extends ConsumerWidget {
  final String vaultId;

  const VaultDetailButtonStack({super.key, required this.vaultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user is steward or owner
    final vaultAsync = ref.watch(vaultProvider(vaultId));
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

    return vaultAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (vault) {
        if (vault == null) return const SizedBox.shrink();

        return currentPubkeyAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (currentPubkey) {
            final isOwned = currentPubkey != null && vault.isOwned(currentPubkey);
            final isSteward =
                currentPubkey != null && !vault.isOwned(currentPubkey) && vault.shards.isNotEmpty;

            // Watch vault for Generate and Distribute Keys button
            final vaultAsync = ref.watch(vaultProvider(vaultId));
            // Watch recovery status for recovery buttons
            final recoveryStatusAsync = ref.watch(recoveryStatusProvider(vaultId));

            return vaultAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (currentVault) {
                return recoveryStatusAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (recoveryStatus) {
                    final buttons = <RowButtonConfig>[];

                    // View Instructions Button (only show for stewards)
                    if (isSteward) {
                      final instructions = _getInstructions(vault);
                      if (instructions != null && instructions.isNotEmpty) {
                        buttons.add(
                          RowButtonConfig(
                            onPressed: () {
                              InstructionsDialog.show(context, instructions);
                            },
                            icon: Icons.info_outline,
                            text: 'View Instructions',
                          ),
                        );
                      }
                    }

                    // Edit Vault Button (only show if user owns the vault)
                    if (isOwned) {
                      // Check if vault has content
                      final hasContent = currentVault?.content != null;

                      buttons.add(
                        RowButtonConfig(
                          onPressed: () {
                            if (hasContent) {
                              // Edit existing content
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditVaultScreen(vaultId: vaultId),
                                ),
                              );
                            } else if (currentVault != null) {
                              // Create new content (with warning if owner-steward)
                              final isOwnerSteward =
                                  currentVault.content == null && currentVault.shards.isNotEmpty;

                              if (isOwnerSteward) {
                                _showUpdateContentWarning(context, ref, currentVault);
                              } else {
                                // No content and no shards - just go to edit screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditVaultScreen(vaultId: vaultId),
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icons.edit,
                          text: 'Change Vault Contents',
                        ),
                      );

                      // Recovery Plan Section - only allow if vault has content
                      buttons.add(
                        RowButtonConfig(
                          onPressed: hasContent
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BackupConfigScreen(vaultId: vaultId),
                                    ),
                                  );
                                }
                              : () {
                                  // Show dialog offering to create content first
                                  _showNoContentDialog(context, ref, vaultId);
                                },
                          icon: Icons.settings,
                          text: 'Change Recovery Plan',
                        ),
                      );

                      // Delete Local Copy Button - shown after distribution
                      // Owner can delete vault content while keeping recovery capability
                      if (currentVault != null) {
                        final backupConfig = currentVault.backupConfig;
                        if (backupConfig != null &&
                            backupConfig.stewards.isNotEmpty &&
                            backupConfig.lastRedistribution != null &&
                            currentVault.content != null) {
                          buttons.add(
                            RowButtonConfig(
                              onPressed: () => _showDeleteContentDialog(context, ref, currentVault),
                              icon: Icons.delete_sweep,
                              text: 'Delete Local Copy',
                            ),
                          );
                        }
                      }

                      // Practice Recovery Button (only for owners)
                      // Only show if all stewards are holding the current key
                      final backupConfig = currentVault?.backupConfig;
                      final allStewardsHoldingCurrentKey =
                          backupConfig?.allStewardsHoldingCurrentKey ?? false;

                      if (allStewardsHoldingCurrentKey) {
                        // Check if there's an active practice recovery (not canceled/archived)
                        // Canceled recoveries are filtered out by recoveryStatusProvider (only isActive or completed are included)
                        final activeRequest = recoveryStatus.activeRecoveryRequest;
                        final hasActivePracticeRecovery = recoveryStatus.hasActiveRecovery &&
                            activeRequest?.isPractice == true &&
                            recoveryStatus.isInitiator;

                        if (hasActivePracticeRecovery) {
                          // Show "Manage Practice Recovery" if there's an active practice recovery
                          buttons.add(
                            RowButtonConfig(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RecoveryStatusScreen(recoveryRequestId: activeRequest!.id),
                                  ),
                                );
                              },
                              icon: Icons.school,
                              text: 'Manage Practice Recovery',
                            ),
                          );
                        } else {
                          // Show "Practice Recovery" button when there's no active practice recovery
                          // This includes when practice recovery was canceled, since canceled recoveries
                          // are not considered "active" by the recoveryStatusProvider
                          buttons.add(
                            RowButtonConfig(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      PracticeRecoveryInfoScreen(vaultId: vaultId),
                                );
                              },
                              icon: Icons.school,
                              text: 'Practice Recovery',
                            ),
                          );
                        }
                      }
                    }

                    // Owner-steward state: owner has deleted content but kept shards
                    // Show special buttons for recovery
                    final isOwnerSteward = isOwned &&
                        currentVault != null &&
                        currentVault.content == null &&
                        currentVault.shards.isNotEmpty;

                    if (isOwnerSteward) {
                      // Show "You are the owner" indicator and recovery options
                      // Show "Manage Recovery" if user initiated active recovery
                      if (recoveryStatus.hasActiveRecovery && recoveryStatus.isInitiator) {
                        buttons.add(
                          RowButtonConfig(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecoveryStatusScreen(
                                    recoveryRequestId: recoveryStatus.activeRecoveryRequest!.id,
                                  ),
                                ),
                              );
                            },
                            icon: Icons.visibility,
                            text: 'Manage Recovery',
                          ),
                        );
                      } else {
                        // Show "Initiate Recovery" for owner-steward
                        buttons.add(
                          RowButtonConfig(
                            onPressed: () => _initiateRecovery(context, ref, vaultId),
                            icon: Icons.restore,
                            text: 'Initiate Recovery',
                          ),
                        );
                      }
                    }

                    // Recovery buttons - only show for stewards (not owners, since owners already have contents)
                    // Don't show recovery buttons when steward is waiting for their key (awaitingKey state)
                    if (!isOwned &&
                        !isOwnerSteward &&
                        currentVault != null &&
                        currentVault.state != VaultState.awaitingKey) {
                      // Show "Manage Recovery" if user initiated active recovery
                      if (recoveryStatus.hasActiveRecovery && recoveryStatus.isInitiator) {
                        buttons.add(
                          RowButtonConfig(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RecoveryStatusScreen(
                                    recoveryRequestId: recoveryStatus.activeRecoveryRequest!.id,
                                  ),
                                ),
                              );
                            },
                            icon: Icons.visibility,
                            text: 'Manage Recovery',
                          ),
                        );
                      } else {
                        // Show "Initiate Recovery" if no active recovery or user didn't initiate it
                        buttons.add(
                          RowButtonConfig(
                            onPressed: () => _initiateRecovery(context, ref, vaultId),
                            icon: Icons.restore,
                            text: 'Initiate Recovery',
                          ),
                        );
                      }
                    }

                    if (buttons.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return RowButtonStack(buttons: buttons);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String? _getInstructions(Vault vault) {
    final shard = vault.mostRecentShard;
    if (shard != null) {
      return shard.instructions;
    }
    return null;
  }

  /// Show warning dialog before creating new content for owner-steward vault (T016, T020)
  Future<void> _showUpdateContentWarning(BuildContext context, WidgetRef ref, Vault vault) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Content?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You currently have a key for this vault but no local content.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Creating new content will:'),
            const SizedBox(height: 8),
            const Text('• Replace any existing backup'),
            const Text('• Redistribute keys to stewards'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If you want to recover the original content, use "Initiate Recovery" instead.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create New Content'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditVaultScreen(vaultId: vault.id)),
      );
    }
  }

  /// Show confirmation dialog for deleting vault content (T011 stub, T013 implements)
  Future<void> _showDeleteContentDialog(BuildContext context, WidgetRef ref, Vault vault) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Local Copy?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will delete the vault content "${vault.name}" from this device.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your backup configuration will be preserved, allowing you to initiate recovery later to restore the content.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will need to initiate recovery to view this vault content again.',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Local Copy'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(vaultRepositoryProvider);
        await repository.deleteVaultContent(vault.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Local copy deleted. You can recover it later using your stewards.'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh vault data to show new state
          ref.invalidate(vaultProvider(vault.id));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete local copy: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Show dialog when trying to change recovery plan without content
  Future<void> _showNoContentDialog(BuildContext context, WidgetRef ref, String vaultId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No Vault Content'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You cannot change the recovery plan without having the vault contents locally.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'You chose to delete the contents from this device. You can initiate recovery to get it back or recreate it from scratch. Would you like to recreate it now?',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create Content'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      // Navigate to edit vault screen to create content
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditVaultScreen(vaultId: vaultId),
        ),
      );
    }
  }

  Future<void> _initiateRecovery(BuildContext context, WidgetRef ref, String vaultId) async {
    // Show full-screen loading dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.8),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 24),
                      Text('Sending recovery requests...', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final recoveryService = ref.read(recoveryServiceProvider);
      final recoveryRequest = await recoveryService.initiateAndSendRecovery(
        vaultId,
        isPractice: false,
      );

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recovery request initiated and sent')));

        ref.invalidate(recoveryStatusProvider(vaultId));

        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecoveryStatusScreen(recoveryRequestId: recoveryRequest.id),
            ),
          );
        }
      }
    } catch (e) {
      Log.error('Error initiating recovery', e);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
