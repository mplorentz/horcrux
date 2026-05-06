import 'dart:async';

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

/// Shows horcrux-styled toasts in an [Overlay] below the status bar / notch.
/// They stay at the **top** of the screen and may overlap [Scaffold.appBar].
/// ([SnackBarBehavior.floating] is bottom-anchored in the scaffold and does not
/// reliably honor vertical margins with Material 3.)
abstract final class HorcruxSnackBar {
  static OverlayEntry? _activeEntry;
  static Timer? _activeTimer;

  static void _finishCurrent() {
    _activeTimer?.cancel();
    _activeTimer = null;
    final entry = _activeEntry;
    _activeEntry = null;
    entry?.remove();
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
      case HorcruxSnackKind.info:
      case HorcruxSnackKind.success:
      case HorcruxSnackKind.warning:
        final bright = theme.brightness == Brightness.light;
        backgroundColor = bright ? const Color(0xFF2c2c2c) : const Color(0xFFf4f4f4);
        contentColor = bright ? const Color(0xFFf4f4f4) : const Color(0xFF0e0c0d);
    }

    final outlineColor =
        theme.brightness == Brightness.light ? const Color(0xFFf4f4f4) : const Color(0xFF0e0c0d);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: BorderSide(color: outlineColor.withValues(alpha: 0.35)),
    );

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
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    _finishCurrent();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: mq.viewPadding.top + 8,
        left: 16,
        right: 16,
        child: Semantics(
          container: true,
          liveRegion: true,
          child: Material(
            elevation: snackBarTheme.elevation ?? 2,
            surfaceTintColor: Colors.transparent,
            color: backgroundColor,
            shape: shape,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Text(message, style: textStyle)),
                  if (action != null)
                    TextButton(
                      onPressed: () {
                        action.onPressed();
                        if (_activeEntry == entry) {
                          _finishCurrent();
                        }
                      },
                      style: TextButton.styleFrom(foregroundColor: actionForeground),
                      child: Text(action.label),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
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
