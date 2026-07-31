import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/invitation_service.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button.dart';

/// Informational screen shown when the user taps "I have an invitation" on
/// the Start screen. Explains that they should leave the app and tap the
/// invitation link; the app will remember it.
///
/// Flow: StartScreen → [I have an invitation] → InvitationInstructionsScreen
///       → [Got it] → pops back (user leaves app, taps deep link)
///
/// If a staged invitation is detected (cold-start scenario), routes directly
/// to AccountChoiceScreen for account creation / login, which will pick up
/// the invitation via the onboarding pickup hook.
class InvitationInstructionsScreen extends ConsumerWidget {
  const InvitationInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
                    Icon(
                      Icons.mail_outline,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Check your messages',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                  ],
                ),
              ),
            ),
            // Got it button at bottom
            RowButton(
              onPressed: () {
                // Check if there's already a staged invitation (cold-start
                // scenario: user tapped the link before opening the app).
                final invitationService = ref.read(invitationServiceProvider);
                if (invitationService.hasStagedInvitations) {
                  // Route to account creation so the pickup hook fires.
                  Navigator.pushReplacementNamed(context, '/account-choice');
                  return;
                }
                Navigator.pop(context);
              },
              icon: Icons.check,
              text: 'Got it',
              addBottomSafeArea: true,
            ),
          ],
        ),
      ),
    );
  }
}
