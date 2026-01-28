import 'package:flutter/material.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import '../models/steward_status.dart';

/// Dialog widget for displaying detailed steward information
class StewardDetailsDialog extends StatelessWidget {
  final String? pubkey;
  final String? displayName;
  final String? contactInfo;
  final bool isOwner;
  final StewardStatus? status;

  const StewardDetailsDialog({
    super.key,
    this.pubkey,
    this.displayName,
    this.contactInfo,
    required this.isOwner,
    this.status,
  });

  /// Show steward details dialog
  static Future<void> show(
    BuildContext context, {
    String? pubkey,
    String? displayName,
    String? contactInfo,
    required bool isOwner,
    StewardStatus? status,
  }) {
    return showDialog(
      context: context,
      builder: (context) => StewardDetailsDialog(
        pubkey: pubkey,
        displayName: displayName,
        contactInfo: contactInfo,
        isOwner: isOwner,
        status: status,
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
          Icon(Icons.person, color: colorScheme.primary),
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
              Text(
                'Nostr ID',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
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
            if (status != null) ...[
              Text(
                'Status',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status!.label,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            if (contactInfo != null && contactInfo!.isNotEmpty) ...[
              Text(
                'Contact Information',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                contactInfo!,
                style: theme.textTheme.bodyMedium,
              ),
            ] else ...[
              Text(
                'Contact Information',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
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
}
