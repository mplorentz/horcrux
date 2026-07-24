import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/row_button_stack.dart';
import 'feedback_screen.dart';

/// Full-screen recovery UI when app initialization fails (e.g. database open).
///
/// Offers restart plus a path to [FeedbackScreen] so users are not stuck with
/// only a useless reload when the underlying error persists.
class InitializationErrorScreen extends StatelessWidget {
  final String error;

  /// Override for tests; production defaults to [exit]ing the process.
  final VoidCallback? onRestart;

  const InitializationErrorScreen({
    super.key,
    required this.error,
    this.onRestart,
  });

  void _openFeedback(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FeedbackScreen(
          initialMessage: 'App failed to initialize:\n\n$error',
        ),
      ),
    );
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
                  icon: Icons.feedback_outlined,
                  text: 'Send Feedback',
                ),
                RowButtonConfig(
                  onPressed: onRestart ?? () => exit(0),
                  icon: Icons.refresh,
                  text: 'Restart App',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
