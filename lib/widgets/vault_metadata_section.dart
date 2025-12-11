import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/vault.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';

/// Widget for displaying vault metadata (ownership info)
class VaultMetadataSection extends ConsumerWidget {
  final String vaultId;

  const VaultMetadataSection({super.key, required this.vaultId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaultAsync = ref.watch(vaultProvider(vaultId));
    final currentPubkeyAsync = ref.watch(currentPublicKeyProvider);

    return vaultAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Vault Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading vault: $error',
                style: TextStyle(color: Colors.red[600]),
              ),
            ],
          ),
        ),
      ),
      data: (vault) {
        if (vault == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Vault not found'),
            ),
          );
        }

        return currentPubkeyAsync.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error loading user info: $error'),
            ),
          ),
          data: (currentPubkey) => _buildMetadataContent(context, vault, currentPubkey),
        );
      },
    );
  }

  Widget _buildMetadataContent(
    BuildContext context,
    Vault vault,
    String? currentPubkey,
  ) {
    final isOwner = currentPubkey == vault.ownerPubkey;
    final threshold = vault.shards.firstOrNull?.threshold;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isOwner) ...[
              // Owner state
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'You own this vault',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ] else ...[
              // Key holder state
              Row(
                children: [
                  Icon(
                    Icons.key,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have a key to this vault',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Owner: ${Helpers.encodeBech32(vault.ownerPubkey, 'npub')}',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
              if (threshold != null) ...[
                const SizedBox(height: 8),
                Text(
                  'A minimum of $threshold keys are needed to recover and unlock the vault.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
