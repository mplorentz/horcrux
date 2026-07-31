import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/key_provider.dart';
import '../services/invitation_service.dart';
import '../services/logger.dart';
import '../utils/app_initialization.dart';
import '../screens/account_created_screen.dart';
import '../screens/login_screen.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';

/// Screen allowing users to choose how to set up their account
class AccountChoiceScreen extends ConsumerStatefulWidget {
  const AccountChoiceScreen({super.key});

  @override
  ConsumerState<AccountChoiceScreen> createState() => _AccountChoiceScreenState();
}

class _AccountChoiceScreenState extends ConsumerState<AccountChoiceScreen> {
  @override
  void initState() {
    super.initState();
    final hasStaged = ref.read(invitationServiceProvider).hasStagedInvitations;
    Log.debug('[onboarding] AccountChoiceScreen: initState, hasStagedInvitations=$hasStaged');
  }

  @override
  Widget build(BuildContext context) {
    return HorcruxScaffold(
      appBar: const HorcruxAppBar(title: 'Setup'),
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

                  Log.debug('[onboarding] AccountChoiceScreen: Create Account tapped');
                  final loginService = ref.read(loginServiceProvider);
                  final keyPair = await loginService.generateAndStoreNostrKey();

                  // Initialize services and refresh key providers
                  Log.debug(
                    '[onboarding] AccountChoiceScreen: calling initializeAppAndRefreshKeys '
                    '(this reinitializes deep link handling)',
                  );
                  await initializeAppAndRefreshKeys(ref);
                  Log.debug(
                    '[onboarding] AccountChoiceScreen: initializeAppAndRefreshKeys done, '
                    'hasStagedInvitations=${ref.read(invitationServiceProvider).hasStagedInvitations}',
                  );

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
