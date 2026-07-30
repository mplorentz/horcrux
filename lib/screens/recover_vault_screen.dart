import 'package:flutter/material.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button.dart';
import 'login_screen.dart';

/// Informational screen explaining vault recovery.
///
/// Tells users that recovery requires an existing steward to recover their
/// data on another device. The Login button lets users who already have their
/// account key proceed to log in.
///
/// Flow: StartScreen → [Recover a Vault] → RecoverVaultScreen → [Login] → LoginScreen
class RecoverVaultScreen extends StatelessWidget {
  const RecoverVaultScreen({super.key});

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
                      'To recover a vault, you will need an existing steward '
                      'to recover your data on another device.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'If you already have your account key, you can log in below.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Login button at bottom
            RowButton(
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
              addBottomSafeArea: true,
            ),
          ],
        ),
      ),
    );
  }
}