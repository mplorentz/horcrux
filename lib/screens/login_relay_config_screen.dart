import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/relay_configuration.dart';
import '../providers/vault_provider.dart';
import '../services/ndk_service.dart';
import '../services/relay_scan_service.dart';
import '../services/logger.dart';
import '../utils/invite_code_utils.dart';
import '../utils/validators.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button_stack.dart';
import 'import_success_screen.dart';
import 'vault_list_screen.dart';

enum _ScanState { editing, scanning, results }

/// Shown after login so the user can configure which relays to scan for
/// pre-existing vaults before entering the app.
class LoginRelayConfigScreen extends ConsumerStatefulWidget {
  /// The imported nsec — forwarded to [ImportSuccessScreen].
  final String nsec;

  const LoginRelayConfigScreen({super.key, required this.nsec});

  @override
  ConsumerState<LoginRelayConfigScreen> createState() => _LoginRelayConfigScreenState();
}

class _LoginRelayConfigScreenState extends ConsumerState<LoginRelayConfigScreen> {
  _ScanState _state = _ScanState.editing;

  /// Relay list managed locally; persisted to [RelayScanService] on scan start.
  late List<RelayConfiguration> _relays;

  /// Baseline vault count taken just before the scan starts.
  int _baselineVaultCount = 0;

  /// Vault count updated live from the vault stream during scanning.
  int _liveVaultCount = 0;

  /// Controls the 10-second visual progress bar.
  Timer? _progressTimer;
  double _progressValue = 0.0;

  static const Duration _progressDuration = Duration(seconds: 10);
  static const Duration _progressTickInterval = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _relays = [
      const RelayConfiguration(
        id: 'horcrux-default',
        url: RelayScanService.defaultHorcruxRelayUrl,
        name: 'Horcrux Relay',
        isEnabled: true,
        isTrusted: false,
      ),
    ];
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  int get _vaultsFound => (_liveVaultCount - _baselineVaultCount).clamp(0, 9999);

  // ── relay editing ──────────────────────────────────────────────────────────

  void _removeRelay(RelayConfiguration relay) {
    setState(() => _relays.removeWhere((r) => r.id == relay.id));
  }

