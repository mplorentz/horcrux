import 'dart:async';
import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/material.dart';

/// Semantic category for [HorcruxSnackBar.show]. [HorcruxSnackKind.info] uses the
/// inverted monochrome slab. [HorcruxSnackKind.warning] uses medium grays from the
/// design palette (same family as RowButtonStack tones — no hue in DESIGN_GUIDE).
/// [HorcruxSnackKind.success] uses deep green (`0xFF2E7D32`). [HorcruxSnackKind.error]
/// uses the theme error color (`0xFFBA1A1A`).
enum HorcruxSnackKind {
  info,
  success,
  warning,
  error,
}

/// Shows horcrux-styled toasts in an [Overlay] below the status bar / notch.
/// Top inset uses [MediaQuery.viewPadding] plus [MediaQueryData.displayFeatures]
/// ([DisplayFeatureType.cutout]) so desktop windows without a cutout get extra
/// spacing; phones with notches rely on OS-reported padding.
/// They may overlap [Scaffold.appBar].
/// ([SnackBarBehavior.floating] is bottom-anchored in the scaffold and does not
/// reliably honor vertical margins with Material 3.)
abstract final class HorcruxSnackBar {
  static OverlayEntry? _activeEntry;
  static Timer? _activeTimer;

  /// True when the platform reports a display cutout overlapping the top band
  /// (notch / camera hole / Dynamic Island region).
  static bool _hasTopCutout(MediaQueryData mq) {
    for (final feature in mq.displayFeatures) {
      if (feature.type != DisplayFeatureType.cutout) {
        continue;
      }
      final b = feature.bounds;
      if (b.width <= 0 || b.height <= 0) {
        continue;
      }
      if (b.top < 48 && b.bottom > 0) {
        return true;
      }
    }
    return false;
  }

  /// Distance from the top of the view to place the toast (logical px).
  static double _toastTopPx(MediaQueryData mq) {
    const gapBelowSafeArea = 8.0;
    const extraWhenNoTopObstruction = 14.0;
    final vpTop = mq.viewPadding.top;
    final cutout = _hasTopCutout(mq);
    // Handheld notches and status bars usually set viewPadding.top (often ≥24).
    // Cutouts are also listed on many Android devices even when padding tracks them.
    if (vpTop >= 12 || cutout) {
      return vpTop + gapBelowSafeArea;
    }
    // macOS / Windows / Linux windows: no inset — breathe away from the title bar.
    return vpTop + gapBelowSafeArea + extraWhenNoTopObstruction;
  }

  static void _finishCurrent() {
    _activeTimer?.cancel();
    _activeTimer = null;
    final entry = _activeEntry;
    _activeEntry = null;
    // [OverlayEntry.remove] asserts a non-null overlay link; if the overlay was
    // torn down (hot restart, app exit) before the auto-dismiss timer fires,
    // the entry can already be unmounted.
    if (entry != null && entry.mounted) {
      entry.remove();
    }
  }

  static void _scheduleAutoDismiss(OverlayEntry entry, Duration duration) {
    _activeTimer?.cancel();
    _activeTimer = Timer(duration, () {
      if (_activeEntry != entry) {
        return;
      }
      _finishCurrent();
    });
  }

