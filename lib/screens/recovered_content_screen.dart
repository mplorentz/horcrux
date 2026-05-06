import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/horcrux_scaffold.dart';
import '../widgets/row_button.dart';

/// Full-screen view of recovered vault plaintext with copy support.
///
/// [SelectableText] and the clipboard intentionally surface the secret; this is
/// the dedicated UI for that after recovery.
class RecoveredContentScreen extends StatelessWidget {
  const RecoveredContentScreen({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return HorcruxScaffold(
      showNotificationBanner: false,
      appBar: AppBar(
        title: const Text('Vault Contents'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                content,
                style: const TextStyle(fontFamily: 'RobotoMono'),
              ),
            ),
          ),
          RowButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              }
            },
            icon: Icons.copy_all_outlined,
            text: 'Copy All',
            addBottomSafeArea: true,
          ),
        ],
      ),
    );
  }
}
