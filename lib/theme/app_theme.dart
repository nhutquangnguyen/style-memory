import 'package:flutter/material.dart';

class AppTheme {
  // Modern Color Palette - Beauty & Style Industry Inspired
  // Primary - Elegant Rose Gold/Coral for sophistication
  static const Color primaryColor = Color(0xFF6366F1); // Indigo - professional yet stylish
  static const Color primaryLightColor = Color(0xFF818CF8); // Lighter indigo
  static const Color primaryDarkColor = Color(0xFF4F46E5); // Deeper indigo

  // Secondary - Warm coral for accents
  static const Color secondaryColor = Color(0xFFF59E0B); // Amber gold
  static const Color secondaryLightColor = Color(0xFFFBBF24); // Light amber
  static const Color secondaryDarkColor = Color(0xFFD97706); // Dark amber

  // Neutrals - Rich grays with more character
  static const Color backgroundColor = Color(0xFFFAFAFB); // Softer white
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
  static const Color cardColor = Color(0xFFFFFFFF); // Pure white cards
  static const Color primaryTextColor = Color(0xFF111827); // Rich dark gray
  static const Color secondaryTextColor = Color(0xFF6B7280); // Medium gray
  static const Color mutedTextColor = Color(0xFF9CA3AF); // Light gray

  // Status colors
  static const Color successColor = Color(0xFF10B981); // Emerald green
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color infoColor = Color(0xFF3B82F6); // Blue

  // Border colors
  static const Color borderColor = Color(0xFFE5E7EB); // Light gray border
  static const Color borderLightColor = Color(0xFFF3F4F6); // Very light border
  static const Color borderDarkColor = Color(0xFFD1D5DB); // Medium border

  // Shadow colors
  static const Color shadowColor = Color(0x26000000); // 15% black (increased from 10%)
  static const Color shadowLightColor = Color(0x1A000000); // 10% black (increased from 5%)
  static const Color shadowDarkColor = Color(0x33000000); // 20% black (increased from 15%)

  // Spacing System - Enhanced scale
  static const double spacingXs = 2.0;
  static const double spacingVerySmall = 4.0;
  static const double spacingSm = 6.0;
  static const double spacingSmall = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingMedium = 16.0;
  static const double spacingLg = 20.0;
  static const double spacingLarge = 24.0;
  static const double spacingXl = 28.0;
  static const double spacingExtraLarge = 32.0;
  static const double spacing2xl = 40.0;
  static const double spacing3xl = 48.0;
  static const double spacing4xl = 64.0;

  // Border Radius System
  static const double borderRadiusXs = 4.0;
  static const double borderRadiusSmall = 6.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXl = 16.0;
  static const double borderRadius2xl = 20.0;
  static const double borderRadius3xl = 24.0;
  static const double borderRadiusFull = 9999.0; // For circular elements

  // Elevation System
  static const double elevationNone = 0.0;
  static const double elevationLow = 3.0; // Increased from 2.0
  static const double elevationMedium = 6.0; // Increased from 4.0
  static const double elevationHigh = 12.0; // Increased from 8.0
  static const double elevationVeryHigh = 20.0; // Increased from 16.0

  // Icon Sizes
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double icon2xl = 48.0;
  static const double icon3xl = 64.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,

