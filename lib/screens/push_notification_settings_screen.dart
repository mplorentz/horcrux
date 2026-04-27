import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/logger.dart';
import '../services/push_notification_receiver.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/push_privacy_learn_more_text.dart';

/// Settings screen for global push opt-in.
class PushNotificationSettingsScreen extends ConsumerStatefulWidget {
  const PushNotificationSettingsScreen({super.key});

  @override
  ConsumerState<PushNotificationSettingsScreen> createState() =>
      _PushNotificationSettingsScreenState();
}

class _PushNotificationSettingsScreenState extends ConsumerState<PushNotificationSettingsScreen> {
  bool _loading = true;
  bool _optedIn = false;
  bool _mutatingOptIn = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload({bool showError = true}) async {
    try {
      final receiver = ref.read(pushNotificationReceiverProvider);
      final optedIn = await receiver.isOptedIn();
      if (!mounted) return;
      setState(() => _optedIn = optedIn);
    } catch (e, st) {
      Log.warning('Failed to load push notification opt-in state', e, st);
      if (!mounted) return;
      if (showError) {
        _showErrorSnackBar(
          'Unable to load push notification settings right now. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: cs.onError)),
        backgroundColor: cs.error,
      ),
    );
  }

  Future<void> _toggleOptIn(bool value) async {
    if (_mutatingOptIn) return;
    setState(() => _mutatingOptIn = true);
    try {
      final receiver = ref.read(pushNotificationReceiverProvider);
      if (value) {
        final granted = await receiver.optIn();
        if (!mounted) return;
        setState(() => _optedIn = granted);
        if (!granted) {
          _showErrorSnackBar(
            'Push permission was not granted. Enable notifications in '
            'your device settings and try again.',
          );
        }
      } else {
        await receiver.optOut();
        if (!mounted) return;
        setState(() => _optedIn = false);
      }
      await _reload(showError: false);
    } catch (e, st) {
      Log.warning('Failed to toggle push opt-in', e, st);
      if (!mounted) return;
      _showErrorSnackBar('Failed to update push notifications: $e');
    } finally {
      if (mounted) setState(() => _mutatingOptIn = false);
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
                else
                  _buildGlobalToggleTile(theme),
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
}
