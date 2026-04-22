import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/row_button.dart';
import '../widgets/vault_content_form.dart';
import '../widgets/vault_content_save_mixin.dart';
import '../widgets/horcrux_scaffold.dart';
import 'backup_config_screen.dart';
import 'vault_list_screen.dart';

/// Enhanced vault creation screen with integrated backup configuration
class VaultCreateScreen extends ConsumerStatefulWidget {
  final String? initialContent;
  final String? initialName;
  final bool isOnboarding;

  const VaultCreateScreen({
    super.key,
    this.initialContent,
    this.initialName,
    this.isOnboarding = false,
  });

  @override
  ConsumerState<VaultCreateScreen> createState() => _VaultCreateScreenState();
}

class _VaultCreateScreenState extends ConsumerState<VaultCreateScreen> with VaultContentSaveMixin {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// When true, new vaults use [Vault.pushEnabled]. The owner-side OS
  /// permission prompt is deferred until they navigate away from the vault
  /// or recovery plan screen, so we don't pop an OS dialog during the
  /// initial vault creation tap.
  bool _alertStewardsWithPush = true;

  @override
  void initState() {
    super.initState();
    // Prefill fields if initial values provided
    if (widget.initialName != null) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HorcruxScaffold(
      appBar: AppBar(title: const Text('New Vault'), centerTitle: false),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  VaultContentForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    contentController: _contentController,
                    ownerNameController: _ownerNameController,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _alertStewardsWithPush,
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _alertStewardsWithPush = v);
                        }
                      },
                      title: Text(
                        'Alert stewards with push notifications',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        'When you distribute keys or start recovery, stewards can be '
                        'notified on their device. Requires notification permission.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          RowButton(
            onPressed: () => _saveVault(),
            icon: Icons.arrow_forward,
            text: 'Next',
            addBottomSafeArea: true,
          ),
        ],
      ),
    );
  }

  Future<void> _saveVault() async {
    if (!_formKey.currentState!.validate()) return;

    final vaultId = await saveVault(
      formKey: _formKey,
      name: _nameController.text,
      content: _contentController.text,
      ownerName: _ownerNameController.text.trim().isEmpty ? null : _ownerNameController.text.trim(),
      pushEnabledForNewVault: _alertStewardsWithPush,
    );

    if (vaultId != null && mounted) {
      await _navigateToBackupConfig(vaultId);
    }
  }

  Future<void> _navigateToBackupConfig(String vaultId) async {
    if (!mounted) return;

    // Regular push (not modal) for BackupConfigScreen
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => BackupConfigScreen(
          vaultId: vaultId,
          isOnboarding: widget.isOnboarding,
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (widget.isOnboarding) {
      // After onboarding flow completes, take the user to the vault list
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const VaultListScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vault created and recovery plan saved!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Dismiss the modal and pass the vaultId back up the chain
      Navigator.pop(context, result);
    }
  }
}
