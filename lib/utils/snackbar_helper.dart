import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Semantic category for [HorcruxSnackBar.show]. [HorcruxSnackKind.info],
/// [HorcruxSnackKind.success], and [HorcruxSnackKind.warning] share the same
/// high-contrast monochrome slab (horcrux3). Only [HorcruxSnackKind.error] uses
/// the theme error color.
enum HorcruxSnackKind {
  info,
  success,
  warning,
  error,
}

/// Positions snackbars just below [Scaffold.appBar] when one exists; otherwise
/// below the status bar. Uses an inverted light/dark slab for non-error kinds.
abstract final class HorcruxSnackBar {
  static const double _estimatedSnackHeight = 112;

  /// Shows a snackbar via [ScaffoldMessenger]. Prefer [BuildContext.showHorcruxSnackBar].
  static void show(
    BuildContext context, {
    required String message,
    HorcruxSnackKind kind = HorcruxSnackKind.info,
    Duration? duration,
    SnackBarAction? action,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mq = MediaQuery.of(context);
    final scaffold = Scaffold.maybeOf(context);

    final bool hasAppBar = scaffold?.widget.appBar != null;
    final double reservedTop;
    if (!hasAppBar) {
      reservedTop = mq.padding.top + 16;
    } else {
      final barHeight = scaffold!.appBarMaxHeight;
      reservedTop = (barHeight != null && barHeight > 0)
          ? barHeight + 8
          : mq.padding.top + kToolbarHeight + 8;
    }

    final screenHeight = mq.size.height;
    final bottomMargin = math.max(
      0.0,
      screenHeight - reservedTop - _estimatedSnackHeight,
    );

    final defaultDuration =
        kind == HorcruxSnackKind.error ? const Duration(seconds: 5) : const Duration(seconds: 4);

    final Color backgroundColor;
    final Color contentColor;
    final Color? closeIconColor;
    switch (kind) {
      case HorcruxSnackKind.error:
        backgroundColor = cs.error;
        // [ColorScheme.onError] is tied to scaffold tones in horcrux3; use a fixed
        // light foreground on error red for contrast.
        contentColor = const Color(0xFFf4f4f4);
        closeIconColor = contentColor;
      case HorcruxSnackKind.info:
      case HorcruxSnackKind.success:
      case HorcruxSnackKind.warning:
        final bright = theme.brightness == Brightness.light;
        backgroundColor = bright ? const Color(0xFF2c2c2c) : const Color(0xFFf4f4f4);
        contentColor = bright ? const Color(0xFFf4f4f4) : const Color(0xFF0e0c0d);
        closeIconColor = contentColor;
    }

    final outlineColor =
        theme.brightness == Brightness.light ? const Color(0xFFf4f4f4) : const Color(0xFF0e0c0d);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(color: contentColor) ??
              TextStyle(color: contentColor, fontSize: 14),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: duration ?? defaultDuration,
        action: action,
        dismissDirection: DismissDirection.up,
        showCloseIcon: kind == HorcruxSnackKind.error,
        closeIconColor: closeIconColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: outlineColor.withValues(alpha: 0.35)),
        ),
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
      ),
    );
  }
}

extension HorcruxSnackBarExtension on BuildContext {
  /// Shows a horcrux-styled snackbar (below app bar when present).
  void showHorcruxSnackBar(
    String message, {
    HorcruxSnackKind kind = HorcruxSnackKind.info,
    Duration? duration,
    SnackBarAction? action,
  }) {
    HorcruxSnackBar.show(
      this,
      message: message,
      kind: kind,
      duration: duration,
      action: action,
    );
  }
}
