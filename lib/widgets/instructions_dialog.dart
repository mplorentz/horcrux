import 'package:flutter/material.dart';

/// Dialog widget for displaying steward instructions
class InstructionsDialog extends StatelessWidget {
  final String? instructions;

  const InstructionsDialog({super.key, required this.instructions});

  /// Show instructions dialog
  static Future<void> show(BuildContext context, String? instructions) {
    return showDialog(
      context: context,
      builder: (context) => InstructionsDialog(instructions: instructions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 8),
          Text('Steward Instructions'),
        ],
      ),
      content: SingleChildScrollView(
        child: instructions != null && instructions!.isNotEmpty
            ? Text(instructions!, style: Theme.of(context).textTheme.bodyMedium)
            : Text(
                'No instructions provided.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
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
