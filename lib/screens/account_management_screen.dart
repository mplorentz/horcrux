import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/key_provider.dart';
import '../providers/vault_provider.dart';
import '../services/logout_service.dart';
import '../services/logger.dart';
import '../widgets/row_button.dart';

/// Account management screen for viewing Nostr ID and managing account
class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState
    extends ConsumerState<AccountManagementScreen> {
  bool _obscureNsec = true;
  String? _nsec;

  @override
  void initState() {
    super.initState();
    _loadNsec();
  }

  Future<void> _loadNsec() async {
    final loginService = ref.read(loginServiceProvider);
    final keyPair = await loginService.getStoredNostrKey();
    if (mounted) {
      setState(() {
        _nsec = keyPair?.privateKeyBech32;
      });
    }
  }

  Future<void> _copyNsecWithWarning() async {
    if (_nsec == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copy Private Key?'),
        content: const Text(
          'Your private key gives full access to your account and cannot be reset. Never share your private key with anyone or any app you don\'t fully trust.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Copy Anyway'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    Clipboard.setData(ClipboardData(text: _nsec!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Private key copied to clipboard'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'Logging out will delete your private key from the app as well as all vault contents. Make sure you have your private key backed up or you will lose access to this account. Your stewards will still be able to recover your vaults unless you delete them individually.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('My key is backed up'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final logoutService = ref.read(logoutServiceProvider);
      await logoutService.logout();

      // Invalidate providers so the app rebuilds in onboarding mode
      ref.invalidate(currentPublicKeyProvider);
      ref.invalidate(currentPublicKeyBech32Provider);
      ref.invalidate(isLoggedInProvider);
      ref.invalidate(vaultListProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out! Returning to onboarding...'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Log.error('Error logging out', e);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final publicKeyBech32Async = ref.watch(currentPublicKeyBech32Provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Management'),
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
                    const SizedBox(height: 8),
                    // Nostr ID section
                    Text(
                      'Nostr ID',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    publicKeyBech32Async.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (err, _) =>
                          Text('Error: $err', style: textTheme.bodySmall),
                      data: (npub) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    npub ?? 'Not available',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                size: 20,
                                color: theme.colorScheme.onSurface,
                              ),
                              onPressed: npub != null
                                  ? () => _copyToClipboard(
                                      context,
                                      npub,
                                      'Nostr ID',
                                    )
                                  : null,
                              tooltip: 'Copy Nostr ID',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Private Key section
                    Text(
                      'Private Key',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: TextEditingController(
                                    text: _nsec,
                                  ),
                                  readOnly: true,
                                  obscureText: _obscureNsec,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  _obscureNsec
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  size: 20,
                                  color: theme.colorScheme.onSurface,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNsec = !_obscureNsec;
                                  });
                                },
                                tooltip: _obscureNsec
                                    ? 'Show private key'
                                    : 'Hide private key',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.copy,
                                  size: 20,
                                  color: theme.colorScheme.onSurface,
                                ),
                                onPressed: _nsec != null
                                    ? _copyNsecWithWarning
                                    : null,
                                tooltip: 'Copy private key',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Logout button
            RowButton(
              onPressed: _handleLogout,
              icon: Icons.logout,
              text: 'Logout',
              addBottomSafeArea: true,
            ),
          ],
        ),
      ),
    );
  }
}
