import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';

/// Dialog widget for displaying detailed steward information
class StewardDetailsDialog extends StatelessWidget {
  final String? pubkey;
  final String? displayName;
  final String? contactInfo;
  final bool isOwner;
  final BuildContext? rootContext;

  const StewardDetailsDialog({
    super.key,
    this.pubkey,
    this.displayName,
    this.contactInfo,
    required this.isOwner,
    this.rootContext,
  });

  /// Show steward details dialog
  static Future<void> show(
    BuildContext context, {
    String? pubkey,
    String? displayName,
    String? contactInfo,
    required bool isOwner,
  }) {
    return showDialog(
      context: context,
      builder: (dialogContext) => StewardDetailsDialog(
        pubkey: pubkey,
        displayName: displayName,
        contactInfo: contactInfo,
        isOwner: isOwner,
        rootContext: context, // Store original context for SnackBar
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Format Nostr ID (npub)
    String? nostrId;
    if (pubkey != null) {
      try {
        nostrId = Helpers.encodeBech32(pubkey!, 'npub');
      } catch (e) {
        nostrId = pubkey; // Fallback to hex if encoding fails
      }
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.person, color: colorScheme.onSurface),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName ?? 'Steward Details',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Owner',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (nostrId != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nostr ID',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      size: 18,
                      color: colorScheme.onSurface,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _copyToClipboard(context, nostrId!, 'Nostr ID'),
                    tooltip: 'Copy Nostr ID',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SelectableText(
                nostrId,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Contact Information',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (contactInfo != null && contactInfo!.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      size: 18,
                      color: colorScheme.onSurface,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _copyToClipboard(context, contactInfo!, 'Contact Information'),
                    tooltip: 'Copy Contact Information',
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (contactInfo != null && contactInfo!.isNotEmpty) ...[
              SelectableText(
                contactInfo!,
                style: theme.textTheme.bodyMedium,
              ),
            ] else ...[
              Text(
                'No contact information provided.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    // Use root context to ensure SnackBar shows even from dialog
    final scaffoldMessenger =
        rootContext != null ? ScaffoldMessenger.of(rootContext!) : ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
