import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/vault.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import '../services/backup_service.dart';
import '../widgets/steward_list.dart';
import '../widgets/vault_detail_button_stack.dart';
import '../widgets/vault_status_banner.dart';
import '../widgets/vault_owner_display.dart';

/// Detail/view screen for displaying a vault
class VaultDetailScreen extends ConsumerWidget {
  final String vaultId;

  const VaultDetailScreen({super.key, required this.vaultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(vaultProvider(vaultId));

    return vaultAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...'), centerTitle: false),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error'), centerTitle: false),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(vaultProvider(vaultId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (vault) {
        if (vault == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Vault Not Found'),
              centerTitle: false,
            ),
            body: const Center(child: Text('This vault no longer exists.')),
          );
        }

        return _buildVaultDetail(context, ref, vault);
      },
    );
  }

  Widget _buildVaultDetail(BuildContext context, WidgetRef ref, Vault vault) {
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(vault.name),
        centerTitle: false,
        actions: [
          currentPubkeyAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (currentPubkey) {
              final isOwned = currentPubkey != null && vault.isOwned(currentPubkey);
              final canRedistribute =
                  isOwned && vault.backupConfig != null && vault.backupConfig!.stewards.isNotEmpty;

              return PopupMenuButton(
                itemBuilder: (context) {
                  final items = <PopupMenuItem>[];

                  if (canRedistribute) {
                    items.add(
                      const PopupMenuItem(
                        value: 'redistribute',
                        child: Row(
                          children: [
                            Icon(Icons.refresh),
                            SizedBox(width: 8),
                            Text('Redistribute Keys'),
                          ],
                        ),
                      ),
                    );
                  }

                  items.add(
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  );

                  return items;
                },
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(context, ref, vault);
                  } else if (value == 'redistribute') {
                    _showRedistributeDialog(context, ref, vault);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owner display above status banner
          VaultOwnerDisplay(vault: vault),
          // Status banner showing recovery readiness
          VaultStatusBanner(vault: vault),
          // Scrollable content
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Steward List (extends to edges)
                    StewardList(vaultId: vault.id),
                  ],
                ),
              ),
            ),
          ),
          // Fixed buttons at bottom
          VaultDetailButtonStack(vaultId: vault.id),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Vault vault) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vault'),
        content: Text(
          'Are you sure you want to delete "${vault.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Use Riverpod to get the repository - much better for testing!
              final repository = ref.read(vaultRepositoryProvider);
              await repository.deleteVault(vault.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRedistributeDialog(BuildContext context, WidgetRef ref, Vault vault) {
    if (vault.backupConfig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recovery plan not found'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final config = vault.backupConfig!;
    if (config.stewards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No stewards in recovery plan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (vault.content == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot redistribute: vault content is not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isRedistribution = config.lastRedistribution != null;
    final title = isRedistribution ? 'Redistribute Keys?' : 'Distribute Keys?';
    final action = isRedistribution ? 'Redistribute' : 'Distribute';

    // Build explanation message
    String contentMessage = 'This will generate ${config.totalKeys} key shares '
        'and distribute them to ${config.stewards.length} steward${config.stewards.length > 1 ? 's' : ''}.\n\n'
        'Threshold: ${config.threshold} (minimum keys needed for recovery)';

    if (isRedistribution) {
      contentMessage += '\n\n⚠️ This will invalidate previously distributed keys. '
          'All stewards will receive new keys.';
    }

    contentMessage += '\n\nUse this option if:';
    contentMessage += '\n• A relay deleted your data';
    contentMessage += '\n• The app crashed during distribution';
    contentMessage += '\n• You suspect an inconsistent state';

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(contentMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _redistributeKeys(context, ref, vault);
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> _redistributeKeys(BuildContext context, WidgetRef ref, Vault vault) async {
    if (!context.mounted) return;

    // Show loading indicator on root navigator (so it persists even if context becomes unmounted)
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Distributing keys...')),
          ],
        ),
      ),
    );

    try {
      final backupService = ref.read(backupServiceProvider);
      await backupService.createAndDistributeBackup(vaultId: vault.id);

      // Close dialog using root navigator key (works even if context is unmounted)
      navigatorKey.currentState?.pop();

      // Show success message if context is still mounted
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keys distributed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh vault data
        ref.invalidate(vaultProvider(vault.id));
      }
    } catch (e) {
      // Close dialog using root navigator key (works even if context is unmounted)
      navigatorKey.currentState?.pop();

      // Show error message if context is still mounted
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to distribute keys: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
