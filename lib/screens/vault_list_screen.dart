import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vault_provider.dart';
import '../widgets/row_button.dart';
import '../widgets/horcrux_scaffold.dart';
import 'vault_explainer_screen.dart';
import 'vault_detail_screen.dart';
import 'settings_screen.dart';
import '../widgets/vault_card.dart';

/// Main list screen showing all vaults
class VaultListScreen extends ConsumerWidget {
  const VaultListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the vault stream provider
    final vaultsAsync = ref.watch(vaultListProvider);

    return HorcruxScaffold(
      showNotificationBanner: true,
      appBar: AppBar(
        title: const Text('Horcrux'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Use AsyncValue.when() to handle loading/error/data states
                vaultsAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  error: (error, stack) {
                    final textTheme = Theme.of(context).textTheme;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: $error',
                            style: textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.refresh(vaultListProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  },
                  data: (vaults) {
                    if (vaults.isEmpty) {
                      final theme = Theme.of(context);
                      final textTheme = theme.textTheme;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 64,
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            const SizedBox(height: 16),
                            Text('No vaults yet', style: textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                'Tap + to create a vault or if you received an invitation link open it now to join their vault.',
                                style: textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: vaults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final vault = vaults[index];
                        return VaultCard(key: ValueKey(vault.id), vault: vault);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          // Create vault button at bottom
          RowButton(
            onPressed: () async {
              // Show vault creation flow as a modal
              final vaultId = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => const VaultExplainerScreen(),
                  fullscreenDialog: true,
                ),
              );

              // If vault was created, navigate to its detail screen
              if (vaultId != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VaultDetailScreen(vaultId: vaultId),
                  ),
                );
              }
            },
            icon: Icons.add,
            text: 'Create Vault',
            addBottomSafeArea: true,
          ),
        ],
      ),
    );
  }
}