  /// Whether the message (+ optional action) fits on one row within
  /// [maxInnerWidth] so the toast can shrink-wrap and stay centered.
  static bool _toastFitsCompactSingleLine({
    required String message,
    required TextStyle textStyle,
    required double maxInnerWidth,
    required TextDirection textDirection,
    required TextScaler textScaler,
    SnackBarAction? action,
    required Color actionForeground,
    required ThemeData theme,
  }) {
    if (maxInnerWidth <= 0 || message.contains('\n')) {
      return false;
    }

    final msgPainter = TextPainter(
      text: TextSpan(text: message, style: textStyle),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout(maxWidth: double.infinity);

    var total = msgPainter.width;
    if (action != null) {
      final labelStyle =
          theme.textTheme.labelLarge ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
      final actionPainter = TextPainter(
        text: TextSpan(
          text: action.label,
          style: labelStyle.copyWith(color: actionForeground),
        ),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout(maxWidth: double.infinity);
      // Row gap + TextButton horizontal padding slack vs bare label width.
      total += 8 + actionPainter.width + 28;
    }

    return total <= maxInnerWidth + 0.5;
  }

  /// Shows a toast via [Overlay]. Prefer [BuildContext.showHorcruxSnackBar].
  static void show(
    BuildContext context, {
    required String message,
    HorcruxSnackKind kind = HorcruxSnackKind.info,
    Duration? duration,
    SnackBarAction? action,
  }) {
    final overlay = Overlay.maybeOf(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mq = MediaQuery.of(context);

    final defaultDuration =
        kind == HorcruxSnackKind.error ? const Duration(seconds: 5) : const Duration(seconds: 4);
    final effectiveDuration = duration ?? defaultDuration;

    final Color backgroundColor;
    final Color contentColor;
    switch (kind) {
      case HorcruxSnackKind.error:
        backgroundColor = cs.error;
        contentColor = const Color(0xFFf4f4f4);
      case HorcruxSnackKind.success:
        // Same deep green as vault status / recovery success accents.
        backgroundColor = const Color(0xFF2E7D32);
        contentColor = const Color(0xFFf4f4f4);
      case HorcruxSnackKind.info:
        final bright = theme.brightness == Brightness.light;
        backgroundColor = bright ? const Color(0xFF2c2c2c) : const Color(0xFFf4f4f4);
        contentColor = bright ? const Color(0xFFf4f4f4) : const Color(0xFF0e0c0d);
      case HorcruxSnackKind.warning:
        // DESIGN_GUIDE does not define a warning hue; use documented grays (#606060 / stack mids).
        backgroundColor = theme.brightness == Brightness.light
            ? const Color(0xFF606060)
            : const Color(0xFF505050);
        contentColor = const Color(0xFFf4f4f4);
    }

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(4));

    final textStyle = theme.textTheme.bodyMedium?.copyWith(color: contentColor) ??
        TextStyle(color: contentColor, fontSize: 14);

    final snackBarTheme = theme.snackBarTheme;
    final actionForeground =
        snackBarTheme.actionTextColor ?? snackBarTheme.contentTextStyle?.color ?? contentColor;

    if (overlay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: textStyle),
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          duration: effectiveDuration,
          action: action,
          dismissDirection: DismissDirection.up,
          showCloseIcon: false,
          shape: shape,
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      );
      return;
    }

    _finishCurrent();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        const horizontalToastMargin = 32.0;
        const horizontalContentPadding = 16.0;

        return Positioned(
          top: _toastTopPx(mq),
          left: horizontalToastMargin,
          right: horizontalToastMargin,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxInnerWidth = constraints.maxWidth - 2 * horizontalContentPadding;
              final compact = _toastFitsCompactSingleLine(
                message: message,
                textStyle: textStyle,
                maxInnerWidth: maxInnerWidth,
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                action: action,
                actionForeground: actionForeground,
                theme: theme,
              );

              void onActionPressed() {
                action?.onPressed();
                if (_activeEntry == entry) {
                  _finishCurrent();
                }
              }

              final actionButton = action == null
                  ? null
                  : TextButton(
                      onPressed: onActionPressed,
                      style: TextButton.styleFrom(foregroundColor: actionForeground),
                      child: Text(action.label),
                    );

              final paddedRow = Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: horizontalContentPadding,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (compact)
                      Text(message, style: textStyle)
                    else
                      Expanded(child: Text(message, style: textStyle)),
                    if (actionButton != null) ...[
                      if (compact) const SizedBox(width: 8),
                      actionButton,
                    ],
                  ],
                ),
              );

              final material = Material(
                elevation: snackBarTheme.elevation ?? 2,
                surfaceTintColor: Colors.transparent,
                color: backgroundColor,
                shape: shape,
                clipBehavior: Clip.antiAlias,
                child: paddedRow,
              );

              return Semantics(
                container: true,
                liveRegion: true,
                child: compact ? Align(alignment: Alignment.center, child: material) : material,
              );
            },
          ),
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
    _scheduleAutoDismiss(entry, effectiveDuration);
  }
}

extension HorcruxSnackBarExtension on BuildContext {
  /// Shows a horcrux-styled toast at the top of the screen (below status bar;
  /// may overlap the app bar).
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
