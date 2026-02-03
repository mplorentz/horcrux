import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/invitation_link.dart';
import '../models/invitation_status.dart';
import '../models/invitation_exceptions.dart';
import '../services/invitation_service.dart';
import '../providers/invitation_provider.dart';
import '../providers/key_provider.dart';
import '../widgets/row_button_stack.dart';
import '../widgets/row_button.dart';
import '../widgets/horcrux_scaffold.dart';

/// Screen for accepting or denying an invitation link
///
/// This screen is accessed via deep link and displays invitation details
/// allowing the user to accept or deny the invitation.
class InvitationAcceptanceScreen extends ConsumerStatefulWidget {
  final String inviteCode;

  const InvitationAcceptanceScreen({super.key, required this.inviteCode});

  @override
  ConsumerState<InvitationAcceptanceScreen> createState() => _InvitationAcceptanceScreenState();
}

class _InvitationAcceptanceScreenState extends ConsumerState<InvitationAcceptanceScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final invitationAsync = ref.watch(
      invitationByCodeProvider(widget.inviteCode),
    );
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

    return HorcruxScaffold(
      appBar: AppBar(title: const Text('Invitation'), centerTitle: false),
      body: invitationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading invitation',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
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
        ),
        data: (invitation) {
          if (invitation == null) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Invitation Not Found',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This invitation link is invalid or has expired.',
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

          return _buildInvitationContent(invitation, currentPubkeyAsync);
        },
      ),
    );
  }

  Widget _buildInvitationContent(
    InvitationLink invitation,
    AsyncValue<String?> currentPubkeyAsync,
  ) {
    final canAct = invitation.status.canRedeem && !_isProcessing;
    final isTerminal = invitation.status.isTerminal;
    final ownerNpub = Helpers.encodeBech32(invitation.ownerPubkey, 'npub');

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                if (isTerminal)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        invitation.status,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: _getStatusColor(invitation.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(invitation.status),
                          color: _getStatusColor(invitation.status),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            invitation.status.description,
                            style: TextStyle(
                              color: _getStatusColor(invitation.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Title
                Text(
                  'You\'ve been invited',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),

                // Explainer text
                Text(
                  'Accepting this invitation will grant you a single key to a shared vault. You\'ll then be able to recover the vault in coordination with the other stewards.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 24),

                // Owner information
                Text(
                  'From',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 4),
                // Show owner name if available, otherwise show npub
                if (invitation.ownerName != null && invitation.ownerName!.isNotEmpty)
                  Text(
                    invitation.ownerName!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  )
                else
                  Text(
                    ownerNpub,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                const SizedBox(height: 24),

                // Invitee name (if provided)
                if (invitation.inviteeName != null) ...[
                  Text(
                    'Invited as',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invitation.inviteeName!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Vault name (if available)
                if (invitation.vaultName != defaultVaultName) ...[
                  Text(
                    'Vault',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invitation.vaultName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Action Buttons
        if (!isTerminal)
          currentPubkeyAsync.when(
            loading: () => const RowButton(
              onPressed: null,
              icon: Icons.hourglass_empty,
              text: 'Checking account...',
            ),
            error: (error, _) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error checking account. Please ensure you are logged in.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                RowButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icons.arrow_back,
                  text: 'Go Back',
                ),
              ],
            ),
            data: (pubkey) {
              if (pubkey == null) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      margin: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You need to be logged in to accept an invitation.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    RowButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icons.arrow_back,
                      text: 'Go Back',
                    ),
                  ],
                );
              }

              return RowButtonStack(
                buttons: [
                  RowButtonConfig(
                    onPressed: canAct ? _denyInvitation : null,
                    icon: Icons.close,
                    text: 'Deny',
                  ),
                  RowButtonConfig(
                    onPressed: canAct && !_isProcessing ? () => _acceptInvitation(pubkey) : null,
                    icon: _isProcessing ? Icons.hourglass_empty : Icons.check,
                    text: _isProcessing ? 'Processing...' : 'Accept',
                  ),
                ],
              );
            },
          )
        else
          RowButton(
            onPressed: () => Navigator.pop(context),
            icon: Icons.arrow_back,
            text: 'Go Back',
          ),
      ],
    );
  }

  Color _getStatusColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.redeemed:
        return Colors.green;
      case InvitationStatus.denied:
        return Colors.orange;
      case InvitationStatus.invalidated:
      case InvitationStatus.error:
        return Colors.red;
      case InvitationStatus.created:
      case InvitationStatus.pending:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.redeemed:
        return Icons.check_circle;
      case InvitationStatus.denied:
        return Icons.cancel;
      case InvitationStatus.invalidated:
      case InvitationStatus.error:
        return Icons.error;
      case InvitationStatus.created:
      case InvitationStatus.pending:
        return Icons.info;
    }
  }

  Future<void> _acceptInvitation(String inviteePubkey) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final invitationService = ref.read(invitationServiceProvider);
      await invitationService.redeemInvitation(
        inviteCode: widget.inviteCode,
        inviteePubkey: inviteePubkey,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the invitation data
        ref.invalidate(invitationByCodeProvider(widget.inviteCode));

        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } on InvitationAlreadyRedeemedException {
      setState(() {
        _errorMessage = 'This invitation has already been redeemed.';
        _isProcessing = false;
      });
      ref.invalidate(invitationByCodeProvider(widget.inviteCode));
    } on InvitationInvalidatedException catch (e) {
      setState(() {
        _errorMessage = 'This invitation has been invalidated: ${e.reason}';
        _isProcessing = false;
      });
      ref.invalidate(invitationByCodeProvider(widget.inviteCode));
    } on InvitationNotFoundException {
      setState(() {
        _errorMessage = 'Invitation not found. It may have expired or been removed.';
        _isProcessing = false;
      });
      ref.invalidate(invitationByCodeProvider(widget.inviteCode));
    } on ArgumentError catch (e) {
      // Handle various argument errors including duplicate redemption and owner redemption
      setState(() {
        _errorMessage = e.message;
        _isProcessing = false;
      });
      ref.invalidate(invitationByCodeProvider(widget.inviteCode));
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        setState(() {
          _errorMessage = errorMessage;
          _isProcessing = false;
        });

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _denyInvitation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deny Invitation?'),
        content: const Text(
          'Are you sure you want to deny this invitation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, true),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deny'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final invitationService = ref.read(invitationServiceProvider);
      await invitationService.denyInvitation(inviteCode: widget.inviteCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation denied'),
            backgroundColor: Colors.orange,
          ),
        );

        // Refresh the invitation data
        ref.invalidate(invitationByCodeProvider(widget.inviteCode));

        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } on InvitationNotFoundException {
      setState(() {
        _errorMessage = 'Invitation not found. It may have expired or been removed.';
        _isProcessing = false;
      });
      ref.invalidate(invitationByCodeProvider(widget.inviteCode));
    } on InvitationAlreadyRedeemedException {
      setState(() {
        _errorMessage = 'This invitation has already been redeemed.';
        _isProcessing = false;
      });
      ref.invalidate(invitationByCodeProvider(widget.inviteCode));
    } on InvitationInvalidatedException catch (e) {
      setState(() {
        _errorMessage = 'This invitation has been invalidated: ${e.reason}';
        _isProcessing = false;
      });
      ref.invalidate(invitationByCodeProvider(widget.inviteCode));
    } on ArgumentError catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isProcessing = false;
      });
      ref.invalidate(invitationByCodeProvider(widget.inviteCode));
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to deny invitation: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }
}
