import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault.dart';
import '../models/backup_config.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import '../services/backup_service.dart';
import '../utils/backup_distribution_helper.dart';
import '../utils/invite_code_utils.dart';

/// Mixin for shared vault save logic between create and edit screens
mixin VaultContentSaveMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Save a vault (create new or update existing)
  /// Returns the vault ID (newly created ID or the existing one)
  Future<String?> saveVault({
    required GlobalKey<FormState> formKey,
    required String name,
    required String content,
    String? vaultId, // null for create, value for update
    String? ownerName,
  }) async {
    if (!formKey.currentState!.validate()) return null;

    try {
      final repository = ref.read(vaultRepositoryProvider);

      if (vaultId == null) {
        // Create new vault
        final vault = await _createNewVault(name, content, ownerName);
        await repository.addVault(vault);
        return vault.id;
      } else {
        // Update existing vault - check if content, name, or ownerName changed
        final existingVault = await repository.getVault(vaultId);
        if (existingVault == null) {
          throw Exception('Vault not found: $vaultId');
        }

        final contentChanged = existingVault.content != content;
        final nameChanged = existingVault.name != name.trim();
        final newOwnerName = ownerName?.trim().isEmpty == true
            ? null
            : ownerName?.trim();
        final ownerNameChanged = existingVault.ownerName != newOwnerName;

        // Check if we need to show the regeneration alert
        // Show alert if content/name/ownerName changed AND all stewards have accepted invitations
        bool shouldAutoDistribute = false;
        final willChange = contentChanged || nameChanged || ownerNameChanged;

        if (willChange) {
          if (!mounted) return null;
          final shouldAutoDistributeResult =
              await BackupDistributionHelper.showRegenerationAlertIfNeeded(
                context: context,
                backupConfig: existingVault.backupConfig,
                willChange: true,
                mounted: mounted,
              );

          if (shouldAutoDistributeResult == false) {
            // User cancelled or widget disposed, don't save changes
            return null;
          }

          if (shouldAutoDistributeResult == true) {
            shouldAutoDistribute = true;
          }
        }

        // Update vault
        await repository.updateVault(vaultId, name, content);

        // Also update ownerName (even if null, to clear it)
        await repository.saveVault(
          existingVault.copyWith(ownerName: newOwnerName),
        );

        // If content, name, or ownerName changed, increment distributionVersion
        if (contentChanged || nameChanged || ownerNameChanged) {
          final backupService = ref.read(backupServiceProvider);
          await backupService.handleContentChange(vaultId);

          // If user confirmed, auto-distribute
          if (shouldAutoDistribute) {
            // Reload config to get updated version
            final updatedConfig = await repository.getBackupConfig(vaultId);
            if (updatedConfig != null && updatedConfig.canDistribute) {
              try {
                await backupService.createAndDistributeBackup(vaultId: vaultId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Keys regenerated and distributed successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to distribute keys: $e'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            }
          }
        }

        return vaultId;
      }
    } catch (e) {
      showError('Failed to save vault: ${e.toString()}');
      return null;
    }
  }

  /// Create a new vault with the current user's public key
  Future<Vault> _createNewVault(
    String name,
    String content,
    String? ownerName,
  ) async {
    final loginService = ref.read(loginServiceProvider);
    final currentPubkey = await loginService.getCurrentPublicKey();
    if (currentPubkey == null) {
      throw Exception('Unable to get current user public key');
    }

    // Generate cryptographically secure vault ID
    // Vault IDs are exposed in invitation URLs, so they must be unguessable
    final vaultId = generateSecureID();

    return Vault(
      id: vaultId,
      name: name.trim(),
      content: content,
      createdAt: DateTime.now(),
      ownerPubkey: currentPubkey,
      ownerName: ownerName?.trim().isEmpty == true ? null : ownerName?.trim(),
    );
  }

  /// Show an error message to the user
  void showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
