import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault.dart';
import '../providers/vault_provider.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Text(vault.name),
        centerTitle: false,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
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
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context, ref, vault);
              }
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
}
