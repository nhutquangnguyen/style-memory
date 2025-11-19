import 'package:flutter/material.dart';

class AppTheme {
  // Color palette - simplified and neutral
  static const Color backgroundColor = Colors.white;
  static const Color primaryTextColor = Color(0xFF1A1A1A); // Almost black
  static const Color secondaryTextColor = Color(0xFF757575); // Medium gray
  static const Color primaryAccentColor = Color(0xFF9E9E9E); // Soft gray
  static const Color primaryButtonColor = Color(0xFF424242); // Dark gray
  static const Color errorColor = Color(0xFFD32F2F); // Red
  static const Color borderColor = Color(0xFFE0E0E0); // Light border
  static const Color cardColor = Color(0xFFFAFAFA); // Very light gray

  // Spacing constants
  static const double spacingVerySmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingExtraLarge = 32.0;

  // Border radius
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.grey,
      scaffoldBackgroundColor: backgroundColor,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primaryButtonColor,
        secondary: primaryAccentColor,
        error: errorColor,
        background: backgroundColor,
        surface: cardColor,
        onPrimary: Colors.white,
        onSecondary: primaryTextColor,
        onError: Colors.white,
        onBackground: primaryTextColor,
        onSurface: primaryTextColor,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryTextColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primaryTextColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: primaryTextColor,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: secondaryTextColor,
        ),
      ),

      // App Bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
      ),

      // Card theme
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 1,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadiusMedium)),
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryButtonColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryButtonColor,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryButtonColor,
          side: const BorderSide(color: borderColor),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: primaryButtonColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        fillColor: backgroundColor,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
        hintStyle: const TextStyle(color: secondaryTextColor),
        labelStyle: const TextStyle(color: secondaryTextColor),
      ),

      // Bottom navigation theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryButtonColor,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      ),
    );
  }
}