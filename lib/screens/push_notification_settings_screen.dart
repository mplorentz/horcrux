import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vault.dart';
import '../providers/key_provider.dart';
import '../providers/vault_provider.dart';
import '../services/horcrux_notification_service.dart';
import '../services/logger.dart';
import '../services/push_notification_receiver.dart';
import '../widgets/horcrux_scaffold.dart';

/// Settings screen for managing push notification opt-in, notifier server
/// URL, and per-vault push preferences (owned vaults only).
class PushNotificationSettingsScreen extends ConsumerStatefulWidget {
  const PushNotificationSettingsScreen({super.key});

  @override
  ConsumerState<PushNotificationSettingsScreen> createState() =>
      _PushNotificationSettingsScreenState();
}

class _PushNotificationSettingsScreenState extends ConsumerState<PushNotificationSettingsScreen> {
  final TextEditingController _serverUrlController = TextEditingController();

  bool _loading = true;
  bool _optedIn = false;
  bool _mutatingOptIn = false;
  bool _savingUrl = false;
  String _resolvedServerUrl = HorcruxNotificationService.defaultBaseUrl;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final receiver = ref.read(pushNotificationReceiverProvider);
    final notifier = ref.read(horcruxNotificationServiceProvider);
    final optedIn = await receiver.isOptedIn();
    final url = await notifier.getBaseUrl();
    if (!mounted) return;
    setState(() {
      _optedIn = optedIn;
      _resolvedServerUrl = url;
      _serverUrlController.text = url;
      _loading = false;
    });
  }

  Future<void> _toggleOptIn(bool value) async {
    if (_mutatingOptIn) return;
    setState(() => _mutatingOptIn = true);
    try {
      final receiver = ref.read(pushNotificationReceiverProvider);
      if (value) {
        final granted = await receiver.optIn();
        if (!mounted) return;
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Push permission was not granted. Enable notifications in '
                'your device settings and try again.',
              ),
            ),
          );
        }
      } else {
        await receiver.optOut();
      }
      await _reload();
    } catch (e, st) {
      Log.warning('Failed to toggle push opt-in', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update push notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _mutatingOptIn = false);
    }
  }

  Future<void> _saveServerUrl() async {
    final trimmed = _serverUrlController.text.trim();
    if (trimmed.isNotEmpty) {
      final parsed = Uri.tryParse(trimmed);
      if (parsed == null ||
          !(parsed.isScheme('http') || parsed.isScheme('https')) ||
          parsed.host.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter a valid http(s) URL (e.g. https://notify.example.com).',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _savingUrl = true);
    try {
      final notifier = ref.read(horcruxNotificationServiceProvider);
      await notifier.setBaseUrl(trimmed.isEmpty ? null : trimmed);
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            trimmed.isEmpty ? 'Notifier URL reset to default' : 'Notifier URL updated',
          ),
        ),
      );
    } catch (e, st) {
      Log.warning('Failed to save notifier URL', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save notifier URL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _savingUrl = false);
    }
  }

  Future<void> _toggleVaultPushEnabled(Vault vault, bool enabled) async {
    try {
      final repository = ref.read(vaultRepositoryProvider);
      await repository.setPushEnabled(vault.id, enabled);
    } catch (e, st) {
      Log.warning('Failed to toggle per-vault push', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update vault: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HorcruxScaffold(
      appBar: AppBar(
        title: const Text('Push Notifications'),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (!PushNotificationReceiver.isSupported)
                  _buildUnsupportedBanner(theme)
                else ...[
                  _buildGlobalToggleTile(theme),
                  const Divider(height: 1),
                  _buildServerUrlSection(theme),
                  const Divider(height: 1),
                  _buildOwnedVaultsSection(theme),
                ],
              ],
            ),
    );
  }

  Widget _buildUnsupportedBanner(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Push notifications are not supported on this platform.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Recovery events still arrive as in-app notifications while the '
            'app is running.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalToggleTile(ThemeData theme) {
    final subtitle = _optedIn
        ? 'Registered for push notifications on this device.'
        : 'Receive alerts when stewards or vault owners reach out.';
    return SwitchListTile.adaptive(
      title: const Text('Enable push notifications'),
      subtitle: Text(subtitle),
      value: _optedIn,
      onChanged: _mutatingOptIn ? null : (value) => _toggleOptIn(value),
      secondary: _mutatingOptIn
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _optedIn ? Icons.notifications_active : Icons.notifications_off_outlined,
              color: theme.colorScheme.onSurface,
            ),
    );
  }

  Widget _buildServerUrlSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifier server', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Default: ${HorcruxNotificationService.defaultBaseUrl}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _serverUrlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://notify.example.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _savingUrl
                    ? null
                    : () {
                        _serverUrlController.text = HorcruxNotificationService.defaultBaseUrl;
                      },
                child: const Text('Use default'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _savingUrl || _serverUrlController.text.trim() == _resolvedServerUrl
                    ? null
                    : _saveServerUrl,
                child: _savingUrl
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnedVaultsSection(ThemeData theme) {
    final vaultsAsync = ref.watch(vaultListProvider);
    final pubkeyAsync = ref.watch(currentPublicKeyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Your vaults',
            style: theme.textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Toggle whether each vault you own triggers push notifications '
            'to stewards.',
            style: theme.textTheme.bodySmall,
          ),
        ),
        vaultsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load vaults: $error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          data: (vaults) => pubkeyAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Failed to load account: $error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            data: (currentPubkey) => _buildOwnedVaultsList(theme, vaults, currentPubkey),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnedVaultsList(
    ThemeData theme,
    List<Vault> vaults,
    String? currentPubkey,
  ) {
    if (currentPubkey == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No account loaded.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final ownedVaults = vaults.where((v) => v.isOwned(currentPubkey)).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (ownedVaults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "You don't own any vaults yet.",
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ownedVaults.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final vault = ownedVaults[index];
        return SwitchListTile.adaptive(
          title: Text(vault.name),
          subtitle: Text(
            vault.pushEnabled ? 'Push alerts enabled for stewards' : 'Push alerts disabled',
          ),
          value: vault.pushEnabled,
          onChanged: (value) => _toggleVaultPushEnabled(vault, value),
        );
      },
    );
  }
}
