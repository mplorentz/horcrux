import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Rich text that ends with a tappable "Learn more" link pointing to the
/// Horcrux privacy documentation. Used to explain push notification privacy
/// trade-offs consistently across the app.
class PushPrivacyLearnMoreText extends StatefulWidget {
  /// Text that precedes the "Learn more" link. A trailing space is expected.
  final String prefixText;

  /// Optional text style override. Defaults to [TextTheme.bodySmall].
  final TextStyle? style;

  const PushPrivacyLearnMoreText({
    super.key,
    this.prefixText = 'For maximum security you may want to disable push notifications. ',
    this.style,
  });

  @override
  State<PushPrivacyLearnMoreText> createState() => _PushPrivacyLearnMoreTextState();
}

class _PushPrivacyLearnMoreTextState extends State<PushPrivacyLearnMoreText> {
  static final _privacyUrl = Uri.parse('https://github.com/mplorentz/horcrux#privacy');

  late final TapGestureRecognizer _learnMoreTap = TapGestureRecognizer()..onTap = _onLearnMore;

  @override
  void dispose() {
    _learnMoreTap.dispose();
    super.dispose();
  }

  Future<void> _onLearnMore() async {
    await launchUrl(_privacyUrl, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? Theme.of(context).textTheme.bodySmall;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: widget.prefixText),
          TextSpan(
            text: 'Learn more',
            style: baseStyle?.copyWith(
              color: onSurface,
              decoration: TextDecoration.underline,
              decorationColor: onSurface,
            ),
            recognizer: _learnMoreTap,
          ),
          TextSpan(
            text: '.',
            style: baseStyle,
          ),
        ],
      ),
    );
  }
}
