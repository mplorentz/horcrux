import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault.dart';
import '../models/backup_config.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import '../providers/recovery_provider.dart';
import '../services/recovery_service.dart';
import '../services/logger.dart';
import '../screens/recovery_status_screen.dart';
import '../widgets/row_button.dart';

/// Screen to explain the processs for practicing recovery.
/// This allows vault owners to initiate a practice recovery sesssion.
class PracticeRecoveryInfoScreen extends ConsumerWidget {
  final String vaultId;

  const PracticeRecoveryInfoScreen({super.key, required this.vaultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(vaultProvider(vaultId));
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Recovery'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // How Recovery Works
                Text('How Recovery Works', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildStepCard(
                  context,
                  stepNumber: 1,
                  title: 'Initiate Recovery',
                  description: 'You (or a steward) send a recovery request to all other stewards.',
                ),
                const SizedBox(height: 8),
                _buildStepCard(
                  context,
                  stepNumber: 2,
                  title: 'Stewards Respond',
                  description:
                      'Stewards receive a notification and can approve or deny the request. Approved requests include their vault key.',
                ),
                const SizedBox(height: 8),
                _buildStepCard(
                  context,
                  stepNumber: 3,
                  title: 'Threshold Met',
                  description:
                      'Once ${backupConfig.threshold} stewards approve, you have enough keys to unlock your vault and recover the contents.',
                ),

                const SizedBox(height: 24),

                // How Practice Mode Works
                Text(
                  'How Practice Mode Works',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBulletPoint(
                        context,
                        'In practice mode no vault keys or data is actually exchanged.',
                      ),
                      _buildBulletPoint(
                        context,
                        'Only you (the vault owner) can initiate practice recovery.',
                      ),
                      _buildBulletPoint(
                        context,
                        'Your stewards will receive a recovery request from you marked "Practice" which they can respond to in their copy of Horcrux.',
                      ),
                      _buildBulletPoint(
                        context,
                        'You will be taken to the Recovery Status screen to manage the recovery just like in a real recovery scenario.',
                      ),
                      _buildBulletPoint(
                        context,
                        'You may end the practice run at any time.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Start Practice Recovery button
        RowButton(
          onPressed: () => _startPracticeRecovery(context, ref, vault),
          icon: Icons.restore,
          text: 'Start Practice Recovery',
          addBottomSafeArea: true,
        ),
      ],
    );
  }

  Widget _buildNotReadyMessage(
    BuildContext context,
    String title,
    String message,
  ) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
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
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
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

  Future<void> _startPracticeRecovery(
    BuildContext context,
    WidgetRef ref,
    Vault vault,
  ) async {
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
                      Text(
                        'Sending recovery requests...',
                        style: TextStyle(fontSize: 16),
                      ),
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
        isPractice: true,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recovery request initiated and sent')),
        );

        ref.invalidate(recoveryStatusProvider(vaultId));

        if (context.mounted) {
          // Dismiss the modal bottom sheet first
          Navigator.pop(context);

          // Then push RecoveryStatusScreen from the right
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
