import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// A full-width button with an icon and text in a row layout
class RowButton extends StatelessWidget {
  final VoidCallback? onPressed; // Nullable for disabled state
  final IconData icon;
  final String text;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? iconSize;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final bool
  addBottomSafeArea; // Whether to add bottom safe area padding on iOS

  const RowButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
    this.backgroundColor,
    this.foregroundColor,
    this.iconSize = 24,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    this.addBottomSafeArea =
        false, // Default to false, set to true for bottom buttons
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null;
    final isDark = theme.brightness == Brightness.dark;

    // Get theme colors for buttons - use outlined style with subtle fill
    final borderColor = theme.colorScheme.primary;
    final textColor =
        theme.colorScheme.onSurface; // Use onSurface for better contrast
    // Very subtle background fill
    final subtleFill = isDark
        ? borderColor.withValues(alpha: 0.1)
        : borderColor.withValues(alpha: 0.05);

    // Disabled colors: use gray that works in both light and dark
    final disabledBorder = isDark
        ? const Color(0xFF404040)
        : const Color(0xFFC0C0C0);
    final disabledText = isDark
        ? const Color(0xFF808080)
        : const Color(0xFF808080);
    final disabledFill = isDark
        ? disabledBorder.withValues(alpha: 0.1)
        : disabledBorder.withValues(alpha: 0.05);

    // Effective colors
    final effectiveBorderColor = isDisabled
        ? disabledBorder
        : (backgroundColor ?? borderColor);
    final effectiveForegroundColor = isDisabled
        ? disabledText
        : (foregroundColor ?? textColor);
    final effectiveFill = isDisabled ? disabledFill : subtleFill;

    // Subtle shadow for enabled buttons
    final shadowColor = isDark
        ? borderColor.withValues(alpha: 0.1)
        : borderColor.withValues(alpha: 0.1);

    // Add bottom safe area padding on iOS devices with home indicator
    // Note: Platform.isIOS is not available on web, so check kIsWeb first
    final bottomSafeArea = addBottomSafeArea && !kIsWeb && Platform.isIOS
        ? 8.0
        : 0.0;

    // Calculate effective padding with safe area
    final effectivePadding = padding != null
        ? padding!.copyWith(bottom: padding!.bottom + bottomSafeArea)
        : EdgeInsets.only(
            top: 20,
            bottom: 20 + bottomSafeArea,
            left: 20,
            right: 20,
          );

    return InkWell(
      onTap: onPressed,
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: effectiveFill, // Subtle background fill
            border: Border.all(color: effectiveBorderColor, width: 0.5),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: effectiveForegroundColor, size: iconSize),
              const SizedBox(width: 12),
              Text(
                text,
                style:
                    textStyle ??
                    theme.textTheme.titleLarge?.copyWith(
                      color: effectiveForegroundColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
