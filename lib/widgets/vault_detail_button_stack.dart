import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault.dart';
import '../models/vault_detail.dart';
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
import '../utils/snackbar_helper.dart';

/// Button stack widget for vault detail screen
class VaultDetailButtonStack extends ConsumerWidget {
  final String vaultId;

  const VaultDetailButtonStack({super.key, required this.vaultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(vaultDetailProvider(vaultId));
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
            final isVaultOwner = currentPubkey != null && vault.isVaultOwner(currentPubkey);
            final isSteward = currentPubkey != null &&
                !vault.isVaultOwner(currentPubkey) &&
                vault is StewardedVaultDetail &&
                vault.latestShare != null;

            // Watch recovery status for recovery buttons
            final recoveryStatusAsync = ref.watch(recoveryStatusProvider(vaultId));

            return recoveryStatusAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (recoveryStatus) {
                final buttons = <RowButtonConfig>[];
                // Exclusivity is per (vault, initiator): each user may have at most one
                // active recovery session per vault (practice or real), but different
                // users (other stewards, owner) may have their own concurrent sessions
                // on the same vault. `recoveryStatusProvider` only surfaces the single
                // most-recent manageable request, which can belong to another user --
                // so we resolve the current user's own sessions through
                // `VaultDetail.manageableRecoveryFor`, which keys off `initiatorPubkey`
                // and includes both in-flight statuses and `completed` (users finalize a
                // recovery from the same Manage screen once enough stewards approve).
                final myActiveRealRecovery =
                    vault.manageableRecoveryFor(currentPubkey, isPractice: false);
                final myActivePracticeRecovery =
                    vault.manageableRecoveryFor(currentPubkey, isPractice: true);
                final hasMyInFlightRecovery =
                    myActiveRealRecovery != null || myActivePracticeRecovery != null;
                final showManageRealRecovery = myActiveRealRecovery != null;
                // Initiate is hidden when this user already has any of their own session
                // (practice or real) in flight on this vault; they should manage that one
                // instead. The service would reject the call anyway.
                final showInitiateRealRecovery = !hasMyInFlightRecovery;

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
                if (isVaultOwner) {
                  // Check if vault has content
                  final hasContent = vault is OwnedVaultDetail;

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
                        } else {
                          // Create new content (with warning if owner-steward)
                          final isOwnerSteward =
                              vault is StewardedVaultDetail && vault.latestShare != null;

                          if (isOwnerSteward) {
                            _showUpdateContentWarning(context, ref, vault);
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

                  // Travel Mode Button - shown after distribution
                  // Erases the local copy of the vault contents while keeping the
                  // recovery plan intact, so the owner can restore the contents later
                  // via their stewards. Useful before crossing a border, lending the
                  // device, or any other situation where the contents shouldn't be
                  // accessible from this device.
                  if (vault is OwnedVaultDetail) {
                    final backupConfig = vault.backupConfig;
                    if (backupConfig != null &&
                        backupConfig.stewards.isNotEmpty &&
                        backupConfig.hasBeenDistributed) {
                      buttons.add(
                        RowButtonConfig(
                          onPressed: () => _showTravelModeDialog(context, ref, vault),
                          icon: Icons.luggage,
                          text: 'Travel Mode',
                        ),
                      );
                    }
                  }

                  // Practice Recovery Button (only for owners)
                  // Only show if all stewards are holding the current key
                  final backupConfig = vault.backupConfig;
                  final allStewardsHoldingCurrentKey =
                      backupConfig?.allStewardsHoldingCurrentKey ?? false;

                  if (allStewardsHoldingCurrentKey) {
                    if (myActivePracticeRecovery != null) {
                      // Show "Manage Practice Recovery" if THIS user has an active
                      // practice session of their own. Other users' practice sessions
                      // are not actionable from here.
                      final myPracticeId = myActivePracticeRecovery.id;
                      buttons.add(
                        RowButtonConfig(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RecoveryStatusScreen(recoveryRequestId: myPracticeId),
                              ),
                            );
                          },
                          icon: Icons.school,
                          text: 'Manage Practice Recovery',
                        ),
                      );
                    } else if (!hasMyInFlightRecovery) {
                      // Show "Practice Recovery" only when this user has no session of
                      // their own in flight (per-user exclusivity).
                      buttons.add(
                        RowButtonConfig(
                          onPressed: () {
                            // Use a full-screen route, not showModalBottomSheet,
                            // so the AppBar gets normal Scaffold safe-area
                            // insets on edge-to-edge Android devices.
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                fullscreenDialog: true,
                                builder: (_) => PracticeRecoveryInfoScreen(vaultId: vaultId),
                              ),
                            );
                          },
                          icon: Icons.school,
                          text: 'Practice Recovery',
                        ),
                      );
                    }
                  }

