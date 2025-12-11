import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/steward.dart';
import '../models/steward_status.dart';
import '../models/backup_config.dart';
import '../models/vault.dart';
import '../models/invitation_link.dart';
import '../services/backup_service.dart';
import '../services/invitation_service.dart';
import '../services/invitation_sending_service.dart';
import '../providers/vault_provider.dart';
import '../utils/backup_distribution_helper.dart';
import '../widgets/row_button_stack.dart';
import '../widgets/recovery_rules_widget.dart';
import 'vault_list_screen.dart';

/// Recovery plan screen for setting up distributed backup
///
/// This screen allows users to set up their recovery plan including:
/// - Threshold and total number of keys
/// - Key holders (trusted contacts)
/// - Nostr relay selection
///
/// Note: Requires a valid vaultId to load the vault content for backup
class BackupConfigScreen extends ConsumerStatefulWidget {
  final String vaultId;
  final bool isOnboarding;

  const BackupConfigScreen({
    super.key,
    required this.vaultId,
    this.isOnboarding = false,
  });

  @override
  ConsumerState<BackupConfigScreen> createState() => _BackupConfigScreenState();
}

class _BackupConfigScreenState extends ConsumerState<BackupConfigScreen> {
  int _threshold = VaultBackupConstraints.defaultThreshold;
  final List<Steward> _stewards = [];
  final List<String> _relays = ['wss://dev.horcruxbackup.com'];
  bool _isCreating = false;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  bool _isEditingExistingPlan = false; // Track if we're editing an existing plan
  bool _thresholdManuallyChanged = false; // Track if user manually changed threshold
  bool _showAdvancedSettings = false; // Track if advanced settings are visible

  // Instructions controller
  final TextEditingController _instructionsController = TextEditingController();
  // Map to track invitation links by invitee name
  final Map<String, InvitationLink> _invitationLinksByInviteeName = {};

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  /// Calculate default threshold based on steward count for new plans
  int _calculateDefaultThreshold(int stewardCount) {
    if (stewardCount == 0) {
      return VaultBackupConstraints.minThreshold;
    } else if (stewardCount == 1) {
      return 1;
    } else if (stewardCount == 2) {
      return 2;
    } else {
      // For 3+ stewards, default to n-1
      return stewardCount - 1;
    }
  }

