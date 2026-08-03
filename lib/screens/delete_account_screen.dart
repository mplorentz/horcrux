import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database_provider.dart';
import '../models/relay_configuration.dart';
import '../providers/key_provider.dart';
import '../providers/vault_provider.dart';
import '../services/account_deletion_service.dart';
import '../services/deep_link_service.dart';
import '../services/logger.dart';
import '../services/ndk_service.dart';
import '../services/publish_service.dart';
import '../services/relay_scan_service.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/keyboard_dismiss_wrapper.dart';
import '../widgets/row_button_stack.dart';

enum _DeleteState { confirming, broadcasting, success, failure }

/// Phrase the user must type in the confirming state before "Delete Account"
/// is enabled, to guard against an accidental tap on this irreversible action.
const _confirmPhrase = 'DELETE ALL MY NOSTR DATA';

/// Full-screen flow for irrevocably deleting the user's account: signs and
/// broadcasts a NIP-62 "Request to Vanish" to every configured relay, then
/// (only if at least one relay acknowledges) wipes all local app data.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  _DeleteState _state = _DeleteState.confirming;
  List<RelayPublishStatus> _relayStatuses = [];
  final TextEditingController _confirmController = TextEditingController();
  bool _deletionInFlight = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _startDeletion() async {
    if (_deletionInFlight) return;
    _deletionInFlight = true;
    try {
      List<RelayConfiguration> relays = [];
      try {
        relays = await ref.read(relayScanServiceProvider).getRelayConfigurations(enabledOnly: true);
      } catch (e) {
        Log.error('Error loading relay configurations for account deletion', e);
      }
      if (!mounted) return;

      setState(() {
        _state = _DeleteState.broadcasting;
        _relayStatuses = [
          for (final relay in relays)
            RelayPublishStatus(relayUrl: relay.url, state: RelayPublishAckState.pending),
        ];
      });

      try {
        final result = await ref.read(accountDeletionServiceProvider).deleteAccount(
          onRelayStatusUpdate: (statuses) {
            if (!mounted) return;
            setState(() => _relayStatuses = statuses);
          },
        );
        if (!mounted) return;
        if (result.relayRequestAcknowledged) {
          ref.invalidate(currentPublicKeyProvider);
          ref.invalidate(currentPublicKeyBech32Provider);
          ref.invalidate(isLoggedInProvider);
          ref.invalidate(vaultListProvider);
          ref.invalidate(appDatabaseProvider);
          ref.invalidate(ndkServiceProvider);
          ref.invalidate(relayScanServiceProvider);
          ref.invalidate(deepLinkServiceProvider);
          setState(() => _state = _DeleteState.success);
          // main.dart's login-state listener will pushAndRemoveUntil(OnboardingScreen)
          // once isLoggedInProvider flips false; no manual navigation needed here.
        } else {
          setState(() {
            _relayStatuses = _finalizePendingAsFailed(_relayStatuses);
            _state = _DeleteState.failure;
          });
        }
      } catch (e) {
        Log.error('Error deleting account', e);
        if (!mounted) return;
        setState(() {
          _relayStatuses = _finalizePendingAsFailed(_relayStatuses);
          _state = _DeleteState.failure;
        });
      }
    } finally {
      _deletionInFlight = false;
    }
  }

  /// Once the broadcast has settled, any relay still in
  /// [RelayPublishAckState.pending] never responded in time -- render those
  /// as failed rather than leaving a spinner for an operation that's
  /// actually over.
  List<RelayPublishStatus> _finalizePendingAsFailed(List<RelayPublishStatus> statuses) {
    return [
      for (final status in statuses)
        if (status.state == RelayPublishAckState.pending)
          RelayPublishStatus(relayUrl: status.relayUrl, state: RelayPublishAckState.failed)
        else
          status,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _state != _DeleteState.broadcasting,
      child: HorcruxScaffold(
        appBar: const HorcruxAppBar(title: 'Delete Account'),
        body: switch (_state) {
          _DeleteState.confirming => _buildConfirmingBody(),
          _DeleteState.broadcasting => _buildBroadcastingBody(),
          _DeleteState.success => _buildSuccessBody(),
          _DeleteState.failure => _buildFailureBody(),
        },
      ),
    );
  }

  Widget _buildConfirmingBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: KeyboardDismissWrapper(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              children: [
                Text(
                  'Danger! Deleting your account is irreversible. '
                  'This will send a request to all your stewards and relays to destory all '
                  'of your vaults, then destroy your private key and all vaults on '
                  'this device. Note that if you use other Nostr apps with this account '
                  'their data will also be deleted.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  'Type $_confirmPhrase to confirm.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: _confirmPhrase,
                  ),
                ),
              ],
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _confirmController,
            builder: (context, value, _) {
              final confirmed = value.text.trim() == _confirmPhrase;
              return RowButtonStack(
                buttons: [
                  RowButtonConfig(
                    onPressed: () => Navigator.pop(context),
                    icon: Icons.close,
                    text: 'Cancel',
                  ),
                  RowButtonConfig(
                    onPressed: confirmed ? _startDeletion : null,
                    icon: Icons.delete_forever,
                    text: 'Delete Account',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastingBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              'Requesting deletion from your relays…',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _relayStatuses.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) =>
                  _RelayPublishStatusRow(status: _relayStatuses[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBody() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(height: 24),
          Text(
            'Account deletion requested',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Returning to onboarding…',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFailureBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              'No relays confirmed the deletion request. Your account has not been '
              'deleted and your private key is still on this device.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _relayStatuses.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) =>
                  _RelayPublishStatusRow(status: _relayStatuses[index]),
            ),
          ),
          RowButtonStack(
            buttons: [
              RowButtonConfig(
                onPressed: () => Navigator.pop(context),
                icon: Icons.close,
                text: 'Cancel',
              ),
              RowButtonConfig(
                onPressed: _startDeletion,
                icon: Icons.refresh,
                text: 'Try Again',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RelayPublishStatusRow extends StatelessWidget {
  final RelayPublishStatus status;

  const _RelayPublishStatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.dns_outlined,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(status.relayUrl, style: theme.textTheme.bodyMedium),
          ),
          switch (status.state) {
            RelayPublishAckState.pending => Semantics(
                label: 'pending',
                container: true,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            RelayPublishAckState.acknowledged => Semantics(
                label: 'acknowledged',
                container: true,
                child: Icon(
                  Icons.check_circle,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            RelayPublishAckState.failed => Semantics(
                label: 'failed',
                container: true,
                child: Icon(
                  Icons.cancel,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
              ),
          },
        ],
      ),
    );
  }
}
