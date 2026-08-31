import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/row_button_stack.dart';
import 'feedback_screen.dart';

/// Full-screen recovery UI when app initialization fails (e.g. database open).
///
/// Offers restart, a path to [FeedbackScreen], and — when [onResetDatabase] is
/// provided — a destructive "Reset Database" recovery for an unrecoverable
/// database, so users are not stuck with only a useless reload when the
/// underlying error persists.
class InitializationErrorScreen extends StatelessWidget {
  final String error;

  /// Override for tests; production defaults to [exit]ing the process.
  final VoidCallback? onRestart;

  /// Wipes local data and re-logs-in with the existing key, then re-initializes.
  /// When null (e.g. some tests) the Reset Database button is hidden.
  final Future<void> Function()? onResetDatabase;

  const InitializationErrorScreen({
    super.key,
    required this.error,
    this.onRestart,
    this.onResetDatabase,
  });

  void _openFeedback(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'FeedbackScreen'),
        builder: (context) => FeedbackScreen(
          title: 'Contact Support',
          initialMessage: 'App failed to initialize:\n\n$error',
        ),
      ),
    );
  }

  Future<void> _confirmAndReset(BuildContext context) async {
    final reset = onResetDatabase;
    if (reset == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Database?'),
        content: const Text(
          'This will permanently delete Horcrux data stored on this device, '
          'including vault data and keys you hold. Your sign-in key is kept and Horcrux will attempt to re-download your data from the network. If you had vault data stored locally you may need to recover it from your stewards. Contact support if you need help.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset Database'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false, // RowButtonStack handles bottom inset via addBottomSafeArea
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Initialization Failed',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            RowButtonStack(
              buttons: [
                RowButtonConfig(
                  onPressed: () => _openFeedback(context),
                  icon: Icons.support_agent_outlined,
                  text: 'Contact Support',
                ),
                RowButtonConfig(
                  onPressed: onRestart ?? () => exit(0),
                  icon: Icons.refresh,
                  text: 'Restart App',
                ),
                if (onResetDatabase != null)
                  RowButtonConfig(
                    onPressed: () => _confirmAndReset(context),
                    icon: Icons.delete_forever_outlined,
                    text: 'Reset Database',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
