import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/horcrux_notification_service.dart';
import '../services/logger.dart';
import '../services/push_notification_receiver.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/push_privacy_learn_more_text.dart';

/// Settings screen for global push opt-in and notifier server URL.
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
              backgroundColor: Colors.red,
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
                  if (kDebugMode) ...[
                    const Divider(height: 1),
                    _buildServerUrlSection(theme),
                  ],
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
    return SwitchListTile.adaptive(
      title: const Text('Enable push notifications'),
      subtitle: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: PushPrivacyLearnMoreText(
          prefixText:
              'Push notifications notify you immediately when important events like recovery requests need your attention. For maximum security you may want to disable push notifications. ',
        ),
      ),
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
          Text('Push Notification Server', style: theme.textTheme.titleMedium),
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
}
