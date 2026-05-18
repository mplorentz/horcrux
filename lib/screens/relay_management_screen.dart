import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/relay_configuration.dart';
import '../providers/vault_provider.dart';
import '../services/logger.dart';
import '../services/ndk_service.dart';
import '../services/relay_scan_service.dart';
import '../utils/invite_code_utils.dart';
import '../utils/snackbar_helper.dart';
import '../utils/validators.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button_stack.dart';

enum _ScanState { editing, scanning, results }

/// Settings screen for choosing which Nostr relays Horcrux scans.
class RelayManagementScreen extends ConsumerStatefulWidget {
  const RelayManagementScreen({super.key});

  @override
  ConsumerState<RelayManagementScreen> createState() => _RelayManagementScreenState();
}

class _RelayManagementScreenState extends ConsumerState<RelayManagementScreen> {
  _ScanState _state = _ScanState.editing;

  List<RelayConfiguration> _relays = [];
  bool _isLoading = true;

  int _baselineVaultCount = 0;
  int _liveVaultCount = 0;

  Timer? _progressTimer;
  double _progressValue = 0.0;

  static const Duration _progressDuration = Duration(seconds: 10);
  static const Duration _progressTickInterval = Duration(milliseconds: 100);

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  int get _vaultsFound => (_liveVaultCount - _baselineVaultCount).clamp(0, 9999);

  Future<void> _loadRelays() async {
    try {
      final relays = await ref.read(relayScanServiceProvider).getRelayConfigurations();
      if (mounted) {
        setState(() {
          _relays = relays;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      Log.error('Error loading relay configurations', e, st);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRelays();
  }

  Map<String, Set<String>> _vaultNamesByRelayUrl() {
    final vaults = ref.read(vaultDetailListProvider).valueOrNull ?? const [];
    final map = <String, Set<String>>{};
    for (final v in vaults) {
      final urls = v.backupConfig?.relays;
      if (urls == null) continue;
      for (final url in urls) {
        map.putIfAbsent(url, () => {}).add(v.name);
      }
    }
    return map;
  }

  Future<void> _removeRelay(RelayConfiguration relay) async {
    final inUse = _vaultNamesByRelayUrl()[relay.url];
    if (inUse != null && inUse.isNotEmpty) {
      final names = inUse.toList()..sort();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cannot remove relay'),
          content: Text(
            'This relay is in use by ${inUse.length} vault${inUse.length == 1 ? '' : 's'}: '
            '${names.join(', ')}. Remove it from those vaults\' backup configs first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await ref.read(relayScanServiceProvider).removeRelayConfiguration(relay.id);
      if (!mounted) return;
      setState(() => _relays.removeWhere((r) => r.id == relay.id));
      context.showHorcruxSnackBar(
        'Removed relay',
        kind: HorcruxSnackKind.success,
      );
    } catch (e, st) {
      Log.error('Error removing relay', e, st);
      if (mounted) {
        context.showHorcruxSnackBar(
          'Error removing relay: $e',
          kind: HorcruxSnackKind.error,
        );
      }
    }
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
        context.showHorcruxSnackBar(
          'That relay is already in the list.',
          kind: HorcruxSnackKind.info,
        );
      }
      return;
    }

    final relay = RelayConfiguration(
      id: generateSecureID(),
      url: url,
      name: url,
      isEnabled: true,
      isTrusted: false,
    );

    try {
      await ref.read(relayScanServiceProvider).addRelayConfiguration(relay);
      if (!mounted) return;
      setState(() => _relays.add(relay));
      context.showHorcruxSnackBar(
        'Added relay',
        kind: HorcruxSnackKind.success,
      );
    } catch (e, st) {
      Log.error('Error adding relay', e, st);
      if (mounted) {
        context.showHorcruxSnackBar(
          'Error adding relay: $e',
          kind: HorcruxSnackKind.error,
        );
      }
    }
  }

  Future<void> _startScan() async {
    if (_state != _ScanState.editing) return;

    if (_relays.isEmpty) {
      context.showHorcruxSnackBar(
        'Add at least one relay before scanning.',
        kind: HorcruxSnackKind.info,
      );
      return;
    }

    setState(() => _state = _ScanState.scanning);

    final relayScanService = ref.read(relayScanServiceProvider);
    await relayScanService.ensureScanningStarted();
    if (!mounted) return;

    final current = ref.read(vaultDetailListProvider).valueOrNull ?? [];
    _baselineVaultCount = current.length;
    _liveVaultCount = current.length;

    final relayUrls = _relays.map((r) => r.url).toList();
    unawaited(
      ref
          .read(ndkServiceProvider)
          .queryHistoricalGiftWraps(relayUrls: relayUrls)
          .catchError((e, st) {
        Log.error('Error querying historical gift wraps', e, st);
      }),
    );

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
  }

  void _tryAgain() {
    _progressTimer?.cancel();
    setState(() {
      _state = _ScanState.editing;
      _progressValue = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(vaultDetailListProvider, (_, next) {
      final count = next.valueOrNull?.length ?? 0;
      if ((_state == _ScanState.scanning || _state == _ScanState.results) && mounted) {
        setState(() => _liveVaultCount = count);
      }
    });

    return HorcruxScaffold(
      appBar: const HorcruxAppBar(title: 'Relays'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : switch (_state) {
              _ScanState.editing => _buildEditingBody(),
              _ScanState.scanning => _buildScanningBody(),
              _ScanState.results => _buildResultsBody(),
            },
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
                  'Horcrux scans these relays to listen for vault updates and recovery '
                  'requests. You can manually enter additional relays to scan here.',
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
            ],
          ),
        ],
      ),
    );
  }

  void _cancelScan() {
    _progressTimer?.cancel();
    setState(() {
      _state = _ScanState.editing;
      _progressValue = 0.0;
    });
  }

  Widget _buildScanningBody() {
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
                  Text(
                    'Scanning relays…',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  LinearProgressIndicator(
                    value: _progressValue,
                    minHeight: 8,
                    color: Theme.of(context).colorScheme.onSurface,
                    backgroundColor: Theme.of(context).sliderTheme.inactiveTrackColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Found $_vaultsFound vault${_vaultsFound == 1 ? '' : 's'} so far',
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
                onPressed: _cancelScan,
                icon: Icons.close,
                text: 'Cancel',
              ),
            ],
          ),
        ],
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
                        ? 'Tap Continue to go back to settings.'
                        : 'The scan is still running in the background. Vaults may appear '
                            'as they arrive, or try again with different relays.',
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
                onPressed: _tryAgain,
                icon: Icons.arrow_back,
                text: 'Go Back',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
