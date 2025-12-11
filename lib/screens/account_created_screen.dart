import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/row_button_stack.dart';
import '../screens/vault_explainer_screen.dart';
import '../screens/vault_list_screen.dart';
import '../services/logger.dart';

/// Screen shown after account creation, allowing user to back up their key
class AccountCreatedScreen extends ConsumerStatefulWidget {
  final String nsec;

  const AccountCreatedScreen({super.key, required this.nsec});

  @override
  ConsumerState<AccountCreatedScreen> createState() =>
      _AccountCreatedScreenState();
}

class _AccountCreatedScreenState extends ConsumerState<AccountCreatedScreen> {
  bool _isBackingUp = false;

  String _getRedactedNsec() {
    final nsec = widget.nsec;
    if (nsec.length <= 15) {
      return nsec; // Too short to redact
    }
    // Show first 9 chars and last 6 chars
    return '${nsec.substring(0, 9)}...${nsec.substring(nsec.length - 6)}';
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.nsec));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nostr key copied to clipboard')),
      );
    }
  }

  Future<void> _backupKeyInVault() async {
    if (_isBackingUp) return;

    setState(() {
      _isBackingUp = true;
    });

    try {
      // Navigate to vault explainer with nsec prefilled
      if (mounted) {
        await Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => VaultExplainerScreen(
              initialContent: widget.nsec,
              initialName: 'Nostr Key Backup',
              isOnboarding: true,
            ),
          ),
          (route) => false, // Clear all previous routes
        );
      }
    } catch (e) {
      Log.error('Error navigating to vault backup', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting vault backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _skipBackup() async {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const VaultListScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // No back button
        title: const Text('Account Created'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Title
                    Text(
                      'Account Created',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'Back up your Nostr key',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 32),
                    // Redacted nsec display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getRedactedNsec(),
                              style: textTheme.bodyLarge?.copyWith(
                                fontFamily: 'RobotoMono',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: _copyToClipboard,
                            tooltip: 'Copy full key to clipboard',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Warning text
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Make sure to back up your key. If you lose it, you will not be able to recover your account.',
                              style: textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer
                                    .withValues(alpha: 1.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Buttons at bottom
            RowButtonStack(
              buttons: [
                RowButtonConfig(
                  onPressed: _isBackingUp ? null : _backupKeyInVault,
                  icon: Icons.lock,
                  text: _isBackingUp
                      ? 'Creating Vault...'
                      : 'Back Up in Horcrux Vault',
                ),
                RowButtonConfig(
                  onPressed: _isBackingUp ? null : _skipBackup,
                  icon: Icons.skip_next,
                  text: 'Skip for Now',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
