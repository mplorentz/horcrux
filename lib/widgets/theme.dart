import 'package:flutter/material.dart';

/// Horcrux app theme using bundled Archivo and OpenSans fonts
/// Fonts are bundled in fonts/ directory and declared in pubspec.yaml
final horcruxTheme = ThemeData(
  primaryColor: const Color(0xFFdc714e),
  scaffoldBackgroundColor: const Color(0xFFc1c4b1),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFdc714e),
    brightness: Brightness.light,
    secondary: const Color(0xFF21271c), // Accent color
    surfaceContainerHighest: const Color(0xFF7f8571), // Border/surface color
    surfaceContainer: const Color(0xFF464d41), // Icon background color
  ),
  fontFamily: 'Archivo', // Default font family (bundled in fonts/)
  textTheme: const TextTheme(
    // All text styles explicitly use Archivo font (bundled in fonts/)
    bodyMedium: TextStyle(
      color: Color(0xFF21271C), // Primary text color
      fontFamily: 'Archivo',
    ),
    bodySmall: TextStyle(
      color: Color(0xFF676f62), // Secondary text color
      fontFamily: 'OpenSans', // Override to OpenSans for small text
    ),
    labelSmall: TextStyle(
      color: Color(0xFF676f62), // Secondary text color
      fontFamily: 'OpenSans', // Override to OpenSans for labels
    ),
    displayLarge: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
    displayMedium: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
    displaySmall: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
    headlineLarge: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
    headlineMedium: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
    headlineSmall: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
    titleLarge: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
    titleMedium: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
    titleSmall: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
    bodyLarge: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
    labelLarge: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
    labelMedium: TextStyle(color: Color(0xFF21271C), fontFamily: 'Archivo'),
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFFc1c4b1), // Same as scaffold background
    elevation: 0,
    // shape: HorizontalBorderShape(
    //   topBorder: BorderSide(color: Color(0xFF7f8571), width: 2),
    //   bottomBorder: BorderSide(color: Color(0xFF7f8571), width: 2),
    // ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFc1c4b1), // Scaffold background color
    foregroundColor: Color(0xFF21271C), // Primary text color
    elevation: 0,
    toolbarHeight: 100.0, // Increased height for more vertical spacing
    titleSpacing: 32.0, // Double the default spacing
    leadingWidth: 32.0,
    titleTextStyle: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w500,
      color: Color(0xFF21271C),
      fontFamily: 'Archivo', // Uses bundled Archivo font
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    errorStyle: TextStyle(
      fontFamily: 'OpenSans', // Same as bodySmall
      fontSize: 12,
      // Color will be set from theme.colorScheme.error automatically
    ),
    hintStyle: TextStyle(
      color: Color.fromRGBO(
        103,
        111,
        98,
        0.6,
      ), // Lighter version of secondary text (0xFF676f62 at 60%)
      fontFamily: 'Archivo',
    ),
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

