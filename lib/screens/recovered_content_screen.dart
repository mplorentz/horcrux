import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/horcrux_app_bar_title.dart';
import '../widgets/horcrux_scaffold.dart';

/// Full-screen view of recovered vault plaintext with copy support.
///
/// [SelectableText] and the clipboard intentionally surface the secret; this is
/// the dedicated UI for that after recovery.
class RecoveredContentScreen extends StatelessWidget {
  const RecoveredContentScreen({super.key, required this.content});

  final String content;

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HorcruxScaffold(
      showNotificationBanner: false,
      appBar: AppBar(
        centerTitle: false,
        title: const HorcruxAppBarTitle('Vault Contents'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy',
              onPressed: () => _copyToClipboard(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            content,
            style: const TextStyle(fontFamily: 'RobotoMono'),
          ),
        ),
      ),
    );
  }
}
