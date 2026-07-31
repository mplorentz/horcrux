import 'package:flutter/material.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button_stack.dart';
import 'feedback_screen.dart';
import 'login_screen.dart';

/// Informational screen explaining vault recovery.
///
/// Tells users that recovery requires an existing steward to recover their
/// data on another device. The Login button lets users who already have their
/// account key proceed to log in.
///
/// Flow: StartScreen → [Recover a Vault] → OnboardingRecoveryScreen → [Login] → LoginScreen
class OnboardingRecoveryScreen extends StatelessWidget {
  const OnboardingRecoveryScreen({super.key});

  /// Builds the recovery info screen showing recovery instructions and a
  /// "Login" button for users who already have their account key.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HorcruxScaffold(
      appBar: const HorcruxAppBar(title: 'Recover a Vault'),
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
                    Text(
                      'Horcrux needs your account key to communicate securely with '
                      'your stewards. Login with your key below and initiate recovery '
                      'on the appropriate vault.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'If you don\'t have your account key then you\'ll need to '
                      'contact one of your stewards and have them recover '
                      'the vault on your behalf.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Buttons at bottom
            RowButtonStack(
              buttons: [
                RowButtonConfig(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FeedbackScreen(
                          title: 'Contact Support',
                        ),
                      ),
                    );
                  },
                  icon: Icons.help_outline,
                  text: 'Contact Support',
                ),
                RowButtonConfig(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  icon: Icons.login,
                  text: 'Login',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
