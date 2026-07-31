import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/invitation_service.dart';
import '../services/logger.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button.dart';
import 'account_choice_screen.dart';

/// Informational screen shown when the user taps "I have an invitation" on
/// the Start screen. Explains that they should leave the app and tap the
/// invitation link; the app will remember it.
///
/// Flow: StartScreen → [I have an invitation] → InvitationOnboardingScreen
///       → (user leaves app, taps deep link, invitation is staged in memory)
///       → [Continue] → AccountChoiceScreen
///
/// Subscribes directly to [InvitationService.invitationsChangedStream] (same
/// pattern as [BackupConfigScreen]) so it can advance automatically the
/// moment a staged invitation shows up (cold-start scenario, or the user
/// returning to the app after tapping the link) rather than waiting for the
/// user to notice and tap the button.
class InvitationOnboardingScreen extends ConsumerStatefulWidget {
  const InvitationOnboardingScreen({super.key});

  @override
  ConsumerState<InvitationOnboardingScreen> createState() =>
      _InvitationOnboardingScreenState();
}

class _InvitationOnboardingScreenState extends ConsumerState<InvitationOnboardingScreen> {
  StreamSubscription<void>? _invitationSubscription;
  bool _hasStaged = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Log.debug('[onboarding] InvitationOnboardingScreen: initState');
    // Set up the subscription after first frame when ref is available, and
    // check right away in case an invitation was already staged before this
    // screen was built (e.g. cold-start deep link processed during launch).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final invitationService = ref.read(invitationServiceProvider);
      Log.debug(
        '[onboarding] InvitationOnboardingScreen: post-frame check using '
        'InvitationService(${invitationService.hashCode})',
      );
      _checkStagedInvitation(invitationService);
      _invitationSubscription = invitationService.invitationsChangedStream.listen((_) {
        Log.debug('[onboarding] InvitationOnboardingScreen: invitationsChangedStream fired');
        if (!mounted) return;
        _checkStagedInvitation(invitationService);
      });
      Log.debug(
        '[onboarding] InvitationOnboardingScreen: subscribed to '
        'InvitationService(${invitationService.hashCode}).invitationsChangedStream',
      );
    });
  }

  void _checkStagedInvitation(InvitationService invitationService) {
    final hasStaged = invitationService.hasStagedInvitations;
    Log.debug('[onboarding] InvitationOnboardingScreen: hasStagedInvitations=$hasStaged');
    if (hasStaged != _hasStaged) {
      setState(() => _hasStaged = hasStaged);
    }
    if (hasStaged) {
      _goToAccountChoice();
    }
  }

  void _goToAccountChoice() {
    if (_navigated) {
      Log.debug('[onboarding] InvitationOnboardingScreen: _goToAccountChoice already navigated, skipping');
      return;
    }
    _navigated = true;
    Log.debug('[onboarding] InvitationOnboardingScreen: navigating to AccountChoiceScreen');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountChoiceScreen(),
      ),
    );
  }

  @override
  void dispose() {
    Log.debug('[onboarding] InvitationOnboardingScreen: dispose');
    _invitationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final hasStaged = _hasStaged;

    return HorcruxScaffold(
      appBar: const HorcruxAppBar(title: 'Invitation'),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 32,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Check your messages',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Leave this app and open the invitation link you received. '
                      'We\'ll remember your invitation and bring you back here.',
                      style: textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'After tapping the link, create an account or log in and '
                      'you\'ll be taken directly to your invitation.',
                      style: textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                    if (!hasStaged) ...[
                      const SizedBox(height: 48),
                      Center(child: _buildWaitingWidget(context)),
                      const SizedBox(height: 48),
                    ],
                  ],
                ),
              ),
            ),
            // Continue button at bottom, disabled until a staged invitation shows up.
            RowButton(
              onPressed: hasStaged ? _goToAccountChoice : null,
              icon: Icons.check,
              text: 'Continue',
              addBottomSafeArea: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingWidget(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.primary, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              'Waiting for you to open the invitation',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
