import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault.dart';
import '../models/vault_detail.dart';
import '../models/backup_config.dart';
import '../providers/vault_provider.dart';
import '../providers/key_provider.dart';
import '../services/backup_service.dart';
import '../utils/invite_code_utils.dart';
import '../utils/snackbar_helper.dart';

/// Mixin for shared vault save logic between create and edit screens
mixin VaultContentSaveMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Save a vault (create new or update existing)
  /// Returns the vault ID (newly created ID or the existing one)
  Future<String?> saveVault({
    required GlobalKey<FormState> formKey,
    required String name,
    required String content,
    String? vaultId, // null for create, value for update
    String? ownerName,

    /// Only used when creating a new vault ([vaultId] is null).
    bool pushEnabledForNewVault = true,
  }) async {
    if (!formKey.currentState!.validate()) return null;

    try {
      final repository = ref.read(vaultRepositoryProvider);

      if (vaultId == null) {
        // Create new vault
        final vault = await _createNewVault(
          name,
          ownerName,
          pushEnabled: pushEnabledForNewVault,
        );
        await repository.addVault(vault);
        await repository.saveOwnedVaultContent(vault.id, content);
        return vault.id;
      } else {
        // Update existing vault - check if content, name, or ownerName changed
        final detailRepository = ref.read(vaultDetailRepositoryProvider);
        final existingDetail = await detailRepository.getVaultDetail(vaultId);
        if (existingDetail == null) {
          throw Exception('Vault not found: $vaultId');
        }

        final existingContent = existingDetail is OwnedVaultDetail ? existingDetail.content : null;
        final contentChanged = existingContent != content;
        final nameChanged = existingDetail.name != name.trim();
        final newOwnerName = ownerName?.trim().isEmpty == true ? null : ownerName?.trim();
        final ownerNameChanged = existingDetail.ownerName != newOwnerName;

        final existingVault = await repository.getVault(vaultId);
        if (existingVault == null) throw Exception('Vault not found: $vaultId');
        final updatedVault = existingVault.copyWith(
          name: name.trim(),
          ownerName: newOwnerName,
        );
        await repository.saveVault(updatedVault);
        await repository.saveOwnedVaultContent(vaultId, content);

        // If content, name, or ownerName changed, increment distributionVersion and auto-distribute
        if (contentChanged || nameChanged || ownerNameChanged) {
          final backupService = ref.read(backupServiceProvider);
          await backupService.handleContentChange(vaultId);

          // Automatically distribute keys if backup config exists and can distribute
          final updatedConfig = await repository.getBackupConfig(vaultId);
          if (updatedConfig != null && updatedConfig.canDistribute) {
            try {
              await backupService.createAndDistributeBackup(vaultId: vaultId);
              if (mounted) {
                context.showHorcruxSnackBar(
                  'Keys distributed successfully!',
                  kind: HorcruxSnackKind.success,
                );
              }
            } catch (e) {
              if (mounted) {
                context.showHorcruxSnackBar(
                  'Failed to distribute keys: $e',
                  kind: HorcruxSnackKind.warning,
                );
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

  /// Create a new vault with the current user's public key (no content; call
  /// [VaultRepository.saveOwnedVaultContent] separately).
  Future<Vault> _createNewVault(
    String name,
    String? ownerName, {
    required bool pushEnabled,
  }) async {
    final loginService = ref.read(loginServiceProvider);
    final currentPubkey = await loginService.getCurrentPublicKey();
    if (currentPubkey == null) {
      throw Exception('Unable to get current user public key');
    }

    final vaultId = generateSecureID();

    return Vault(
      id: vaultId,
      name: name.trim(),
      createdAt: DateTime.now(),
      ownerPubkey: currentPubkey,
      ownerName: ownerName?.trim().isEmpty == true ? null : ownerName?.trim(),
      pushEnabled: pushEnabled,
    );
  }

  /// Show an error message to the user
  void showError(String message) {
    if (!mounted) return;

    context.showHorcruxSnackBar(message, kind: HorcruxSnackKind.error);
  }
}
