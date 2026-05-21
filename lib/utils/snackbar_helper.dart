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

  /// Runs slide-out + fade, then removes the overlay entry. Cleared on immediate teardown.
  static VoidCallback? _animatedDismiss;

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

  /// Removes the active toast immediately (e.g. replaced by a new one).
  static void _finishImmediate() {
    _activeTimer?.cancel();
    _activeTimer = null;
    _animatedDismiss = null;
    final entry = _activeEntry;
    _activeEntry = null;
    // [OverlayEntry.remove] asserts a non-null overlay link; if the overlay was
    // torn down (hot restart, app exit) before the auto-dismiss timer fires,
    // the entry can already be unmounted.
    //
    // Also remove entries that are inserted but not yet mounted (e.g. when two
    // show() calls happen in the same synchronous block — the first entry is
    // inserted into the overlay but not yet built/mounted by the framework).
    // These entries are still valid OverlayEntry objects that need cleanup.
    if (entry != null) {
      if (entry.mounted) {
        entry.remove();
      } else {
        // Entry was inserted but not yet mounted — try to remove it anyway.
        // OverlayEntry.remove() on an unmounted entry throws if the overlay
        // link is null. We wrap in try/catch to handle this gracefully.
        try {
          entry.remove();
        } catch (_) {
          // Entry wasn't fully mounted — the overlay will simply not build it
          // since it hasn't been laid out yet.
        }
      }
    }
  }

  /// Plays exit animation then removes the overlay entry.
  static void _requestAnimatedDismiss() {
    _activeTimer?.cancel();
    _activeTimer = null;
    final dismiss = _animatedDismiss;
    _animatedDismiss = null;
    if (dismiss != null) {
      dismiss();
    } else if (_activeEntry != null) {
      _finishImmediate();
    }
  }

  static void _scheduleAutoDismiss(OverlayEntry entry, Duration duration) {
    _activeTimer?.cancel();
    _activeTimer = Timer(duration, () {
      if (_activeEntry != entry) {
        // This timer's entry was replaced by a newer toast. Try to remove
        // the old entry directly so it doesn't leak in the overlay.
        if (entry.mounted) {
          entry.remove();
        }
        return;
      }
      _requestAnimatedDismiss();
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

    final defaultDuration = kind == HorcruxSnackKind.error
        ? const Duration(milliseconds: 2500)
        : const Duration(seconds: 2);
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

    _finishImmediate();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        const horizontalToastMargin = 32.0;

        return Positioned(
          top: _toastTopPx(MediaQuery.of(ctx)),
          left: horizontalToastMargin,
          right: horizontalToastMargin,
          child: _HorcruxOverlayToast(
            entry: entry,
            message: message,
            textStyle: textStyle,
            theme: theme,
            shape: shape,
            snackBarTheme: snackBarTheme,
            backgroundColor: backgroundColor,
            actionForeground: actionForeground,
            action: action,
            autoDismissDuration: effectiveDuration,
          ),
        );
      },
    );

    _activeEntry = entry;
    overlay.insert(entry);
    _scheduleAutoDismiss(entry, effectiveDuration);
  }
}

/// Slide + fade from above; registers [HorcruxSnackBar._animatedDismiss] for timed/action dismiss.
class _HorcruxOverlayToast extends StatefulWidget {
  final Duration autoDismissDuration;

  const _HorcruxOverlayToast({
    required this.entry,
    required this.message,
    required this.textStyle,
    required this.theme,
    required this.shape,
    required this.snackBarTheme,
    required this.backgroundColor,
    required this.actionForeground,
    required this.action,
    required this.autoDismissDuration,
  });

  final OverlayEntry entry;
  final String message;
  final TextStyle textStyle;
  final ThemeData theme;
  final ShapeBorder shape;
  final SnackBarThemeData snackBarTheme;
  final Color backgroundColor;
  final Color actionForeground;
  final SnackBarAction? action;

  @override
  State<_HorcruxOverlayToast> createState() => _HorcruxOverlayToastState();
}

class _HorcruxOverlayToastState extends State<_HorcruxOverlayToast>
    with SingleTickerProviderStateMixin {
  static const horizontalContentPadding = 16.0;

  final UniqueKey _dismissKey = UniqueKey();

  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  late VoidCallback _boundDismiss;
  Timer? _autoDismissTimer;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _boundDismiss = _startDismiss;
    HorcruxSnackBar._animatedDismiss = _boundDismiss;
    _controller.forward();
    _autoDismissTimer = Timer(widget.autoDismissDuration, _startDismiss);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    if (HorcruxSnackBar._animatedDismiss == _boundDismiss) {
      HorcruxSnackBar._animatedDismiss = null;
    }
    _controller.dispose();
    super.dispose();
  }

  void _cancelAutoDismissTimer() {
    HorcruxSnackBar._activeTimer?.cancel();
    HorcruxSnackBar._activeTimer = null;
  }

  void _startDismiss() {
    if (_isExiting || !mounted) {
      return;
    }
    _isExiting = true;
    _cancelAutoDismissTimer();
    if (HorcruxSnackBar._animatedDismiss == _boundDismiss) {
      HorcruxSnackBar._animatedDismiss = null;
    }
    _controller.reverse().then((_) {
      if (!mounted) {
        return;
      }
      HorcruxSnackBar._activeEntry = null;
      widget.entry.remove();
    });
  }

  /// Swipe-away: [Dismissible] already animated the child off-screen.
  void _finishDismissFromSwipe() {
    if (_isExiting) {
      return;
    }
    _isExiting = true;
    _cancelAutoDismissTimer();
    if (HorcruxSnackBar._animatedDismiss == _boundDismiss) {
      HorcruxSnackBar._animatedDismiss = null;
    }
    _controller.stop();
    HorcruxSnackBar._activeEntry = null;
    widget.entry.remove();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Dismissible(
          key: _dismissKey,
          direction: DismissDirection.up,
          movementDuration: const Duration(milliseconds: 220),
          dismissThresholds: const {DismissDirection.up: 0.12},
          confirmDismiss: (_) async {
            _cancelAutoDismissTimer();
            return true;
          },
          onDismissed: (_) => _finishDismissFromSwipe(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxInnerWidth = constraints.maxWidth - 2 * horizontalContentPadding;
              final compact = HorcruxSnackBar._toastFitsCompactSingleLine(
                message: widget.message,
                textStyle: widget.textStyle,
                maxInnerWidth: maxInnerWidth,
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                action: widget.action,
                actionForeground: widget.actionForeground,
                theme: widget.theme,
              );

              void onActionPressed() {
                widget.action?.onPressed();
                if (HorcruxSnackBar._activeEntry == widget.entry) {
                  HorcruxSnackBar._requestAnimatedDismiss();
                }
              }

              final actionButton = widget.action == null
                  ? null
                  : TextButton(
                      onPressed: onActionPressed,
                      style: TextButton.styleFrom(foregroundColor: widget.actionForeground),
                      child: Text(widget.action!.label),
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
                      Text(widget.message, style: widget.textStyle)
                    else
                      Expanded(child: Text(widget.message, style: widget.textStyle)),
                    if (actionButton != null) ...[
                      if (compact) const SizedBox(width: 8),
                      actionButton,
                    ],
                  ],
                ),
              );

              final material = Material(
                elevation: widget.snackBarTheme.elevation ?? 2,
                surfaceTintColor: Colors.transparent,
                color: widget.backgroundColor,
                shape: widget.shape,
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
        ),
      ),
    );
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
