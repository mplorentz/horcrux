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
import '../services/relay_scan_service.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button_stack.dart';

enum _DeleteState { confirming, broadcasting, success, failure }

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
  List<RelayVanishStatus> _relayStatuses = [];

  Future<void> _startDeletion() async {
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
          RelayVanishStatus(relayUrl: relay.url, state: RelayVanishAckState.pending),
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
        setState(() => _state = _DeleteState.failure);
      }
    } catch (e) {
      Log.error('Error deleting account', e);
      if (!mounted) return;
      setState(() => _state = _DeleteState.failure);
    }
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              children: [
                Text(
                  'Deleting your account is irreversible. This will sign and send a '
                  'request that your relays must honor to delete all of your data, '
                  'then remove your private key and all vault contents from this '
                  'device. Make sure you have your private key backed up or you will '
                  'lose access to this account. Your stewards will still be able to '
                  'recover your vaults unless you delete them individually.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
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
                icon: Icons.delete_forever,
                text: 'Delete Account',
              ),
            ],
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
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final status in _relayStatuses) _VanishRelayRow(status: status),
              ],
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
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final status in _relayStatuses) _VanishRelayRow(status: status),
              ],
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

class _VanishRelayRow extends StatelessWidget {
  final RelayVanishStatus status;

  const _VanishRelayRow({required this.status});

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
            RelayVanishAckState.pending => const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            RelayVanishAckState.acknowledged => const Icon(
                Icons.check_circle,
                size: 20,
                color: Colors.green,
              ),
            RelayVanishAckState.failed => const Icon(
                Icons.cancel,
                size: 20,
                color: Colors.red,
              ),
          },
        ],
      ),
    );
  }
}
