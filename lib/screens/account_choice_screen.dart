import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/key_provider.dart';
import '../utils/app_initialization.dart';
import '../screens/account_created_screen.dart';
import '../screens/login_screen.dart';
import '../screens/vault_list_screen.dart';

/// Screen allowing users to choose how to set up their account
class AccountChoiceScreen extends ConsumerStatefulWidget {
  const AccountChoiceScreen({super.key});

  @override
  ConsumerState<AccountChoiceScreen> createState() => _AccountChoiceScreenState();
}

class _AccountChoiceScreenState extends ConsumerState<AccountChoiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup'), centerTitle: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Explainer text
              const Text(
                'Horcrux uses the Nostr network to store and transmit data. '
                'Nostr is a digital commons that prevents vendor lock-in. '
                'We can create a new Nostr account for you or you can log in with an existing one.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              // Create Account card
              _buildAccountCard(
                context,
                icon: Icons.add_circle_outline,
                title: 'Create Account',
                description: 'Generate a new Nostr identity',
                onTap: () async {
                  final navigator = Navigator.of(context);

                  final loginService = ref.read(loginServiceProvider);
                  final keyPair = await loginService.generateAndStoreNostrKey();

                  // Initialize services and refresh key providers
                  await initializeAppAndRefreshKeys(ref);

                  navigator.push(
                    MaterialPageRoute(
                      builder: (context) => AccountCreatedScreen(nsec: keyPair.privateKeyBech32!),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Login card
              _buildAccountCard(
                context,
                icon: Icons.login,
                title: 'Login',
                description: 'Import existing Nostr key',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // No Account card
              _buildAccountCard(
                context,
                icon: Icons.arrow_forward,
                title: 'Continue Without Account',
                description: 'Use local-only mode',
                onTap: () async {
                  final navigator = Navigator.of(context);

                  // Show warning dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Are You Sure?'),
                      content: const Text(
                        'Without an account you will only be able to use Horcrux on this device and you will need to manually migrate your vaults to new devices. If you change your mind you can always back up your account keys from the app settings.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Continue Anyway'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  // Generate key silently
                  final loginService = ref.read(loginServiceProvider);
                  await loginService.initializeKey();

                  // Initialize services
                  await initializeAppServices(ref);

                  // Navigate to main app, clear onboarding stack
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const VaultListScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary, width: 0.5),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.surface,
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
    );
  }
}