      // Enhanced Color scheme with new palette
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLightColor,
        secondary: secondaryColor,
        secondaryContainer: secondaryLightColor,
        tertiary: infoColor,
        error: errorColor,
        surface: backgroundColor,
        surfaceContainer: surfaceColor,
        surfaceContainerHighest: cardColor,
        outline: borderColor,
        onPrimary: Colors.white,
        onPrimaryContainer: primaryTextColor,
        onSecondary: Colors.white,
        onSecondaryContainer: primaryTextColor,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: primaryTextColor,
        onSurfaceVariant: secondaryTextColor,
      ),

      // Enhanced Typography System
      textTheme: const TextTheme(
        // Display styles - for heroes and major headers
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: primaryTextColor,
          height: 1.1,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: primaryTextColor,
          height: 1.2,
          letterSpacing: -0.25,
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
          height: 1.2,
        ),

        // Headline styles - for page titles and section headers
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
          height: 1.4,
        ),

        // Title styles - for card titles and component headers
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
          height: 1.4,
        ),

        // Body styles - for main content
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: primaryTextColor,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: primaryTextColor,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondaryTextColor,
          height: 1.4,
        ),

        // Label styles - for buttons, forms, and UI elements
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
          height: 1.4,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: primaryTextColor,
          height: 1.4,
          letterSpacing: 0.1,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: secondaryTextColor,
          height: 1.4,
          letterSpacing: 0.15,
        ),
      ),

      // Enhanced App Bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: shadowLightColor,
        scrolledUnderElevation: elevationLow,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
          height: 1.3,
        ),
        titleSpacing: spacingMedium,
        toolbarHeight: 64, // Increased height for better proportions
        centerTitle: false,
      ),

      // Enhanced Card theme with better shadows
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: elevationMedium, // Increased from elevationLow
        shadowColor: shadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
          side: BorderSide(color: borderLightColor, width: 1), // Added subtle border
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
      ),

      // Enhanced Button themes with modern styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: borderColor,
          disabledForegroundColor: mutedTextColor,
          elevation: elevationLow,
          shadowColor: shadowColor,
          minimumSize: const Size.fromHeight(52), // Slightly larger for better touch
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusLarge),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: borderColor,
          disabledForegroundColor: mutedTextColor,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusLarge),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          disabledForegroundColor: mutedTextColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingMedium,
            vertical: spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          disabledForegroundColor: mutedTextColor,
          side: const BorderSide(color: borderColor, width: 1.5),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusLarge),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // Icon Button theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: secondaryTextColor,
          padding: const EdgeInsets.all(spacingSmall),
          minimumSize: const Size(44, 44), // Better touch target
          iconSize: iconLg,
        ),
      ),

      // Floating Action Button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: elevationMedium,
        focusElevation: elevationHigh,
        hoverElevation: elevationMedium,
        highlightElevation: elevationHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusXl)),
        ),
      ),

      // Enhanced Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
          borderSide: const BorderSide(color: borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
          borderSide: const BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
          borderSide: const BorderSide(color: borderLightColor),
        ),
        fillColor: surfaceColor,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMd,
        ),
        hintStyle: const TextStyle(
          color: mutedTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: secondaryTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        errorStyle: const TextStyle(
          color: errorColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        helperStyle: const TextStyle(
          color: secondaryTextColor,
          fontSize: 12,
        ),
      ),

      // Enhanced Bottom navigation theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: mutedTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: elevationMedium,
        selectedIconTheme: IconThemeData(size: iconLg),
        unselectedIconTheme: IconThemeData(size: iconLg),
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),

      // Tab Bar theme
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: secondaryTextColor,
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Chip theme
      chipTheme: const ChipThemeData(
        backgroundColor: borderLightColor,
        selectedColor: primaryLightColor,
        disabledColor: borderLightColor,
        deleteIconColor: secondaryTextColor,
        labelStyle: TextStyle(
          color: primaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: spacingMd,
          vertical: spacingSmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusFull)),
        ),
      ),

      // Dialog theme
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: elevationVeryHigh,
        shadowColor: shadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius2xl)),
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
          height: 1.3,
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: secondaryTextColor,
          height: 1.5,
        ),
      ),

      // Drawer theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: surfaceColor,
        elevation: elevationVeryHigh,
        shadowColor: shadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(borderRadiusXl),
            bottomRight: Radius.circular(borderRadiusXl),
          ),
        ),
      ),

      // Snackbar theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: primaryTextColor,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusLarge)),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevationMedium,
      ),

      // List Tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
        minVerticalPadding: spacingSmall,
        iconColor: secondaryTextColor,
        textColor: primaryTextColor,
        tileColor: Colors.transparent,
        selectedTileColor: primaryLightColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusMedium)),
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: spacingMedium,
      ),
    );
  }

  // Helper methods for gradients and advanced styling
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryDarkColor],
  );

  static LinearGradient get secondaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryColor, secondaryDarkColor],
  );

  static BoxShadow get cardShadow => BoxShadow(
    color: shadowColor,
    offset: const Offset(0, 4), // Increased from 2
    blurRadius: 12, // Increased from 8
    spreadRadius: 0,
  );

  static BoxShadow get buttonShadow => BoxShadow(
    color: shadowLightColor,
    offset: const Offset(0, 1),
    blurRadius: 3,
    spreadRadius: 0,
  );

  // Backward compatibility aliases for existing code
  static const Color primaryAccentColor = borderDarkColor; // Temporary compatibility
  static const Color primaryButtonColor = primaryColor; // Temporary compatibility
}