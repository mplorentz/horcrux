import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vault_detail.dart';
import '../providers/vault_provider.dart';
import '../widgets/vault_content_form.dart';
import '../widgets/vault_content_save_mixin.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';

/// Edit existing vault screen
class EditVaultScreen extends ConsumerStatefulWidget {
  final String vaultId;

  const EditVaultScreen({super.key, required this.vaultId});

  @override
  ConsumerState<EditVaultScreen> createState() => _EditVaultScreenState();
}

class _EditVaultScreenState extends ConsumerState<EditVaultScreen> with VaultContentSaveMixin {
  final _nameController = TextEditingController();
  final _contentController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  VaultDetail? _vault;

  @override
  void initState() {
    super.initState();
    _loadVault();
  }

  Future<void> _loadVault() async {
    final detailRepository = ref.read(vaultDetailRepositoryProvider);
    final vault = await detailRepository.getVaultDetail(widget.vaultId);
    if (mounted && vault != null) {
      setState(() {
        _vault = vault;
        _nameController.text = vault.name;
        _contentController.text = vault is OwnedVaultDetail ? vault.content : '';
        _ownerNameController.text = vault.ownerName ?? '';
      });
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
    if (_vault == null) {
      return const HorcruxScaffold(
        appBar: HorcruxAppBar(title: 'Vault Not Found'),
        body: Center(child: Text('This vault no longer exists.')),
      );
    }

    return HorcruxScaffold(
      appBar: HorcruxAppBar(
        title: 'Edit Vault',
        actions: [
          TextButton(
            onPressed: () => _saveVault(),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: VaultContentForm(
        formKey: _formKey,
        nameController: _nameController,
        contentController: _contentController,
        ownerNameController: _ownerNameController,
        contentHintText: 'Enter your sensitive text here...',
      ),
    );
  }

  Future<void> _saveVault() async {
    final savedId = await saveVault(
      formKey: _formKey,
      name: _nameController.text,
      content: _contentController.text,
      vaultId: widget.vaultId,
      ownerName: _ownerNameController.text.trim().isEmpty ? null : _ownerNameController.text.trim(),
    );

    if (savedId != null && mounted) {
      Navigator.pop(context);
    }
  }
}
