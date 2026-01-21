import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/debug_info_sheet.dart';
import '../widgets/horcrux_scaffold.dart';
import 'relay_management_screen.dart';
import 'account_management_screen.dart';

/// Settings screen with debug and relay management options
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showDebugInfo(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DebugInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return HorcruxScaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      body: ListView(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person, color: theme.colorScheme.onSurface),
            ),
            title: const Text('Account Management'),
            subtitle: const Text('View your Nostr ID and manage your account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountManagementScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.wifi, color: theme.colorScheme.onSurface),
            ),
            title: const Text('Relay Management'),
            subtitle: const Text('Configure and manage Nostr relays'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RelayManagementScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.bug_report, color: theme.colorScheme.onSurface),
            ),
            title: const Text('Debug Info'),
            subtitle: const Text('View keys and app information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDebugInfo(context, ref),
          ),
        ],
      ),
    );
  }
}