  /// Load existing recovery plan if one exists
  Future<void> _loadExistingConfig() async {
    try {
      final repository = ref.read(vaultRepositoryProvider);
      final existingConfig = await repository.getBackupConfig(widget.vaultId);

      if (existingConfig != null && mounted) {
        setState(() {
          _threshold = existingConfig.threshold;
          _stewards.clear();
          _stewards.addAll(existingConfig.stewards);
          _relays.clear();
          _relays.addAll(existingConfig.relays);
          _instructionsController.text = existingConfig.instructions ?? '';
          _isLoading = false;
          _hasUnsavedChanges = false;
          _isEditingExistingPlan = true; // We're editing an existing plan
          _thresholdManuallyChanged = true; // Existing plan means threshold was already set
        });

        // Load existing invitations and match them to stewards
        await _loadExistingInvitations();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isEditingExistingPlan = false; // We're creating a new plan
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recovery Plan'), centerTitle: false),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );

        if (!context.mounted) return;
        if (shouldDiscard == true) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Recovery Plan'), centerTitle: false),
        body: Column(
          children: [
            Expanded(
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: false),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recovery Plan Overview
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            0,
                            16.0,
                            16.0,
                          ),
                          child: Text(
                            'Your recovery plan details how your vault can be opened and by whom.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),

                        // Stewards Section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stewards',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Stewards are trusted contacts who will help you recover access. Each steward receives one key to your vault.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),

                                // Stewards List
                                if (_stewards.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24.0,
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.people_outline,
                                            size: 48,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No stewards yet',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Add your first steward to get started',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: [
                                      for (int i = 0; i < _stewards.length; i++) ...[
                                        _buildStewardListItem(_stewards[i]),
                                        if (i < _stewards.length - 1) const Divider(height: 1),
                                      ],
                                    ],
                                  ),

                                // Add Steward Button
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _showAddStewardDialog,
                                    icon: const Icon(Icons.person_add),
                                    label: Text(
                                      _stewards.isEmpty ? 'Add Steward' : 'Add Another Steward',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recovery Rules Section
                        RecoveryRulesWidget(
                          threshold: _threshold,
                          stewardCount: _stewards.length,
                          onThresholdChanged: (newThreshold) {
                            setState(() {
                              _threshold = newThreshold;
                              _thresholdManuallyChanged = true; // Mark as manually changed
                              _hasUnsavedChanges = true;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Instructions Section
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recovery Instructions',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _instructionsController,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Write recovery instructions for stewards e.g. under what circumstances they should help you recover access?',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: null,
                                  minLines: 3,
                                  onChanged: (_) {
                                    setState(() {
                                      _hasUnsavedChanges = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Advanced Configuration Toggle
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAdvancedSettings = !_showAdvancedSettings;
                            });
                          },
                          icon: Icon(
                            _showAdvancedSettings ? Icons.expand_more : Icons.chevron_right,
                          ),
                          label: Text(
                            _showAdvancedSettings
                                ? 'Hide Advanced Configuration'
                                : 'Show Advanced Configuration',
                          ),
                        ),

                        // Relay Configuration (Advanced)
                        if (_showAdvancedSettings) ...[
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Relay Servers',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  ..._relays.map(
                                    (relay) => ListTile(
                                      leading: const Icon(Icons.cloud),
                                      title: Text(relay),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.remove_circle),
                                        onPressed: () {
                                          if (_relays.length > 1) {
                                            setState(() {
                                              _relays.remove(relay);
                                              _hasUnsavedChanges = true;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _addRelay,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Relay'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(
                          height: 16,
                        ), // Bottom padding inside scroll view
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Fixed action buttons at bottom
            RowButtonStack(
              buttons: [
                RowButtonConfig(
                  onPressed: _handleCancel,
                  icon: Icons.close,
                  text: 'Cancel',
                ),
                // Show Skip if no stewards, Save otherwise
                if (_stewards.isEmpty)
                  RowButtonConfig(
                    onPressed: _handleSkip,
                    icon: Icons.skip_next,
                    text: 'Skip',
                  )
                else
                  RowButtonConfig(
                    onPressed: !_isCreating ? _saveBackup : null,
                    icon: _isCreating ? Icons.hourglass_empty : Icons.save,
                    text: _isCreating ? 'Saving...' : 'Save',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canCreateBackup() {
    return _stewards.isNotEmpty && _relays.isNotEmpty;
  }

  Future<void> _addRelay() async {
    final relayController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Nostr Relay'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: relayController,
              decoration: const InputDecoration(
                labelText: 'Relay URL',
                hintText: 'wss://relay.example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Must be a valid WebSocket URL (wss:// or ws://)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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

    if (result == true) {
      try {
        final relayUrl = relayController.text.trim();

        // Validate relay URL
        if (relayUrl.isEmpty) {
          throw Exception('Relay URL cannot be empty');
        }

        final uri = Uri.parse(relayUrl);
        if (uri.scheme != 'wss' && uri.scheme != 'ws') {
          throw Exception('Relay URL must start with wss:// or ws://');
        }

        // Check if relay already exists
        if (_relays.contains(relayUrl)) {
          throw Exception('This relay is already in the list');
        }

        setState(() {
          _relays.add(relayUrl);
          _hasUnsavedChanges = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid relay URL: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Shows dialog to select method for adding a steward
  Future<void> _showAddStewardDialog() async {
    if (_relays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least one relay before adding a steward',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final method = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Steward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose how you want to add this steward:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'invite'),
              icon: const Icon(Icons.link),
              label: const Text('Invite by Link'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Text(
                'Send them a link they can use to join',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, 'manual'),
              icon: const Icon(Icons.person),
              label: const Text('Add by Public Key'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16),
              child: Text(
                'If they already have a Nostr account',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (method == null || !mounted) return;

    // Get steward name
    final nameController = TextEditingController();
    final nameResult = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(method == 'invite' ? 'Invite Steward' : 'Add Steward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Steward's name",
                hintText: 'Enter name for this steward',
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
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (nameResult != true || !mounted) return;

    final stewardName = nameController.text.trim();
    if (stewardName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a steward name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if steward with this name already exists
    if (_stewards.any((steward) => steward.name == stewardName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'A steward with the name "$stewardName" already exists',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (method == 'invite') {
      // Generate invitation link
      await _generateInvitationLinkForName(stewardName);
    } else {
      // Add by public key
      await _addKeyHolderByPublicKey(stewardName);
    }
  }

  /// Generates invitation link for a steward with the given name
  Future<void> _generateInvitationLinkForName(String inviteeName) async {
    // Limit to first 3 relays as per design
    final relayUrls = _relays.take(3).toList();

    try {
      final invitationService = ref.read(invitationServiceProvider);
      final invitation = await invitationService.generateInvitationLink(
        vaultId: widget.vaultId,
        inviteeName: inviteeName,
        relayUrls: relayUrls,
      );

      if (mounted) {
        // Create invited steward and add to list
        final invitedSteward = createInvitedSteward(
          name: inviteeName,
          inviteCode: invitation.inviteCode,
        );

        setState(() {
          _stewards.add(invitedSteward);
          _invitationLinksByInviteeName[inviteeName] = invitation;
          // Apply default threshold logic for new plans (only if not manually changed)
          if (!_isEditingExistingPlan && !_thresholdManuallyChanged) {
            _threshold = _calculateDefaultThreshold(_stewards.length);
          } else {
            // Ensure threshold doesn't exceed the number of stewards when editing
            if (_threshold > _stewards.length) {
              _threshold = _stewards.length;
            }
          }
          _hasUnsavedChanges = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation link generated and steward added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to generate invitation link';
        if (e is ArgumentError) {
          errorMessage = e.message ?? errorMessage;
        } else {
          errorMessage = '$errorMessage: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Adds a steward by their public key
  Future<void> _addKeyHolderByPublicKey(String stewardName) async {
    final npubController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Steward by Public Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adding: $stewardName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: npubController,
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

    try {
      // Convert bech32 npub to hex pubkey
      final npub = npubController.text.trim();
      final decoded = Helpers.decodeBech32(npub);
      if (decoded[0].isEmpty) {
        throw Exception('Invalid npub format: $npub');
      }

      // Check if steward with this pubkey already exists
      if (_stewards.any((steward) => steward.pubkey == decoded[0])) {
        throw Exception('A steward with this public key already exists');
      }

      final steward = createSteward(
        pubkey: decoded[0], // Hex format
        name: stewardName,
      );

      if (!mounted) return;
      setState(() {
        _stewards.add(steward);
        // Apply default threshold logic for new plans (only if not manually changed)
        if (!_isEditingExistingPlan && !_thresholdManuallyChanged) {
          _threshold = _calculateDefaultThreshold(_stewards.length);
        } else {
          // Ensure threshold doesn't exceed the number of stewards when editing
          if (_threshold > _stewards.length) {
            _threshold = _stewards.length;
          }
        }
        _hasUnsavedChanges = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Steward added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid steward: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStewardListItem(Steward steward) {
    final invitation = steward.name != null ? _invitationLinksByInviteeName[steward.name] : null;
    final isInvited = steward.status == StewardStatus.invited;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Icon(isInvited ? Icons.mail_outline : Icons.person),
            title: Text(steward.displayName),
            subtitle: Text(steward.displaySubtitle),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isInvited && invitation != null) ...[
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'copy') {
                        _copyInvitationLinkForSteward(invitation);
                      } else if (value == 'regenerate') {
                        _regenerateInvitationLink(steward, invitation);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 20),
                            SizedBox(width: 8),
                            Text('Copy Link'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'regenerate',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, size: 20),
                            SizedBox(width: 8),
                            Text('Regenerate Link'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () => _showRemoveStewardConfirmation(steward),
                  tooltip: 'Remove steward',
                ),
              ],
            ),
          ),
          // Show invitation link preview for invited stewards
          if (isInvited && invitation != null) ...[
            InkWell(
              onTap: () => _copyInvitationLinkForSteward(invitation),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share this invitation with ${steward.name ?? steward.displayName}:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _truncateUrl(invitation.toUrl()),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () => _copyInvitationLinkForSteward(invitation),
                          tooltip: 'Copy invitation link',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _truncateUrl(String url) {
    if (url.length <= 60) return url;
    return '${url.substring(0, 30)}...${url.substring(url.length - 27)}';
  }

  void _copyInvitationLinkForSteward(InvitationLink invitation) {
    final url = invitation.toUrl();
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invitation link copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadExistingInvitations() async {
    try {
      final invitationService = ref.read(invitationServiceProvider);
      final pendingInvitations = await invitationService.getPendingInvitations(
        widget.vaultId,
      );

      // Match invitations to stewards by inviteeName
      final updatedInvitations = <String, InvitationLink>{};
      for (final invitation in pendingInvitations) {
        if (invitation.inviteeName != null &&
            _stewards.any((kh) => kh.name == invitation.inviteeName)) {
          updatedInvitations[invitation.inviteeName!] = invitation;
        }
      }

      if (mounted) {
        setState(() {
          _invitationLinksByInviteeName.clear();
          _invitationLinksByInviteeName.addAll(updatedInvitations);
        });
      }
    } catch (e) {
      // Log error but don't fail loading
      debugPrint('Error loading existing invitations: $e');
    }
  }

  Future<void> _showRemoveStewardConfirmation(Steward steward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Steward'),
        content: Text(
          'Are you sure you want to remove "${steward.name ?? 'this steward'}" from the recovery plan? ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeSteward(steward);
    }
  }

  Future<void> _removeSteward(Steward steward) async {
    // If this is an invited steward, invalidate their invitation
    if (steward.status == StewardStatus.invited && steward.name != null) {
      final invitation = _invitationLinksByInviteeName[steward.name];
      if (invitation != null) {
        try {
          final invitationService = ref.read(invitationServiceProvider);
          await invitationService.invalidateInvitation(
            inviteCode: invitation.inviteCode,
            reason: 'Steward removed from recovery plan',
          );
        } catch (e) {
          debugPrint('Error invalidating invitation: $e');
          // Continue with removal even if invalidation fails
        }
      }
    }

    // If steward has accepted (has pubkey), send removal event
    if (steward.pubkey != null) {
      try {
        final repository = ref.read(vaultRepositoryProvider);
        final config = await repository.getBackupConfig(widget.vaultId);
        if (config != null && config.relays.isNotEmpty) {
          final invitationSendingService = ref.read(
            invitationSendingServiceProvider,
          );
          await invitationSendingService.sendKeyHolderRemovalEvent(
            vaultId: widget.vaultId,
            removedStewardPubkey: steward.pubkey!,
            relayUrls: config.relays,
          );
          debugPrint('Sent removal event for steward ${steward.pubkey}');
        }
      } catch (e) {
        debugPrint('Error sending removal event: $e');
        // Continue with removal even if event sending fails
      }
    }

    setState(() {
      _stewards.remove(steward);
      if (steward.name != null) {
        _invitationLinksByInviteeName.remove(steward.name);
      }

      // Apply default threshold logic for new plans when removing stewards (only if not manually changed)
      if (!_isEditingExistingPlan && !_thresholdManuallyChanged) {
        _threshold = _calculateDefaultThreshold(_stewards.length);
      } else {
        // Ensure threshold doesn't exceed the number of stewards when editing
        if (_stewards.isEmpty) {
          _threshold = VaultBackupConstraints.minThreshold;
        } else if (_threshold > _stewards.length) {
          _threshold = _stewards.length;
        }
      }

      _hasUnsavedChanges = true;
    });
  }

  Future<void> _regenerateInvitationLink(
    Steward steward,
    InvitationLink oldInvitation,
  ) async {
    if (steward.name == null) return;

    try {
      final invitationService = ref.read(invitationServiceProvider);

      // Invalidate old invitation
      await invitationService.invalidateInvitation(
        inviteCode: oldInvitation.inviteCode,
        reason: 'Invitation link regenerated',
      );

      // Generate new invitation link
      final relayUrls = oldInvitation.relayUrls;
      final newInvitation = await invitationService.generateInvitationLink(
        vaultId: widget.vaultId,
        inviteeName: steward.name!,
        relayUrls: relayUrls,
      );

      if (mounted) {
        setState(() {
          _invitationLinksByInviteeName[steward.name!] = newInvitation;
          _hasUnsavedChanges = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation link regenerated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate invitation link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCancel() async {
    // In onboarding mode, show different dialog
    if (widget.isOnboarding) {
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Vault Creation?'),
          content: const Text(
            'This will delete the vault you just created. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Go Back'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete Vault'),
            ),
          ],
        ),
      );

      if (shouldCancel == true && mounted) {
        // Delete the vault
        try {
          final repository = ref.read(vaultRepositoryProvider);
          await repository.deleteVault(widget.vaultId);
        } catch (e) {
          debugPrint('Error deleting vault during onboarding cancel: $e');
        }

        // Navigate to vault list screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const VaultListScreen(),
            ),
            (route) => false,
          );
        }
      }
    } else {
      // Normal mode: handle unsaved changes
      if (_hasUnsavedChanges) {
        final shouldDiscard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );

        if (shouldDiscard == true && mounted) {
          // Pop with vaultId so the vault detail screen is shown
          Navigator.of(context).pop(widget.vaultId);
        }
      } else {
        // Pop with vaultId so the vault detail screen is shown
        Navigator.of(context).pop(widget.vaultId);
      }
    }
  }

  /// Skip saving backup config (when no stewards are configured)
  /// Just navigates without saving any backup configuration
  void _handleSkip() {
    if (!mounted) return;
    Navigator.pop(context, widget.vaultId);
  }

  Future<void> _saveBackup() async {
    if (!_canCreateBackup()) return;

    try {
      final backupService = ref.read(backupServiceProvider);
      final repository = ref.read(vaultRepositoryProvider);

      // Check if this is the first save or an update
      final existingConfig = await repository.getBackupConfig(widget.vaultId);
      final isNewConfig = existingConfig == null;

      // Check if we need to show the regeneration alert
      // Show alert if config will change AND we've already distributed keys to at least one steward
      // (i.e., at least one steward has a pubkey, meaning they've received keys)
      bool shouldAutoDistribute = false;
      if (!isNewConfig) {
        // Create temporary config from UI state to compare with existing config
        final uiConfig = copyBackupConfig(
          existingConfig,
          threshold: _threshold,
          stewards: _stewards,
          relays: _relays,
          instructions: _instructionsController.text.trim().isEmpty
              ? null
              : _instructionsController.text.trim(),
        );

        // Check if config parameters will change (will increment version)
        final configWillChange = existingConfig.configParamsDifferFrom(
          uiConfig,
        );

        // Show alert if needed and get user confirmation
        if (!mounted) return;
        final shouldAutoDistributeResult =
            await BackupDistributionHelper.showRegenerationAlertIfNeeded(
          context: context,
          backupConfig: existingConfig,
          willChange: configWillChange,
          mounted: mounted,
        );

        if (shouldAutoDistributeResult == false) {
          // User cancelled or widget disposed, don't save changes
          return;
        }

        if (shouldAutoDistributeResult == true) {
          shouldAutoDistribute = true;
        }
      }

      setState(() {
        _isCreating = true;
      });

      if (isNewConfig) {
        // First time: use saveBackupConfig to create the config
        await backupService.saveBackupConfig(
          vaultId: widget.vaultId,
          threshold: _threshold,
          totalKeys: _stewards.length,
          stewards: _stewards,
          relays: _relays,
          instructions: _instructionsController.text.trim().isEmpty
              ? null
              : _instructionsController.text.trim(),
        );
      } else {
        // Update: use mergeBackupConfig to preserve RSVP updates
        await backupService.mergeBackupConfig(
          vaultId: widget.vaultId,
          threshold: _threshold,
          stewards: _stewards,
          relays: _relays,
          instructions: _instructionsController.text.trim().isEmpty
              ? null
              : _instructionsController.text.trim(),
        );
      }

      // If user confirmed, auto-distribute
      if (shouldAutoDistribute) {
        // Reload config to get updated version
        final updatedConfig = await repository.getBackupConfig(
          widget.vaultId,
        );
        if (updatedConfig != null && updatedConfig.canDistribute) {
          try {
            await backupService.createAndDistributeBackup(
              vaultId: widget.vaultId,
            );
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

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });

        bool shouldShowSuccessSnack = true;

        if (!shouldAutoDistribute) {
          // Check if we added new invited stewards to an existing plan with distributed keys
          if (!isNewConfig && existingConfig.lastRedistribution != null) {
            final existingInvitedNames = existingConfig.stewards
                .where(
                  (h) => h.status == StewardStatus.invited && h.pubkey == null,
                )
                .map((h) => h.name)
                .whereType<String>()
                .toSet();

            final newInvitedNames = _stewards
                .where(
                  (h) => h.status == StewardStatus.invited && h.pubkey == null,
                )
                .map((h) => h.name)
                .whereType<String>()
                .toSet();

            final addedInvitedCount = newInvitedNames.difference(existingInvitedNames).length;

            if (addedInvitedCount > 0) {
              shouldShowSuccessSnack = false;
              // Show alert explaining that keys need to be redistributed
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('New Stewards Added'),
                  content: Text(
                    'You\'ve added $addedInvitedCount new steward${addedInvitedCount > 1 ? 's' : ''} to your recovery plan. '
                    'Keys have already been distributed to your existing stewards.\n\n'
                    'To include the new steward${addedInvitedCount > 1 ? 's' : ''}, you\'ll need to redistribute keys from the vault detail screen once ${addedInvitedCount > 1 ? 'they' : 'the steward'} accept${addedInvitedCount > 1 ? '' : 's'} ${addedInvitedCount > 1 ? 'their invitations' : 'the invitation'}.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          }
        }

        if (shouldShowSuccessSnack && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Backup configuration saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(context, widget.vaultId);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recovery plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