/// Horcrux v2 theme (terminal-adjacent, ledger vibes, flat, confident type)
final ThemeData horcrux2 = ThemeData(
  // Background slightly lighter / less green than 0xFFC1C4B1
  scaffoldBackgroundColor: const Color(0xFFc1c4b1),
  primaryColor: const Color(0xFFDC714E), // Accent for RowButton, etc.
  // Material 3 color scheme with explicit roles
  // Use an inky neutral as the seed so harmonized roles align with the ledger palette.
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF21271C),
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF243036), // Navy‑Ink as primary
    onPrimary: const Color(0xFFFDFFF0), // Ivory on inky
    secondary: const Color(0xFF7A4A2F), // Umber as secondary
    onSecondary: const Color(0xFFFDFFF0),
    // Calm, ledger-like olive/sage neutrals
    surface: const Color(0xFFc1c4b1),
    onSurface: const Color(0xFF21271C),
    // Match old horcruxTheme chip background for icon container in lists
    surfaceContainer: const Color(0xFF464D41),
    // Used around borders and low-contrast elements
    outline: const Color(0xFF7F8571),
    // Used by components that reference surface containers
    surfaceContainerHighest: const Color(0xFF8A917E),
    // Errors: use Material's standard error color (matches horcruxTheme)
    error: const Color(0xFFBA1A1A),
    onError: const Color(0xFFFDFFF0),
  ),
  // Keep it flat by removing tint; borderless, lower rounding like list screen
  cardTheme: const CardThemeData(
    color: Color(0xFFc1c4b1), // Match scaffold background
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFc1c4b1),
    foregroundColor: Color(0xFF21271C),
    elevation: 0,
    toolbarHeight: 100.0, // Increased height for more vertical spacing
    titleSpacing: 32.0, // Double the default spacing
    leadingWidth: 32.0,
    titleTextStyle: TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w500,
      fontFamily: 'Archivo',
      color: Color(0xFF21271C),
    ),
  ),
  // Inputs: preserve outlined borders and fill tone from v1 that you liked
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFc1c4b1), // Match scaffold background
    // No explicit label styles - use theme defaults like horcruxTheme
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4), // match vault_create_screen
      borderSide: const BorderSide(color: Color(0xFF7F8571), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF7F8571), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFF7F8571), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    hintStyle: const TextStyle(
      color: Color.fromRGBO(103, 111, 98, 0.6), // Match horcruxTheme hint style
      fontFamily: 'Archivo',
    ),
    errorStyle: const TextStyle(fontFamily: 'OpenSans', fontSize: 12),
  ),
  // Text selection and cursor (highlight when selecting text)
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Color(0xFF1E2A20),
    selectionColor: Color(0x331E2A20),
    selectionHandleColor: Color(0xFF1E2A20),
  ),
  // Primary buttons: accent with ivory text
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(
        0xFF243036,
      ), // Default Elevated = neutral primary
      foregroundColor: const Color(0xFFFDFFF0), // Ivory text
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  // Secondary buttons: rust tone with outlined treatment
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF7A4A2F),
      side: const BorderSide(color: Color(0xFF7A4A2F), width: 1.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  ),
  // Tertiary/text buttons: dark ink, confident type
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF1E2A20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  ),
  // Snackbar: flat, high-contrast
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Color(0xFF2C3227),
    contentTextStyle: TextStyle(
      color: Color(0xFFE9EDD9),
      fontFamily: 'OpenSans',
    ),
  ),
  // List tiles to align with VaultCard spacing/shape and icon emphasis
  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    // Match older horcruxTheme chevron/icon tone for lists
    iconColor: const Color(0xFF21271C),
    textColor: const Color(0xFF21271C),
    titleTextStyle: const TextStyle(
      fontFamily: 'Archivo',
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: Color(0xFF21271C),
    ),
    subtitleTextStyle: const TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 12,
      color: Color(0xFF5D695E),
    ),
  ),
  // Menus: flat with ledger paper feel
  popupMenuTheme: const PopupMenuThemeData(
    color: Color(0xFFc1c4b1),
    textStyle: TextStyle(color: Color(0xFF172018), fontFamily: 'OpenSans'),
    surfaceTintColor: Colors.transparent,
  ),
  // Typography: Archivo for titles, OpenSans for body
  fontFamily: 'OpenSans',
  textTheme: const TextTheme(
    // Big/section titles
    displayLarge: TextStyle(
      fontFamily: 'Archivo',
      fontWeight: FontWeight.w700,
      color: Color(0xFF21271C),
    ),
    displayMedium: TextStyle(
      fontFamily: 'Archivo',
      fontWeight: FontWeight.w700,
      color: Color(0xFF21271C),
    ),
    displaySmall: TextStyle(
      fontFamily: 'Archivo',
      fontWeight: FontWeight.w700,
      fontSize: 28,
      height: 36 / 28,
      color: Color(0xFF21271C),
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Archivo',
      fontWeight: FontWeight.w600,
      color: Color(0xFF21271C),
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Archivo',
      fontWeight: FontWeight.w600,
      color: Color(0xFF21271C),
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Archivo',
      fontWeight: FontWeight.w500,
      color: Color(0xFF21271C),
    ),
    // Body content
    bodyLarge: TextStyle(
      fontFamily: 'OpenSans',
      fontWeight: FontWeight.w500,
      fontSize: 14,
      height: 22 / 14,
      color: Color(0xFF21271C),
    ),
    bodyMedium: TextStyle(
      fontFamily: 'OpenSans',
      fontWeight: FontWeight.w400,
      fontSize: 14,
      height: 20 / 14,
      color: Color(0xFF21271C),
    ),
    bodySmall: TextStyle(
      fontFamily: 'OpenSans',
      fontWeight: FontWeight.w400,
      fontSize: 12,
      height: 16 / 12,
      color: Color(0xFF676F62),
    ),
    // Labels
    labelSmall: TextStyle(
      fontFamily: 'OpenSans',
      fontWeight: FontWeight.w500,
      fontSize: 12,
      height: 16 / 12,
      color: Color(0xFF5D695E),
    ),
    labelMedium: TextStyle(
      fontFamily: 'OpenSans',
      fontWeight: FontWeight.w600,
      color: Color(0xFF21271C),
    ),
    labelLarge: TextStyle(
      fontFamily: 'OpenSans',
      fontWeight: FontWeight.w600,
      color: Color(0xFF21271C),
    ),
    titleLarge: TextStyle(
      fontFamily: 'Archivo',
      fontWeight: FontWeight.w600,
      fontSize: 22,
      height: 24 / 18,
      color: Color(0xFF21271C),
    ),
    titleMedium: TextStyle(
      fontFamily: 'Archivo',
      fontWeight: FontWeight.w600,
      color: Color(0xFF21271C),
    ),
    titleSmall: TextStyle(
      fontFamily: 'Archivo',
      fontWeight: FontWeight.w600,
      color: Color(0xFF21271C),
    ),
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

/// Horcrux v3 theme - Stark black and white with subtle shadows
/// Light and dark variants that match system theme
ThemeData horcrux3(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  // Color definitions
  final scaffoldBg = isDark ? const Color(0xFF0e0c0d) : const Color(0xFFf4f4f4);
  final primaryText = isDark ? const Color(0xFFf4f4f4) : const Color(0xFF0e0c0d);
  final secondaryText = isDark ? const Color(0xFF808080) : const Color(0xFF808080);
  final dividerColor = isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
  final surface = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA);
  // More subtle button colors - medium grays instead of pure white/black
  final buttonBg = isDark ? const Color(0xFF404040) : const Color(0xFF808080);
  final buttonText = isDark ? const Color(0xFFf4f4f4) : const Color(0xFFf4f4f4);
  const error = Color(0xFFBA1A1A);
  // Practice banner colors - blue tones for practice mode indicators
  final practiceBannerBg =
      isDark ? const Color(0xFF1A2332) : const Color(0xFFE3F2FD); // blue[50] equivalent
  final practiceBannerIcon =
      isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2); // blue[700] equivalent
  final practiceBannerTitle =
      isDark ? const Color(0xFF90CAF9) : const Color(0xFF0D47A1); // blue[900] equivalent
  final practiceBannerText =
      isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2); // blue[700] equivalent

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: scaffoldBg,
    primaryColor: buttonBg,

    colorScheme: ColorScheme.fromSeed(
      seedColor: buttonBg,
      brightness: brightness,
    ).copyWith(
      primary: buttonBg,
      onPrimary: buttonText,
      secondary: secondaryText,
      onSecondary: primaryText,
      surface: surface,
      onSurface: primaryText,
      surfaceContainer: surface,
      outline: dividerColor,
      error: error,
      onError: scaffoldBg,
      // Practice banner colors
      tertiary: practiceBannerIcon,
      onTertiary: practiceBannerTitle,
      tertiaryContainer: practiceBannerBg,
      onTertiaryContainer: practiceBannerText,
    ),

    // Typography: Archivo for titles, Fira Sans for body
    fontFamily: 'FiraSans',
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 36 / 28,
        color: primaryText,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w500,
        color: primaryText,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'FiraSans',
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 22 / 14,
        color: primaryText,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'FiraSans',
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 20 / 14,
        color: primaryText,
      ),
      bodySmall: TextStyle(
        fontFamily: 'FiraSans',
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 16 / 12,
        color: secondaryText,
      ),
      labelSmall: TextStyle(
        fontFamily: 'FiraSans',
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 16 / 12,
        color: secondaryText,
      ),
      labelMedium: TextStyle(
        fontFamily: 'FiraSans',
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      labelLarge: TextStyle(
        fontFamily: 'FiraSans',
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w600,
        fontSize: 22,
        height: 24 / 18,
        color: primaryText,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
    ),

    // AppBar: stark, minimal
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBg,
      foregroundColor: primaryText,
      elevation: 0,
      surfaceTintColor: Colors.transparent, // Prevent bluish tint when scrolling
      toolbarHeight: 100.0,
      titleSpacing: 32.0,
      leadingWidth: 32.0,
      titleTextStyle: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w500,
        fontFamily: 'Archivo',
        color: primaryText,
      ),
    ),

    // Cards: match scaffold, no elevation
    cardTheme: CardThemeData(
      color: scaffoldBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    // Input fields: subtle borders
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scaffoldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: dividerColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: dividerColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: primaryText, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: TextStyle(
        color: secondaryText.withValues(alpha: 0.6),
        fontFamily: 'Archivo',
      ),
      errorStyle: const TextStyle(fontFamily: 'FiraSans', fontSize: 12),
    ),

    // Text selection
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: primaryText,
      selectionColor: primaryText.withValues(alpha: 0.2),
      selectionHandleColor: primaryText,
    ),

    // Buttons: rounded rects with subtle shadows
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonBg,
        foregroundColor: buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2, // Subtle shadow
        shadowColor: isDark ? buttonBg.withValues(alpha: 0.1) : buttonBg.withValues(alpha: 0.1),
      ),
    ),

    // Outlined buttons: borders with subtle shadows
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryText,
        side: BorderSide(color: primaryText, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),

    // Text buttons: minimal
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    ),

    // Divider: razor thin
    dividerTheme: DividerThemeData(
      color: dividerColor,
      thickness: 0.5,
      space: 1,
    ),

    // List tiles
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      iconColor: primaryText, // Icons use primary text color for high contrast
      textColor: primaryText,
      titleTextStyle: TextStyle(
        fontFamily: 'Archivo',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: primaryText,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'FiraSans',
        fontSize: 12,
        color: secondaryText,
      ),
    ),

    // Popup menus
    popupMenuTheme: PopupMenuThemeData(
      color: scaffoldBg,
      textStyle: TextStyle(color: primaryText, fontFamily: 'FiraSans'),
      surfaceTintColor: Colors.transparent,
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFF2C2C2C),
      contentTextStyle: const TextStyle(
        color: Color(0xFFf4f4f4), // Light text for dark snackbar backgrounds
        fontFamily: 'FiraSans',
      ),
    ),

    // Switch: high contrast for visibility
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          // When on, use primary text color for high contrast
          return primaryText;
        }
        // When off, use a much lighter color for better visibility against dark backgrounds
        return isDark ? const Color(0xFFAAAAAA) : const Color(0xFFE0E0E0);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          // When on, use a darker color for the track
          return isDark ? const Color(0xFF404040) : const Color(0xFF666666);
        }
        // When off, use a darker color that creates clear contrast with the light thumb
        return isDark ? const Color(0xFF555555) : const Color(0xFFB0B0B0);
      }),
    ),

    // Slider: high contrast for visibility
    sliderTheme: SliderThemeData(
      thumbColor:
          isDark ? Colors.white : primaryText, // White in dark mode, primary text in light mode
      activeTrackColor: isDark ? Colors.white : primaryText, // Active track matches thumb
      inactiveTrackColor: isDark
          ? const Color(0xFF555555)
          : const Color(0xFFB0B0B0), // Inactive track with good contrast
      overlayColor: (isDark ? Colors.white : primaryText)
          .withValues(alpha: 0.1), // Subtle overlay when dragging
      valueIndicatorColor: isDark ? Colors.white : primaryText, // Value indicator color
      valueIndicatorTextStyle: TextStyle(
        color: scaffoldBg, // Text color for value indicator
        fontFamily: 'FiraSans',
        fontSize: 12,
      ),
    ),

    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}

/// Horcrux v3 light theme
final ThemeData horcrux3Light = horcrux3(Brightness.light);

/// Horcrux v3 dark theme
final ThemeData horcrux3Dark = horcrux3(Brightness.dark);
