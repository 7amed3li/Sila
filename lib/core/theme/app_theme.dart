import 'package:flutter/material.dart';
import 'package:sila_app/core/theme/app_fonts.dart';

class AppTheme {
  // Premium Palette
  static const Color primaryColor = Color(0xFF064E3B); // Emerald Deep
  static const Color accentColor = Color(0xFFD97706); // Islamic Gold
  static const Color backgroundColor = Color(0xFFFDFBF7); // Parchment
  static const Color surfaceColor =
      Color(0xFFF9F5EC); // Soft Parchment (Legacy/Design System match)
  static const Color darkBackgroundColor = Color(0xFF0F172A); // Night Deep
  static const Color goldLight = Color(0xFFFCD34D); // Gold Light
  static const Color navyHasanat = Color(0xFF1E3A5F); // Navy Hasanat
  static const Color successGreen = Color(0xFF10B981); // Success Green
  static const Color darkSurfaceColor = Color(0xFF1E293B); // Dark Surface

  // Gradients
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF064E3B), Color(0xFF0A6B52), Color(0xFF1A3A5C)],
  );

  static const LinearGradient hasanatGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyHasanat, Color(0xFF2D5A8E)],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, Color(0xFFF59E0B)],
  );

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme:
          AppFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: AppFonts.outfit(
            fontWeight: FontWeight.bold, color: primaryColor),
        titleLarge: AppFonts.outfit(
            fontWeight: FontWeight.w600, color: primaryColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: const Color(
            0xFF10B981), // Minted Emerald for better visibility in dark
        secondary: const Color(0xFFF59E0B), // Glowing Saffron
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      textTheme: AppFonts.outfitTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }
}