  Future<void> _addRelay() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddRelayDialog(),
    );
    if (result == null) return;

    final url = result['url'] as String;
    if (_relays.any((r) => r.url == url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That relay is already in the list.')),
        );
      }
      return;
    }

    setState(() {
      _relays.add(
        RelayConfiguration(
          id: generateSecureID(),
          url: url,
          name: url,
          isEnabled: true,
          isTrusted: false,
        ),
      );
    });
  }

  // ── scanning ───────────────────────────────────────────────────────────────

  Future<void> _startScan() async {
    if (_relays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one relay before scanning.'),
        ),
      );
      return;
    }

    // Persist relay list to service.
    final relayScanService = ref.read(relayScanServiceProvider);
    await relayScanService.clearAll();
    for (final relay in _relays) {
      try {
        await relayScanService.addRelayConfiguration(relay);
      } catch (e) {
        Log.error('Error persisting relay during onboarding scan', e);
      }
    }

    // Snapshot current vault count.
    final current = ref.read(vaultDetailListProvider).valueOrNull ?? [];
    _baselineVaultCount = current.length;
    _liveVaultCount = current.length;

    // Start live subscriptions via existing service.
    await relayScanService.ensureScanningStarted();

    // Fire one-shot historical query (does not block).
    final relayUrls = _relays.map((r) => r.url).toList();
    unawaited(
      ref.read(ndkServiceProvider).queryHistoricalGiftWraps(relayUrls: relayUrls),
    );

    // Visual progress: 100ms ticks over 10 seconds.
    _progressValue = 0.0;
    _progressTimer = Timer.periodic(_progressTickInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = _progressValue +
          (_progressTickInterval.inMilliseconds / _progressDuration.inMilliseconds);
      if (next >= 1.0) {
        timer.cancel();
        setState(() {
          _progressValue = 1.0;
          _state = _ScanState.results;
        });
      } else {
        setState(() => _progressValue = next);
      }
    });

    setState(() => _state = _ScanState.scanning);
  }

  void _tryAgain() {
    _progressTimer?.cancel();
    setState(() {
      _state = _ScanState.editing;
      _progressValue = 0.0;
    });
  }

  /// After a successful scan the user goes straight to the vault list.
  void _continue() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const VaultListScreen()),
      (route) => false,
    );
  }

  /// Skip the scan — offer to back up the key in a vault first.
  void _skip() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ImportSuccessScreen(nsec: widget.nsec)),
      (route) => false,
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Track vault count reactively while scanning.
    ref.listen(vaultDetailListProvider, (_, next) {
      final count = next.valueOrNull?.length ?? 0;
      if ((_state == _ScanState.scanning || _state == _ScanState.results) && mounted) {
        setState(() => _liveVaultCount = count);
      }
    });

    return PopScope(
      canPop: false,
      child: HorcruxScaffold(
        appBar: const HorcruxAppBar(
          title: 'Load Vaults',
          automaticallyImplyLeading: false,
        ),
        body: switch (_state) {
          _ScanState.editing => _buildEditingBody(),
          _ScanState.scanning => _buildScanningBody(),
          _ScanState.results => _buildResultsBody(),
        },
      ),
    );
  }

  Widget _buildEditingBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              children: [
                Text(
                  "Do you have existing Horcrux vaults we should restore? We'll scan these relays for vaults backed up to this key. "
                  'The official Horcrux relay is added already.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ..._relays.map(
                  (relay) => _RelayRow(
                    relay: relay,
                    onDelete: () => _removeRelay(relay),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addRelay,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Relay'),
                ),
              ],
            ),
          ),
          RowButtonStack(
            buttons: [
              RowButtonConfig(
                onPressed: _startScan,
                icon: Icons.search,
                text: 'Scan for Vaults',
              ),
              RowButtonConfig(
                onPressed: _skip,
                icon: Icons.skip_next,
                text: 'Skip',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanningBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Scanning relays…',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            LinearProgressIndicator(value: _progressValue),
            const SizedBox(height: 16),
            Text(
              'Found $_vaultsFound vault${_vaultsFound == 1 ? '' : 's'} so far',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsBody() {
    final count = _vaultsFound;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    count > 0 ? Icons.lock_open : Icons.search_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    count > 0
                        ? 'Found $count vault${count == 1 ? '' : 's'}'
                        : 'No vaults found yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    count > 0
                        ? 'Your vaults are ready. Tap Continue to enter the app.'
                        : 'The scan is still running in the background. You can '
                            'continue into the app and vaults will appear as they '
                            'arrive, or try again with different relays.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          RowButtonStack(
            buttons: [
              RowButtonConfig(
                onPressed: _continue,
                icon: Icons.arrow_forward,
                text: 'Continue',
              ),
              RowButtonConfig(
                onPressed: _tryAgain,
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

// ── sub-widgets ───────────────────────────────────────────────────────────────

class _RelayRow extends StatelessWidget {
  final RelayConfiguration relay;
  final VoidCallback onDelete;

  const _RelayRow({required this.relay, required this.onDelete});

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
            child: Text(relay.url, style: theme.textTheme.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDelete,
            tooltip: 'Remove relay',
          ),
        ],
      ),
    );
  }
}

/// Minimal dialog for adding a relay URL.
class _AddRelayDialog extends StatefulWidget {
  const _AddRelayDialog();

  @override
  State<_AddRelayDialog> createState() => _AddRelayDialogState();
}

class _AddRelayDialogState extends State<_AddRelayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Relay'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _urlController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Relay URL',
            hintText: 'wss://relay.example.com',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a URL';
            }
            if (!isValidRelayUrl(value.trim())) {
              return 'URL must start with ws:// or wss://';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {'url': _urlController.text.trim()});
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
