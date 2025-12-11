import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault.dart';
import '../models/backup_config.dart';
import '../models/backup_status.dart';
import '../models/recovery_request.dart';
import '../providers/key_provider.dart';

/// Status variant enum for internal use
enum _StatusVariant {
  ready,
  almostReady,
  waitingOnStewards,
  noPlan,
  keysNotDistributed,
  planNeedsAttention,
  stewardWaitingKey,
  stewardReady,
  stewardBlocked,
  recoveryInProgress,
  unknown,
}

/// Status banner data class
class _StatusData {
  final String headline;
  final String subtext;
  final IconData icon;
  final Color accentColor;
  final _StatusVariant variant;

  const _StatusData({
    required this.headline,
    required this.subtext,
    required this.icon,
    required this.accentColor,
    required this.variant,
  });
}

/// Banner widget that displays vault recovery readiness status
/// Shows different messages for owners vs stewards
class VaultStatusBanner extends ConsumerWidget {
  final Vault vault;

  const VaultStatusBanner({super.key, required this.vault});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

    return currentPubkeyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (currentPubkey) {
        final isOwner = currentPubkey != null && vault.isOwned(currentPubkey);
        final isSteward =
            currentPubkey != null && !vault.isOwned(currentPubkey) && vault.shards.isNotEmpty;

        // Handle recovery status - for owners: only when active, for stewards: only if they initiated it
        final hasNonArchivedRecovery = vault.recoveryRequests.any(
          (request) => request.status != RecoveryRequestStatus.archived,
        );
        final stewardInitiatedRecovery = isSteward &&
            hasNonArchivedRecovery &&
            vault.recoveryRequests.any(
              (request) =>
                  request.status != RecoveryRequestStatus.archived &&
                  request.initiatorPubkey == currentPubkey,
            );

        if (isOwner && vault.state == VaultState.recovery) {
          const statusData = _StatusData(
            headline: 'Recovery in progress',
            subtext: 'View status and responses on the recovery screen.',
            icon: Icons.refresh,
            accentColor: Color(0xFF7A4A2F), // Umber
            variant: _StatusVariant.recoveryInProgress,
          );
          return _buildBanner(context, statusData, isOwner, isSteward);
        } else if (stewardInitiatedRecovery) {
          const statusData = _StatusData(
            headline: 'Recovery in progress',
            subtext: 'View status and responses on the recovery screen.',
            icon: Icons.refresh,
            accentColor: Color(0xFF7A4A2F), // Umber
            variant: _StatusVariant.recoveryInProgress,
          );
          return _buildBanner(context, statusData, isOwner, isSteward);
        }

        if (isOwner) {
          return _buildOwnerStatus(context, vault);
        } else if (isSteward) {
          return _buildStewardStatus(context, vault);
        } else {
          // Unknown/generic view
          return _buildBanner(
            context,
            const _StatusData(
              headline: 'Recovery status unavailable',
              subtext: 'Unable to determine vault recovery status.',
              icon: Icons.info_outline,
              accentColor: Color(0xFF676F62), // Secondary text color
              variant: _StatusVariant.unknown,
            ),
            false,
            false,
          );
        }
      },
    );
  }

  Widget _buildOwnerStatus(BuildContext context, Vault vault) {
    final backupConfig = vault.backupConfig;

    // No recovery plan
    if (backupConfig == null) {
      return _buildBanner(
        context,
        const _StatusData(
          headline: 'Recovery not set up',
          subtext: 'Step 1 of 3: Choose stewards and rules in your Recovery Plan.',
          icon: Icons.info_outline,
          accentColor: Color(0xFF676F62), // Secondary text color
          variant: _StatusVariant.noPlan,
        ),
        true,
        false,
      );
    }

    // Plan exists but not ready
    if (!backupConfig.isReady) {
      // Plan is invalid or inactive
      if (!backupConfig.isValid || backupConfig.status == BackupStatus.inactive) {
        return _buildBanner(
          context,
          const _StatusData(
            headline: 'Recovery plan needs attention',
            subtext: 'Fix your stewards, relays, or rules in the Recovery Plan.',
            icon: Icons.warning_amber,
            accentColor: Color(0xFFBA1A1A), // Error color
            variant: _StatusVariant.planNeedsAttention,
          ),
          true,
          false,
        );
      }

      // Waiting for stewards to join
      if ((backupConfig.pendingInvitationsCount > 0 || !backupConfig.canDistribute) &&
          backupConfig.lastRedistribution == null) {
        final pendingCount = backupConfig.pendingInvitationsCount;
        return _buildBanner(
          context,
          _StatusData(
            headline: 'Waiting for stewards to join',
            subtext:
                'Step 2 of 3: Invites sent. ${pendingCount > 0 ? "$pendingCount steward${pendingCount > 1 ? 's' : ''} need" : "Stewards need"} to accept before keys can be distributed.',
            icon: Icons.hourglass_empty,
            accentColor: const Color(0xFF7A4A2F), // Umber
            variant: _StatusVariant.waitingOnStewards,
          ),
          true,
          false,
        );
      }

      // Keys not distributed
      if (backupConfig.canDistribute &&
          (backupConfig.needsRedistribution ||
              backupConfig.hasVersionMismatch ||
              backupConfig.status == BackupStatus.pending)) {
        return _buildBanner(
          context,
          const _StatusData(
            headline: 'Keys not distributed',
            subtext: 'Step 2 of 3: Generate and distribute keys to stewards from this screen.',
            icon: Icons.send,
            accentColor: Color(0xFF7A4A2F), // Umber
            variant: _StatusVariant.keysNotDistributed,
          ),
          true,
          false,
        );
      }

      // Almost ready - waiting for confirmations
      if (backupConfig.status == BackupStatus.active &&
          backupConfig.acknowledgedStewardsCount < backupConfig.threshold) {
        final needed = backupConfig.threshold - backupConfig.acknowledgedStewardsCount;
        return _buildBanner(
          context,
          _StatusData(
            headline: 'Almost ready for recovery',
            subtext:
                'Step 3 of 3: Waiting for $needed more steward${needed > 1 ? 's' : ''} to confirm they stored their key.',
            icon: Icons.check_circle_outline,
            accentColor: const Color(0xFF7A4A2F), // Umber
            variant: _StatusVariant.almostReady,
          ),
          true,
          false,
        );
      }

      // Fallback for other not-ready states
      return _buildBanner(
        context,
        const _StatusData(
          headline: 'Recovery plan not ready',
          subtext: 'Complete your recovery plan setup to enable recovery.',
          icon: Icons.info_outline,
          accentColor: Color(0xFF676F62), // Secondary text color
          variant: _StatusVariant.planNeedsAttention,
        ),
        true,
        false,
      );
    }

    // Check for pending stewards before showing "Ready for recovery"
    final pendingCount = backupConfig.pendingInvitationsCount;
    if (pendingCount > 0) {
      return _buildBanner(
        context,
        _StatusData(
          headline: 'Waiting for stewards to accept',
          subtext:
              'Step 2 of 3: Waiting for $pendingCount pending steward${pendingCount > 1 ? 's' : ''} to accept their invitation${pendingCount > 1 ? 's' : ''} before keys can be distributed.',
          icon: Icons.hourglass_empty,
          accentColor: const Color(0xFF7A4A2F), // Umber
          variant: _StatusVariant.waitingOnStewards,
        ),
        true,
        false,
      );
    }

    // Fully ready
    return _buildBanner(
      context,
      const _StatusData(
        headline: 'Ready for recovery',
        subtext:
            'Step 3 of 3: Your stewards have confirmed keys are stored. You can practice recovery anytime.',
        icon: Icons.check_circle,
        accentColor: Color(0xFF2E7D32), // Deep green for success
        variant: _StatusVariant.ready,
      ),
      true,
      false,
    );
  }

  Widget _buildStewardStatus(BuildContext context, Vault vault) {
    final backupConfig = vault.backupConfig;

    // Awaiting key
    if (vault.state == VaultState.awaitingKey) {
      return _buildBanner(
        context,
        const _StatusData(
          headline: 'Waiting for your key',
          subtext:
              'You\'ve accepted the invite. The owner still needs to distribute keys—there\'s nothing you need to do yet.',
          icon: Icons.hourglass_empty,
          accentColor: Color(0xFF7A4A2F), // Umber
          variant: _StatusVariant.stewardWaitingKey,
        ),
        false,
        true,
      );
    }

    // Key holder with active backup
    if (vault.state == VaultState.steward && backupConfig?.status == BackupStatus.active) {
      return _buildBanner(
        context,
        const _StatusData(
          headline: 'You\'re ready to help',
          subtext:
              'You hold a recovery key for this vault. If recovery is requested, you\'ll be asked to approve.',
          icon: Icons.check_circle,
          accentColor: Color(0xFF2E7D32), // Deep green for success
          variant: _StatusVariant.stewardReady,
        ),
        false,
        true,
      );
    }

    // Key holder but plan not fully healthy
    if (vault.state == VaultState.steward &&
        backupConfig != null &&
        (backupConfig.status == BackupStatus.pending ||
            backupConfig.status == BackupStatus.inactive ||
            backupConfig.status == BackupStatus.failed)) {
      return _buildBanner(
        context,
        const _StatusData(
          headline: 'Your key may not be usable yet',
          subtext: 'The owner must finish or fix their recovery plan before recovery can proceed.',
          icon: Icons.warning_amber,
          accentColor: Color(0xFFBA1A1A), // Error color
          variant: _StatusVariant.stewardBlocked,
        ),
        false,
        true,
      );
    }

    // Fallback for steward
    return _buildBanner(
      context,
      const _StatusData(
        headline: 'Vault status',
        subtext: 'You have the latest key for this vault.',
        icon: Icons.key,
        accentColor: Color(0xFF676F62), // Secondary text color
        variant: _StatusVariant.stewardReady,
      ),
      false,
      true,
    );
  }

  Widget _buildBanner(
    BuildContext context,
    _StatusData statusData,
    bool isOwner,
    bool isSteward,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon in square background with rounded corners
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusData.icon,
              size: 20,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Headline
                Text(statusData.headline, style: theme.textTheme.headlineSmall),
                // Optional role context (only show if not obvious from context)
                if (isOwner || isSteward) ...[
                  const SizedBox(height: 4),
                  Text(
                    isOwner ? 'You are the owner' : 'You are a steward',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
                // Subtext
                const SizedBox(height: 4),
                Text(statusData.subtext, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
