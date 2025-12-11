import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/key_provider.dart';
import '../screens/horcrux_gallery_screen.dart';

/// Debug information sheet widget
class DebugInfoSheet extends ConsumerWidget {
  const DebugInfoSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both key providers
    final publicKeyAsync = ref.watch(currentPublicKeyProvider);
    final publicKeyBech32Async = ref.watch(currentPublicKeyBech32Provider);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Debug Information',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bech32 key
                publicKeyBech32Async.when(
                  loading: () => Text('Loading...', style: textTheme.bodySmall),
                  error: (err, _) => Text('Error: $err', style: textTheme.bodySmall),
                  data: (npub) => _KeyDisplay(
                    label: 'Npub (bech32):',
                    value: npub ?? 'Not available',
                    tooltipLabel: 'Npub',
                  ),
                ),
                const SizedBox(height: 12),
                // Hex key
                publicKeyAsync.when(
                  loading: () => Text('Loading...', style: textTheme.bodySmall),
                  error: (err, _) => Text('Error: $err', style: textTheme.bodySmall),
                  data: (pubkey) => _KeyDisplay(
                    label: 'Public Key (hex):',
                    value: pubkey ?? 'Not available',
                    tooltipLabel: 'Hex key',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // View Gallery button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close the debug sheet first
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HorcruxGallery(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.palette),
              label: const Text('View Design Gallery'),
            ),
          ),
        ],
      ),
    );
  }
}

// Key display widget with copy functionality
class _KeyDisplay extends StatelessWidget {
  final String label;
  final String value;
  final String tooltipLabel;

  const _KeyDisplay({
    required this.label,
    required this.value,
    required this.tooltipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.copy,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: value != 'Not available' && value != 'Loading...'
              ? () => _copyToClipboard(context, value, tooltipLabel)
              : null,
          tooltip: 'Copy $tooltipLabel',
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
