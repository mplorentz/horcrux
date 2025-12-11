import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/row_button.dart';
import '../widgets/vault_content_form.dart';
import '../widgets/vault_content_save_mixin.dart';
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

class _VaultCreateScreenState extends ConsumerState<VaultCreateScreen>
    with VaultContentSaveMixin {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
    return Scaffold(
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
    final vaultId = await saveVault(
      formKey: _formKey,
      name: _nameController.text,
      content: _contentController.text,
      ownerName: _ownerNameController.text.trim().isEmpty
          ? null
          : _ownerNameController.text.trim(),
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
