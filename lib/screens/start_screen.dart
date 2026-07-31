import 'package:flutter/material.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import 'account_choice_screen.dart';
import 'onboarding_recovery_screen.dart';

/// Start screen shown after onboarding explainer.
///
/// Presents "Recover a Vault" and a "Something Else" button that routes to
/// AccountChoiceScreen. Additional buttons ("I have an invitation", "Create a
/// Vault") will land in subsequent PRs.
///
/// Flow: HowItWorksScreen → [Get Started] → StartScreen → [Recover a Vault] → OnboardingRecoveryScreen
///                                             → [Something Else] → AccountChoiceScreen
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  /// Builds the start screen layout with a heading and two action cards:
  /// "Recover a Vault" (navigates to [OnboardingRecoveryScreen]) and
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
