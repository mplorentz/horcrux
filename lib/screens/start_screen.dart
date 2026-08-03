import 'package:flutter/material.dart';
import '../services/logger.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import 'account_choice_screen.dart';
import 'invitation_onboarding_screen.dart';
import 'onboarding_recovery_screen.dart';

/// Start screen shown after onboarding explainer.
///
/// Presents "Create a Vault", "I have an invitation", "Recover a Vault", and
/// "Something Else" buttons.
///
/// Flow: HowItWorksScreen → [Get Started] → StartScreen → [Create a Vault] → AccountChoiceScreen
///                                             → [I have an invitation] → InvitationOnboardingScreen
///                                             → [Recover a Vault] → OnboardingRecoveryScreen
///                                             → [Something Else] → AccountChoiceScreen
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
    Log.info('[onboarding] StartScreen: shown');
  }

  /// Builds the start screen layout with a heading and four action cards:
  /// "Create a Vault" (navigates to [AccountChoiceScreen]),
  /// "I have an invitation" (navigates to [InvitationOnboardingScreen]),
  /// "Recover a Vault" (navigates to [OnboardingRecoveryScreen]), and
  /// "Something Else" (navigates to [AccountChoiceScreen]).
  @override
  Widget build(BuildContext context) {
    return HorcruxScaffold(
      appBar: const HorcruxAppBar(title: 'Start'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'How would you like to start?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildAccountCard(
                context: context,
                icon: Icons.add,
                title: 'Create a Vault',
                description: 'Set up a new backup plan with your stewards',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountChoiceScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildAccountCard(
                context: context,
                icon: Icons.mail_outline,
                title: 'I have an invitation',
                description: 'Accept an invitation from a vault owner',
                onTap: () {
                  Log.debug('[onboarding] StartScreen: I have an invitation tapped');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InvitationOnboardingScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildAccountCard(
                context: context,
                icon: Icons.restore,
                title: 'Recover a Vault',
                description: 'Restore vault data from your stewards',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnboardingRecoveryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildAccountCard(
                context: context,
                icon: Icons.arrow_forward,
                title: 'Something Else',
                description: 'Create or import an account',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountChoiceScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary, width: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.onSurface),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(description, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
