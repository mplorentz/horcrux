import 'package:flutter/material.dart';

/// Form fields for analytics opt-in, email, and mailing-list consent.
///
/// Rendered ABOVE the ToS + Privacy Policy legal text on the onboarding
/// consent screen. All values are independent of the ToS "I agree" checkbox.
///
/// The mailing-list checkbox is disabled (greyed out and non-tappable) until
/// the email field contains non-empty text.
class ConsentFormFields extends StatelessWidget {
  final bool analyticsOptIn;
  final TextEditingController emailController;
  final bool mailingList;
  final ValueChanged<bool> onAnalyticsOptInChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<bool> onMailingListChanged;

  const ConsentFormFields({
    super.key,
    required this.analyticsOptIn,
    required this.emailController,
    required this.mailingList,
    required this.onAnalyticsOptInChanged,
    required this.onEmailChanged,
    required this.onMailingListChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final hasEmail = emailController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Analytics opt-in checkbox ---
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: analyticsOptIn,
                onChanged: (v) => onAnalyticsOptInChanged(v ?? false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => onAnalyticsOptInChanged(!analyticsOptIn),
                child: Text(
                  'Allow Horcrux to collect analytics',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Email intro text ---
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            "If you'd like, you can associate an email with your account "
            "so we can contact you — for example, if there's an issue "
            'affecting your data. Enter one below (optional):',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),

        // --- Email field ---
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'your@email.com',
            filled: true,
          ),
          onChanged: onEmailChanged,
        ),
        const SizedBox(height: 12),

        // --- Mailing-list checkbox (disabled until email is non-empty) ---
        Opacity(
          opacity: hasEmail ? 1.0 : 0.5,
          child: AbsorbPointer(
            absorbing: !hasEmail,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: hasEmail ? mailingList : false,
                    onChanged: hasEmail
                        ? (v) => onMailingListChanged(v ?? false)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: hasEmail
                        ? () => onMailingListChanged(!mailingList)
                        : null,
                    child: Text(
                      'Also subscribe me to product updates',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
      ],
    );
  }
}