import 'package:flutter/material.dart';

/// AppBar title wrapper for bead horcrux_app-dyc / Option B.
///
/// Flutter's `AppBar` wraps `title` in `DefaultTextStyle(softWrap: false,
/// overflow: ellipsis)` so a plain `Text` cannot wrap by itself. This widget
/// installs a fresh `DefaultTextStyle` that opts wrapping back on, then
/// renders the title text on up to two lines.
///
/// The theme's `toolbarHeight` should be tall enough to accommodate two lines
/// of the AppBar title (set in `theme.dart`).
class HorcruxAppBarTitle extends StatelessWidget {
  final String text;

  const HorcruxAppBarTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle();
    return DefaultTextStyle(
      style: base,
      softWrap: true,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      child: Text(text),
    );
  }
}
