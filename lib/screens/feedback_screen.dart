import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feedback_service.dart';
import '../widgets/horcrux_app_bar.dart';
import '../widgets/horcrux_scaffold.dart';
import '../utils/snackbar_helper.dart';

/// Provider for the shared [FeedbackService] instance.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService(
    formspreeFormId: 'mgoqebnn',
  );
});

/// Screen where users can submit feedback directly to the maintainer.
///
/// The form POSTs to Formspree which emails the maintainer. Users can
/// optionally provide their email for a reply and include app diagnostics
/// to help with debugging.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _includeDiagnostics = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final service = ref.read(feedbackServiceProvider);
    final success = await service.submitFeedback(
      message: _messageController.text.trim(),
      email: _emailController.text.trim(),
      includeDiagnostics: _includeDiagnostics,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      context.showHorcruxSnackBar(
        'Feedback sent — thank you!',
        kind: HorcruxSnackKind.success,
      );
      Navigator.of(context).pop();
    } else {
      context.showHorcruxSnackBar(
        'Failed to send feedback. Please try again.',
        kind: HorcruxSnackKind.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return HorcruxScaffold(
      appBar: const HorcruxAppBar(title: 'Feedback'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info text
              Text(
                'Have feedback, a feature request, or ran into a bug? '
                'Let us know below. Your message goes directly to the developer.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  hintText: 'your@email.com — for us to reply',
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),

              // Message field
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'What\'s on your mind?',
                  filled: true,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Diagnostics toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Include app diagnostics',
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: Text(
                  'Appends version, OS, and recent logs to help debug issues',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                value: _includeDiagnostics,
                onChanged: (value) => setState(() => _includeDiagnostics = value),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Send Feedback',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
