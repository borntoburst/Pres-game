import 'package:flutter/material.dart';

/// Centralized theme for the whole app.
/// Bright, rounded, kid-friendly palette.
class AppTheme {
  // Primary palette
  static const Color primaryYellow = Color(0xFFFFD93D);
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryBlue   = Color(0xFF4ECDC4);
  static const Color primaryPink   = Color(0xFFFF6B9D);
  static const Color primaryPurple = Color(0xFFA855F7);
  static const Color primaryGreen  = Color(0xFF6BCB77);
  static const Color bgColor       = Color(0xFFFFF9F0);
  static const Color cardBg        = Color(0xFFFFFFFF);
  static const Color textDark      = Color(0xFF2D2D2D);
  static const Color textLight     = Color(0xFF6B6B6B);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryYellow,
      background: bgColor,
    ),
    scaffoldBackgroundColor: bgColor,
    fontFamily: 'Nunito', // Fallback to system rounded font
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: textDark,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: textDark,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );

  // Game-specific accent colors
  static const List<Color> gameColors = [
    primaryOrange,
    primaryBlue,
    primaryPink,
    primaryPurple,
    primaryGreen,
    primaryYellow,
  ];
}
