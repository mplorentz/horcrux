import 'package:flutter/material.dart';

/// AppBar title wrapper for bead horcrux_app-dyc / Option C.
///
/// Wraps the title text in a `FittedBox(fit: BoxFit.scaleDown)` so the title
/// stays on a single line at any phone width. The text never grows past the
/// theme's titleTextStyle size, but it is allowed to shrink uniformly until
/// it fits the available width. This option intentionally has *no minimum
/// font size* — it always fits.
///
/// Tradeoff: long titles can render very small (e.g. 20pt) and the header
/// rhythm becomes unpredictable across screens. See bead notes for the full
/// design tradeoff vs Options B / E / H.
class HorcruxAppBarTitle extends StatelessWidget {
  final String text;

  const HorcruxAppBarTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle();
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: DefaultTextStyle(
        style: base,
        softWrap: false,
        maxLines: 1,
        overflow: TextOverflow.visible,
        child: Text(text),
      ),
    );
  }
}
