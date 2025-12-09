import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault.dart';
import '../models/backup_config.dart';
import '../models/steward_status.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import '../providers/recovery_provider.dart';
import '../services/recovery_service.dart';
import '../services/relay_scan_service.dart';
import '../services/logger.dart';
import '../screens/recovery_status_screen.dart';
import '../widgets/row_button.dart';

/// Screen for practicing the recovery process
/// This allows vault owners to understand what recovery looks like without actually initiating a real recovery
class PracticeRecoveryScreen extends ConsumerWidget {
  final String vaultId;

  const PracticeRecoveryScreen({super.key, required this.vaultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(vaultProvider(vaultId));
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice Recovery')),
      body: vaultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading vault: $error')),
        data: (vault) {
          if (vault == null) {
            return const Center(child: Text('Vault not found'));
          }

          return currentPubkeyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error loading user: $error')),
            data: (currentPubkey) {
              // Verify user is owner
              if (currentPubkey == null || !vault.isOwned(currentPubkey)) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Only the vault owner can practice recovery.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return _buildContent(context, ref, vault);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Vault vault) {
    final theme = Theme.of(context);
    final backupConfig = vault.backupConfig;

    // Check if recovery plan is ready
    if (backupConfig == null) {
      return _buildNotReadyMessage(
        context,
        'No Recovery Plan',
        'You need to set up a recovery plan before you can practice recovery.\n\n'
            'Tap "Recovery Plan" on the vault detail screen to get started.',
      );
    }

    if (!backupConfig.isValid) {
      return _buildNotReadyMessage(
        context,
        'Recovery Plan Invalid',
        'Your recovery plan needs attention before you can practice recovery.\n\n'
            'Check your stewards, relays, and rules in the Recovery Plan.',
      );
    }

    if (!backupConfig.isReady) {
      return _buildNotReadyMessage(
        context,
        'Recovery Plan Not Ready',
        'Your recovery plan is not ready yet.\n\n'
            'You need to distribute keys to stewards and wait for them to confirm receipt.',
      );
    }

    // Recovery plan is ready - show practice content
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.school, size: 32, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Practice Recovery', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        'This is a practice run - no actual recovery will be initiated',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Vault Information
          Text('Vault Information', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildInfoCard(context, icon: Icons.lock, title: 'Vault Name', content: vault.name),

          const SizedBox(height: 24),

          // Recovery Plan Details
          Text('Recovery Plan', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildInfoCard(
            context,
            icon: Icons.people,
            title: 'Stewards',
            content:
                '${backupConfig.stewards.length} steward${backupConfig.stewards.length > 1 ? 's' : ''} have been assigned to help recover this vault',
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            context,
            icon: Icons.key,
            title: 'Threshold',
            content:
                'You need ${backupConfig.threshold} out of ${backupConfig.totalKeys} keys to recover',
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            context,
            icon: Icons.check_circle,
            title: 'Status',
            content:
                '${backupConfig.acknowledgedStewardsCount} steward${backupConfig.acknowledgedStewardsCount > 1 ? 's' : ''} confirmed they stored their key',
          ),

          const SizedBox(height: 24),

          // How Recovery Works
          Text('How Recovery Works', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildStepCard(
            context,
            stepNumber: 1,
            title: 'Initiate Recovery',
            description:
                'You (or a steward) would send a recovery request to all stewards via Nostr.',
          ),
          const SizedBox(height: 8),
          _buildStepCard(
            context,
            stepNumber: 2,
            title: 'Stewards Respond',
            description:
                'Stewards receive a notification and can approve or deny the request. Approved requests include their encrypted shard.',
          ),
          const SizedBox(height: 8),
          _buildStepCard(
            context,
            stepNumber: 3,
            title: 'Threshold Met',
            description:
                'Once ${backupConfig.threshold} stewards approve, you have enough shards to reconstruct your vault content.',
          ),
          const SizedBox(height: 8),
          _buildStepCard(
            context,
            stepNumber: 4,
            title: 'Content Recovered',
            description:
                'The app automatically reassembles the vault content using Shamir\'s Secret Sharing.',
          ),

          const SizedBox(height: 24),

          // What Stewards See
          Text('What Stewards Will See', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Recovery Request Notification', style: theme.textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Stewards will receive a notification with:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _buildBulletPoint(context, 'The vault name: "${vault.name}"'),
                _buildBulletPoint(context, 'Who initiated the recovery'),
                _buildBulletPoint(context, 'Option to approve or deny'),
                _buildBulletPoint(context, 'Instructions (if you provided any)'),
                const SizedBox(height: 12),
                Text(
                  'They can approve or deny the request. If they approve, their encrypted shard is automatically sent back to you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Important Notes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.tertiary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      'Important Notes',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBulletPoint(
                  context,
                  'This is practice only - no actual recovery request will be sent',
                ),
                _buildBulletPoint(context, 'Your stewards will not be notified or contacted'),
                _buildBulletPoint(
                  context,
                  'To initiate a real recovery, you (or a steward) would tap "Initiate Recovery" on the vault detail screen',
                ),
                _buildBulletPoint(context, 'Real recovery requests expire after 24 hours'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start Practice Recovery button
          RowButton(
            onPressed: () => _startPracticeRecovery(context, ref, vault),
            icon: Icons.restore,
            text: 'Start Practice Recovery',
            addBottomSafeArea: true,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNotReadyMessage(BuildContext context, String title, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(content, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '$stepNumber',
                style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: theme.textTheme.bodyMedium),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Future<void> _startPracticeRecovery(BuildContext context, WidgetRef ref, Vault vault) async {
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
      final loginService = ref.read(loginServiceProvider);
      final currentPubkey = await loginService.getCurrentPublicKey();

      if (currentPubkey == null) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Could not load current user')),
          );
        }
        return;
      }

      final backupConfig = vault.backupConfig;
      if (backupConfig == null) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No recovery plan configured for this vault')),
          );
        }
        return;
      }

      // Get steward pubkeys from backup config (owners only - stewards cannot practice recovery)
      final stewardPubkeys = backupConfig.stewards
          .where((s) => s.pubkey != null && s.status == StewardStatus.holdingKey)
          .map((s) => s.pubkey!)
          .toList();

      if (stewardPubkeys.isEmpty) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No stewards available for recovery. Make sure stewards have received and confirmed their keys.'),
            ),
          );
        }
        return;
      }

      final threshold = backupConfig.threshold;

      Log.info(
        'Initiating recovery with ${stewardPubkeys.length} stewards: ${stewardPubkeys.map((k) => k.substring(0, 8)).join(", ")}...',
      );

      final recoveryService = ref.read(recoveryServiceProvider);
      final recoveryRequest = await recoveryService.initiateRecovery(
        vaultId,
        initiatorPubkey: currentPubkey,
        stewardPubkeys: stewardPubkeys,
        threshold: threshold,
        isPractice: true,
      );

      // Get relays and send recovery request via Nostr
      try {
        final relays =
            await ref.read(relayScanServiceProvider).getRelayConfigurations(enabledOnly: true);
        final relayUrls = relays.map((r) => r.url).toList();

        if (relayUrls.isEmpty) {
          Log.warning('No relays configured, recovery request not sent via Nostr');
        } else {
          await recoveryService.sendRecoveryRequestViaNostr(recoveryRequest, relays: relayUrls);
        }
      } catch (e) {
        Log.error('Failed to send recovery request via Nostr', e);
      }

      // Auto-approve if the initiator is also a steward
      if (stewardPubkeys.contains(currentPubkey)) {
        try {
          Log.info('Initiator is a steward, auto-approving recovery request');
          await recoveryService.respondToRecoveryRequestWithShard(
            recoveryRequest.id,
            currentPubkey,
            true,
          );
          Log.info('Auto-approved recovery request');
        } catch (e) {
          Log.error('Failed to auto-approve recovery request', e);
        }
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recovery request initiated and sent')),
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
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
