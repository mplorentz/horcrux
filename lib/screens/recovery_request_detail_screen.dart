import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recovery_request.dart';
import '../models/vault_detail.dart';
import '../services/recovery_service.dart';
import '../providers/key_provider.dart';
import '../services/logger.dart';
import '../providers/recovery_provider.dart';
import '../providers/vault_provider.dart';
import '../utils/nostr_display.dart' show displayNameFromDetailOrNull;
import '../widgets/row_button_stack.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../utils/snackbar_helper.dart';

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

  /// Only explicit steward decisions should block re-entry/duplicate actions.
  bool _isFinalStewardDecision(RecoveryResponseStatus status) {
    return status == RecoveryResponseStatus.approved || status == RecoveryResponseStatus.denied;
  }

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
        final existingResponse = widget.recoveryRequest.responseForPubkey(pubkey);
        if (existingResponse != null && _isFinalStewardDecision(existingResponse.status)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showAlreadyRespondedDialog(existingResponse.status);
          });
        }
      }
    } catch (e) {
      Log.error('Error loading current pubkey', e);
    }
  }

  Future<void> _showAlreadyRespondedDialog(RecoveryResponseStatus responseStatus) async {
    final action = switch (responseStatus) {
      RecoveryResponseStatus.approved => 'approved',
      RecoveryResponseStatus.denied => 'denied',
      _ => 'responded to',
    };
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Already Responded'),
        content: Text('You already $action this recovery request.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _respondToRequest(RecoveryResponseStatus status) async {
    if (_currentPubkey == null) {
      context.showHorcruxSnackBar(
        'Error: Could not load current user',
        kind: HorcruxSnackKind.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final approved = status == RecoveryResponseStatus.approved;

      // Use the convenience method that handles shard retrieval and Nostr sending
      await ref.read(recoveryServiceProvider).respondToRecoveryRequestWithShare(
            widget.recoveryRequest.id,
            _currentPubkey!,
            approved,
          );

      if (mounted) {
        // Invalidate the recovery status provider to force a refresh when navigating back
        ref.invalidate(recoveryStatusProvider(widget.recoveryRequest.vaultId));

        context.showHorcruxSnackBar(
          status == RecoveryResponseStatus.approved
              ? 'Recovery request approved and key sent'
              : 'Recovery request denied',
          kind: status == RecoveryResponseStatus.approved
              ? HorcruxSnackKind.success
              : HorcruxSnackKind.info,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Log.error('Error responding to recovery request', e);
      if (mounted) {
        context.showHorcruxSnackBar('Error: $e', kind: HorcruxSnackKind.error);
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
    final vaultAsync = ref.watch(vaultDetailProvider(request.vaultId));

    return HorcruxScaffold(
      appBar: const HorcruxAppBar(title: 'Recovery Request'),
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
    VaultDetail? vault,
  ) {
    final currentResponseStatus = request.responseForPubkey(_currentPubkey)?.status;
    final hasFinalResponse =
        currentResponseStatus != null && _isFinalStewardDecision(currentResponseStatus);

    final initiatorName = displayNameFromDetailOrNull(vault, request.initiatorPubkey);

    // Get instructions from vault
    String? instructions;
    if (vault != null) {
      if (vault.backupConfig?.instructions != null &&
          vault.backupConfig!.instructions!.isNotEmpty) {
        instructions = vault.backupConfig!.instructions;
      } else {
        final share = switch (vault) {
          StewardedVaultDetail(:final latestShare) => latestShare,
          OwnedVaultDetail(:final selfHeldShare) => selfHeldShare,
        };
        instructions = share?.instructions;
      }
    }

    // Get vault name and owner name
    final vaultName = vault?.name ?? 'Unknown Vault';
    final ownerName = vault?.ownerName ?? 'Unknown Owner';

    // Get initiator contact info from vault data.
    // Contact info is shown unconditionally here because the user is already
    // viewing a recovery request — the screen context implies an active
    // recovery. The vault-level hasActiveRecovery gate cannot fire until Phase 3
    // populates VaultDetail.recoveryRequests from the recovery_requests table.
    // TODO(Phase 3): remove this comment once hasActiveRecovery is reliable.
    String? initiatorContactInfo;
    if (vault != null && vault.backupConfig != null) {
      try {
        final steward = vault.backupConfig!.stewards.firstWhere(
          (s) => s.pubkey == request.initiatorPubkey,
        );
        initiatorContactInfo = steward.contactInfo;
      } catch (e) {
        // Steward not found in backupConfig
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

                // Contact info section (if available and we know who to name)
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
                            child: SelectableText(
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
        if (request.status.isActive && !hasFinalResponse)
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
