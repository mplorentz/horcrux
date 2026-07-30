import 'package:flutter/material.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button.dart';
import 'account_choice_screen.dart';

/// Start screen shown after onboarding explainer.
///
/// Title: "How would you like to start?"
/// Initially contains only a "Something Else" button that routes to
/// AccountChoiceScreen. Three additional buttons land in subsequent PRs:
/// "I have an invitation", "Recover a Vault", "Create a Vault".
///
/// Flow: HowItWorksScreen → [Get Started] → StartScreen → [Something Else] → AccountChoiceScreen
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HorcruxScaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Spacer(),
            // Heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'How would you like to start?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            // Something Else button at bottom
            RowButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountChoiceScreen(),
                  ),
                );
              },
              icon: Icons.arrow_forward,
              text: 'Something Else',
              addBottomSafeArea: true,
            ),
          ],
        ),
      ),
    );
  }
}