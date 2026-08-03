import 'package:flutter/material.dart';

/// Wraps a scrollable form body to provide tap-outside-to-dismiss keyboard
/// behavior.
///
/// Tapping anywhere outside a text field dismisses the keyboard. This is
/// complementary to [ScrollViewKeyboardDismissBehavior.onDrag] which should
/// also be set on the scrollable itself.
///
/// Usage:
/// ```dart
/// KeyboardDismissWrapper(
///   child: SingleChildScrollView(
///     keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
///     child: ...,
///   ),
/// )
/// ```
class KeyboardDismissWrapper extends StatelessWidget {
  final Widget child;

  const KeyboardDismissWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss the keyboard when tapping outside any text field.
      onTap: () => FocusScope.of(context).unfocus(),
      // translucent allows the tap to pass through to child widgets (buttons,
      // switches, etc.) so they still respond to taps.
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}
