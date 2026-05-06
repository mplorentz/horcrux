import 'package:flutter/material.dart';

/// AppBar title wrapper for bead horcrux_app-dyc / Option H.
///
/// Auto-shrinks the title text on a single line, between [minFontSize] and
/// [maxFontSize] (defaults: 28pt..40pt). Falls back to ellipsis below the
/// floor so unusually long titles or wide-glyph languages stay legible.
///
/// Picks the largest font size in `[minFontSize, maxFontSize]` (in 1pt steps)
/// at which the rendered text fits the available width on one line. The
/// search runs at layout time via `LayoutBuilder` + `TextPainter`, so it
/// adapts to phone width, dynamic type, and i18n.
///
/// Compared to FittedBox (Option C), this widget never goes below 28pt — the
/// header still reads as a "headline" on every screen. Compared to wrap
/// (Option B), it stays single-line and avoids the extra vertical chrome.
class HorcruxAppBarTitle extends StatelessWidget {
  final String text;
  final double minFontSize;
  final double maxFontSize;

  const HorcruxAppBarTitle(
    this.text, {
    this.minFontSize = 28,
    this.maxFontSize = 40,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).appBarTheme.titleTextStyle ?? const TextStyle();
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        var fontSize = maxFontSize;
        while (fontSize > minFontSize) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: base.copyWith(fontSize: fontSize)),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout(maxWidth: maxWidth);
          if (!painter.didExceedMaxLines && painter.width <= maxWidth) {
            break;
          }
          fontSize -= 1;
        }
        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: base.copyWith(fontSize: fontSize),
        );
      },
    );
  }
}
