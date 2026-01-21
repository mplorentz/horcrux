import 'package:flutter/material.dart';
import '../widgets/row_button_stack.dart';
import '../widgets/horcrux_scaffold.dart';
import '../screens/vault_explainer_screen.dart';
import '../screens/vault_list_screen.dart';

/// Screen shown after importing an existing Nostr key
class ImportSuccessScreen extends StatelessWidget {
  final String nsec;

  const ImportSuccessScreen({super.key, required this.nsec});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return HorcruxScaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back button
        title: const Text(
          'Account Imported Successfully',
          maxLines: 2,
          overflow: TextOverflow.visible,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Explanation text
                    Text(
                      'Your Nostr account has been imported. You can now back it up '
                      'in a Horcrux Vault so your friends and family can help you '
                      'recover it if needed.',
                      style: textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Backing up your key in a Horcrux Vault means you won\'t '
                              'lose access to your Nostr identity even if you lose this device.',
                              style: textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
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
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => VaultExplainerScreen(
                          initialContent: nsec,
                          initialName: 'Nostr Key Backup',
                        ),
                      ),
                      (route) => false, // Clear all previous routes
                    );
                  },
                  icon: Icons.lock,
                  text: 'Back Up in Horcrux Vault',
                ),
                RowButtonConfig(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const VaultListScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: Icons.skip_next,
                  text: 'Skip for Now',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
