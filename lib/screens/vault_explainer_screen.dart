import 'package:flutter/material.dart';
import '../widgets/row_button.dart';
import '../widgets/horcrux_scaffold.dart';
import 'vault_create_screen.dart';

/// Screen explaining vault terminology and setup process
class VaultExplainerScreen extends StatelessWidget {
  final String? initialContent;
  final String? initialName;
  final bool isOnboarding;

  const VaultExplainerScreen({
    super.key,
    this.initialContent,
    this.initialName,
    this.isOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return HorcruxScaffold(
      appBar: AppBar(title: const Text('Create Vault'), centerTitle: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main explanation paragraph
                  Text(
                    'A Vault is an encrypted bundle of your sensitive data that Horcrux can back up to your friends and family. Each vault requires multiple keys to open. Horcrux helps you create these keys and distribute them to other people.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  // Setup steps section
                  Text('Setting one up involves:', style: textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  // Step 1
                  _buildStep(
                    context,
                    number: '1',
                    title: 'Adding contents',
                    description: 'Attach files that you want to back up.',
                  ),
                  const SizedBox(height: 16),
                  // Step 2
                  _buildStep(
                    context,
                    number: '2',
                    title: 'Invite stewards',
                    description:
                        'Stewards are the other people who will hold keys to your vault. They\'ll need to download Horcrux as well to hold the keys. We\'ll give you a link that makes this easy for them.',
                  ),
                  const SizedBox(height: 16),
                  // Step 3
                  _buildStep(
                    context,
                    number: '3',
                    title: 'Distribute keys',
                    description:
                        'Once you have configured everything we\'ll securely create and distribute the keys to your vault.',
                  ),
                  const SizedBox(height: 16),
                  // Step 4
                  _buildStep(
                    context,
                    number: '4',
                    title: 'Recover',
                    description:
                        'If you lose access to your data or your stewards lose access to you (🪦) any steward can initiate a recovery process. All stewards will receive a notification requesting them to share their key. Assemble enough keys and the steward can unlock the vault.',
                  ),
                  const SizedBox(height: 24),
                  // Learn more button (placeholder)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Placeholder for now
                      },
                      child: const Text('Learn more'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          RowButton(
            onPressed: () async {
              // Navigate to vault creation (regular push, not modal)
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => VaultCreateScreen(
                    initialContent: initialContent,
                    initialName: initialName,
                    isOnboarding: isOnboarding,
                  ),
                ),
              );

              // If vault was created, pop with the vaultId
              // so VaultListScreen can navigate to VaultDetailScreen
              if (result != null && context.mounted) {
                Navigator.pop(context, result);
              }
            },
            icon: Icons.arrow_forward,
            text: 'Get Started',
            addBottomSafeArea: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required String number,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              number,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Step content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(description, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
