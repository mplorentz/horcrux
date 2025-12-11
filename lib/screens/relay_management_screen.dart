import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/relay_configuration.dart';
import '../services/relay_scan_service.dart';
import '../services/logger.dart';
import '../utils/invite_code_utils.dart';

/// Screen for managing Nostr relay configurations
class RelayManagementScreen extends ConsumerStatefulWidget {
  const RelayManagementScreen({super.key});

  @override
  ConsumerState<RelayManagementScreen> createState() => _RelayManagementScreenState();
}

class _RelayManagementScreenState extends ConsumerState<RelayManagementScreen> {
  List<RelayConfiguration> _relays = [];
  ScanningStatus? _scanningStatus;
  bool _isLoading = true;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final relays = await ref.read(relayScanServiceProvider).getRelayConfigurations();
      final scanningStatus = await ref.read(relayScanServiceProvider).getScanningStatus();
      final isScanning = await ref.read(relayScanServiceProvider).isScanningActive();

      if (mounted) {
        setState(() {
          _relays = relays;
          _scanningStatus = scanningStatus;
          _isScanning = isScanning;
          _isLoading = false;
        });
      }
    } catch (e) {
      Log.error('Error loading relay data', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addRelay() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddRelayDialog(),
    );

    if (result != null) {
      try {
        // Generate cryptographically secure relay configuration ID
        final relay = RelayConfiguration(
          id: generateSecureID(),
          url: result['url'] as String,
          name: result['name'] as String,
          isEnabled: true,
          isTrusted: result['isTrusted'] as bool? ?? false,
        );

        await ref.read(relayScanServiceProvider).addRelayConfiguration(relay);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Added relay: ${relay.name}')));
        }
      } catch (e) {
        Log.error('Error adding relay', e);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding relay: $e')));
        }
      }
    }
  }

  Future<void> _toggleRelay(RelayConfiguration relay) async {
    try {
      final updatedRelay = relay.copyWith(isEnabled: !relay.isEnabled);
      await ref.read(relayScanServiceProvider).updateRelayConfiguration(updatedRelay);
      await _loadData();
    } catch (e) {
      Log.error('Error toggling relay', e);
    }
  }

  Future<void> _deleteRelay(RelayConfiguration relay) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Relay'),
        content: Text('Are you sure you want to delete "${relay.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(relayScanServiceProvider).removeRelayConfiguration(relay.id);
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted relay: ${relay.name}')),
          );
        }
      } catch (e) {
        Log.error('Error deleting relay', e);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting relay: $e')));
        }
      }
    }
  }

  Future<void> _toggleScanning() async {
    try {
      if (_isScanning) {
        await ref.read(relayScanServiceProvider).stopRelayScanning();
      } else {
        await ref.read(relayScanServiceProvider).startRelayScanning();
      }
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isScanning ? 'Scanning stopped' : 'Scanning started',
            ),
          ),
        );
      }
    } catch (e) {
      Log.error('Error toggling scanning', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _scanNow() async {
    try {
      await ref.read(relayScanServiceProvider).scanNow();
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Manual scan completed')));
      }
    } catch (e) {
      Log.error('Error scanning relays', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error scanning: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relay Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Scanning status card
                if (_scanningStatus != null) _buildScanningStatusCard(),

                // Scanning controls
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleScanning,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isScanning ? Colors.red : Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(
                            _isScanning ? Icons.stop : Icons.play_arrow,
                          ),
                          label: Text(
                            _isScanning ? 'Stop Scanning' : 'Start Scanning',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _scanNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.search),
                        label: const Text('Scan Now'),
                      ),
                    ],
                  ),
                ),

                // Relay list
                Expanded(
                  child: _relays.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.dns_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No relays configured',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add your first relay',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _relays.length,
                          itemBuilder: (context, index) {
                            final relay = _relays[index];
                            return _buildRelayCard(relay);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRelay,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScanningStatusCard() {
    final status = _scanningStatus!;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isScanning ? Icons.sync : Icons.sync_disabled,
                  color: _isScanning ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  'Scanning Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Total Relays', '${status.totalRelays}'),
            _buildStatusRow('Active Relays', '${status.activeRelays}'),
            _buildStatusRow('Shares Found', '${status.sharesFound}'),
            _buildStatusRow('Requests Found', '${status.requestsFound}'),
            if (status.lastScan != null)
              _buildStatusRow('Last Scan', _formatDateTime(status.lastScan!)),
            if (status.lastError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Error: ${status.lastError}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRelayCard(RelayConfiguration relay) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: relay.isEnabled
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.grey[300],
          child: Icon(
            Icons.dns,
            color: relay.isEnabled ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ),
        title: Text(
          relay.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              relay.url,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (relay.isTrusted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Trusted',
                      style: TextStyle(fontSize: 10, color: Colors.green),
                    ),
                  ),
                if (!relay.isEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Disabled',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                if (relay.lastScanned != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Last scanned: ${_formatDateTime(relay.lastScanned!)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(relay.isEnabled ? Icons.pause : Icons.play_arrow),
                  const SizedBox(width: 8),
                  Text(relay.isEnabled ? 'Disable' : 'Enable'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'toggle') {
              _toggleRelay(relay);
            } else if (value == 'delete') {
              _deleteRelay(relay);
            }
          },
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Dialog for adding a new relay
class _AddRelayDialog extends StatefulWidget {
  const _AddRelayDialog();

  @override
  _AddRelayDialogState createState() => _AddRelayDialogState();
}

class _AddRelayDialogState extends State<_AddRelayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isTrusted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Relay'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Relay Name',
                hintText: 'e.g., My Trusted Relay',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Relay URL',
                hintText: 'wss://relay.example.com',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a URL';
                }
                if (!value.startsWith('ws://') && !value.startsWith('wss://')) {
                  return 'URL must start with ws:// or wss://';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Trusted Relay'),
              subtitle: const Text('Use for sensitive operations'),
              value: _isTrusted,
              onChanged: (value) {
                setState(() {
                  _isTrusted = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
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
              Navigator.pop(context, {
                'name': _nameController.text,
                'url': _urlController.text,
                'isTrusted': _isTrusted,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
