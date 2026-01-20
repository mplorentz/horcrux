import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/steward.dart';

/// Mode for adding a steward
enum AddStewardMode {
  invite, // Invite by link
  manual, // Add by Nostr public key
  edit, // Edit existing steward
}

/// Result returned when the add steward screen is closed
class AddStewardResult {
  final String name;
  final String? contactInfo;
  final AddStewardMode? method;
  final String? npub; // Only set if method is AddStewardMethod.manual

  AddStewardResult({
    required this.name,
    this.contactInfo,
    this.method,
    this.npub,
  });
}

/// Modal bottom sheet for adding or editing a steward
class AddStewardScreen extends ConsumerStatefulWidget {
  final Steward? steward; // If provided, we're editing; otherwise, we're adding
  final List<String> relays; // Required for invitation method

  const AddStewardScreen({
    super.key,
    this.steward,
    required this.relays,
  });

  /// Show the add steward screen as a modal bottom sheet
  static Future<AddStewardResult?> show(
    BuildContext context, {
    Steward? steward,
    required List<String> relays,
  }) {
    return showModalBottomSheet<AddStewardResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddStewardScreen(
        steward: steward,
        relays: relays,
      ),
    );
  }

  @override
  ConsumerState<AddStewardScreen> createState() => _AddStewardScreenState();
}

class _AddStewardScreenState extends ConsumerState<AddStewardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _npubController = TextEditingController();
  bool _showAdvancedOptions = false;
  final bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if editing
    if (widget.steward != null) {
      _nameController.text = widget.steward!.name ?? '';
      _contactInfoController.text = widget.steward!.contactInfo ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactInfoController.dispose();
    _npubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.steward != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  isEditing ? 'Edit Steward' : 'Add Steward',
                  style: theme.textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          // Form content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Steward's name",
                        hintText: 'Enter name for this steward',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: !isEditing,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a steward name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Contact info field
                    TextFormField(
                      controller: _contactInfoController,
                      decoration: const InputDecoration(
                        labelText: 'Contact info (optional)',
                        hintText: 'Email, phone, Signal, etc.',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: maxContactInfoLength,
                      maxLines: 3,
                      buildCounter: (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) {
                        return Text(
                          '$currentLength/$maxLength characters',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        );
                      },
                      onChanged: (value) {
                        setState(() {}); // Update character counter
                      },
                    ),
                    const SizedBox(height: 24),
                    // Method selection (only show when adding, not editing)
                    if (!isEditing) ...[
                      // Primary: Invite by Link
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.relays.isEmpty
                              ? null
                              : () => _handleSubmit(AddStewardMode.invite),
                          icon: const Icon(Icons.link),
                          label: const Text('Invite by Link'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (widget.relays.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                          child: Text(
                            'Please add at least one relay before adding a steward',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Advanced options toggle
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showAdvancedOptions = !_showAdvancedOptions;
                          });
                        },
                        icon: Icon(
                          _showAdvancedOptions ? Icons.expand_more : Icons.chevron_right,
                        ),
                        label: Text(
                          _showAdvancedOptions ? 'Hide Advanced Options' : 'Show Advanced Options',
                        ),
                      ),
                      // Advanced: Invite by Nostr ID
                      if (_showAdvancedOptions) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showNpubInput(),
                            icon: const Icon(Icons.person),
                            label: const Text('Add via Nostr Public Key'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: Text(
                            'If they already have a Nostr account',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      // When editing, show save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _handleSaveEdit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isSubmitting ? 'Saving...' : 'Save'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit(AddStewardMode method) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final contactInfo =
        _contactInfoController.text.trim().isEmpty ? null : _contactInfoController.text.trim();

    if (method == AddStewardMode.invite) {
      Navigator.pop(
        context,
        AddStewardResult(
          name: name,
          contactInfo: contactInfo,
          method: AddStewardMode.invite,
        ),
      );
    }
  }

  void _handleSaveEdit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final contactInfo =
        _contactInfoController.text.trim().isEmpty ? null : _contactInfoController.text.trim();

    Navigator.pop(
      context,
      AddStewardResult(
        name: name,
        contactInfo: contactInfo,
        method: AddStewardMode.edit,
      ),
    );
  }

  Future<void> _showNpubInput() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Steward by Public Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adding: ${_nameController.text.trim()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _npubController,
              decoration: const InputDecoration(
                labelText: 'Nostr Public Key (npub)',
                hintText: 'npub1...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Convert bech32 npub to hex pubkey
      final npub = _npubController.text.trim();
      final decoded = Helpers.decodeBech32(npub);
      if (decoded[0].isEmpty) {
        throw Exception('Invalid npub format: $npub');
      }

      final name = _nameController.text.trim();
      final contactInfo =
          _contactInfoController.text.trim().isEmpty ? null : _contactInfoController.text.trim();

      Navigator.pop(
        context,
        AddStewardResult(
          name: name,
          contactInfo: contactInfo,
          method: AddStewardMode.manual,
          npub: decoded[0], // Hex format
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid npub: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