                  // Surface "Manage Recovery" for the owner whenever they have an
                  // active real recovery, regardless of content state. Owners can
                  // recreate vault content (or restore it) while a recovery is still
                  // in flight; gating on owner-steward state alone made the button
                  // vanish in that scenario (bug horcrux_app-e0h).
                  if (showManageRealRecovery) {
                    final myRecoveryId = myActiveRealRecovery.id;
                    buttons.add(
                      RowButtonConfig(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecoveryStatusScreen(recoveryRequestId: myRecoveryId),
                            ),
                          );
                        },
                        icon: Icons.visibility,
                        text: 'Manage Recovery',
                      ),
                    );
                  }
                }

                // Owner-steward state: owner has deleted content but kept shards.
                // Only "Initiate Recovery" is gated on this state -- you can only
                // start a real recovery when you have shards but no content. Managing
                // an existing recovery is handled in the owner block above so it
                // survives the owner adding content back mid-recovery.
                final isOwnerSteward =
                    isVaultOwner && vault is StewardedVaultDetail && vault.latestShare != null;

                if (isOwnerSteward && showInitiateRealRecovery) {
                  buttons.add(
                    RowButtonConfig(
                      onPressed: () => _initiateRecovery(context, ref, vaultId),
                      icon: Icons.restore,
                      text: 'Initiate Recovery',
                    ),
                  );
                }

                // Recovery buttons - only show for stewards (not owners, since owners already have contents)
                // Don't show recovery buttons when steward is waiting for their shard
                if (!isVaultOwner && !isOwnerSteward && vault.state != VaultState.awaitingShare) {
                  if (showManageRealRecovery) {
                    final myRecoveryId = myActiveRealRecovery.id;
                    buttons.add(
                      RowButtonConfig(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RecoveryStatusScreen(recoveryRequestId: myRecoveryId),
                            ),
                          );
                        },
                        icon: Icons.visibility,
                        text: 'Manage Recovery',
                      ),
                    );
                  } else if (showInitiateRealRecovery) {
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
  }

  String? _getInstructions(VaultDetail vault) {
    final share = switch (vault) {
      StewardedVaultDetail(:final latestShare) => latestShare,
      OwnedVaultDetail(:final selfHeldShare) => selfHeldShare,
    };
    return share?.instructions;
  }

  /// Show warning dialog before creating new content for owner-steward vault (T016, T020)
  Future<void> _showUpdateContentWarning(
      BuildContext context, WidgetRef ref, VaultDetail vault) async {
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

  /// Confirm enabling Travel Mode: erase the local copy of the vault contents
  /// while keeping the recovery plan intact, so the owner can restore them
  /// later via their stewards.
  Future<void> _showTravelModeDialog(BuildContext context, WidgetRef ref, VaultDetail vault) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Travel Mode?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Travel Mode wipes the vault contents from this device, so even if this device is compromised your vault will be safe.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your recovery plan stays intact, so you can restore the contents later with help from your stewards.',
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
                      "You'll need to initiate recovery and wait for stewards to approve before you can view this vault's contents again.",
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
            child: const Text('Enable Travel Mode'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(vaultRepositoryProvider);
        await repository.deleteVaultContent(vault.id);

        if (context.mounted) {
          context.showHorcruxSnackBar(
            'Travel Mode enabled.',
            kind: HorcruxSnackKind.success,
          );

          ref.invalidate(vaultProvider(vault.id));
        }
      } catch (e) {
        if (context.mounted) {
          context.showHorcruxSnackBar(
            'Failed to enable Travel Mode: $e',
            kind: HorcruxSnackKind.error,
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
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Initiate Recovery?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will begin the process of recovering the contents of this vault.'),
            SizedBox(height: 8),
            Text('• Recovery requests will be sent to all stewards.'),
            Text('• Stewards can approve or deny your request.'),
            Text(
                '• Once enough stewards approve, you can recover the vault content on the recovery screen.'),
            SizedBox(height: 12),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Initiate Recovery'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show full-screen loading dialog
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

        context.showHorcruxSnackBar(
          'Recovery request initiated and sent',
          kind: HorcruxSnackKind.success,
        );

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
        context.showHorcruxSnackBar('Error: $e', kind: HorcruxSnackKind.error);
      }
    }
  }
}
