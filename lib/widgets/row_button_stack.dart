import 'package:flutter/material.dart';
import 'row_button.dart';

/// Configuration for a single button in the stack
class RowButtonConfig {
  final VoidCallback? onPressed; // Nullable for disabled buttons
  final IconData icon;
  final String text;

  const RowButtonConfig({
    required this.onPressed,
    required this.icon,
    required this.text,
  });
}

/// A stack of RowButtons with an automatic gradient from primary orange at bottom
/// to progressively lighter/more muted colors going up
class RowButtonStack extends StatelessWidget {
  final List<RowButtonConfig> buttons;

  const RowButtonStack({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    // Generate gradient colors based on theme
    final colors = _generateGradientColors(buttons.length, context);

    // Get theme colors for text - all buttons use onSurface for outlined style
    final theme = Theme.of(context);
    final buttonTextColor =
        theme.colorScheme.onSurface; // Use onSurface for all buttons

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < buttons.length; i++)
          RowButton(
            onPressed: buttons[i].onPressed,
            icon: buttons[i].icon,
            text: buttons[i].text,
            backgroundColor:
                colors[i], // This controls the border color in outlined style
            foregroundColor:
                buttonTextColor, // All buttons use onSurface for contrast
            addBottomSafeArea:
                i == buttons.length - 1, // Only add safe area to bottom button
          ),
      ],
    );
  }

  /// Generate gradient colors: primary button color at bottom, then progressively lighter/darker going up
  List<Color> _generateGradientColors(int count, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Primary button color (black in light mode, white in dark mode)
    final primaryColor = theme.colorScheme.primary;

    if (count == 1) {
      return [primaryColor];
    }

    final colors = <Color>[];

    // For the new black/white theme, create a gradient using grays
    // Bottom button (primary) is the theme's button color
    // Buttons above get progressively lighter (in dark mode) or darker (in light mode)

    if (isDark) {
      // Dark mode: primary button (#404040) at bottom, progressively lighter grays going up
      const lightestGray = Color(0xFF606060); // Lighter gray for top buttons
      const lighterGray = Color(
        0xFF505050,
      ); // Slightly lighter than primary for buttons above

      for (int i = 0; i < count; i++) {
        if (i == count - 1) {
          // Bottom button is always primary (#404040)
          colors.add(primaryColor);
        } else {
          // Interpolate from lightestGray at top to lighterGray just above primary
          final t = count > 2 ? i / (count - 2) : 0.0;
          colors.add(Color.lerp(lightestGray, lighterGray, t)!);
        }
      }
    } else {
      // Light mode: primary button (#808080) at bottom, progressively darker grays going up
      const darkestGray = Color(
        0xFF606060,
      ); // Darker gray for buttons above primary
      const lighterGray = Color(
        0xFF707070,
      ); // Slightly lighter than primary for top buttons

      for (int i = 0; i < count; i++) {
        if (i == count - 1) {
          // Bottom button is always primary (#808080)
          colors.add(primaryColor);
        } else {
          // Interpolate from darkestGray just above primary to lighterGray at top
          final t = count > 2 ? i / (count - 2) : 0.0;
          colors.add(Color.lerp(darkestGray, lighterGray, t)!);
        }
      }
    }

    return colors;
  }
}
