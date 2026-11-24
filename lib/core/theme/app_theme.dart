import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppTheme {
  AppTheme._();

  // Custom Colors from the Style Guide
  static const Color primaryBlue = Color(0xFF5A82F0);
  static const Color lightBg = Color(0xFFF6F5F0);
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        surface: Colors.white,
        onSurface: Color(0xFF1A1A1A),
        error: Color(0xFFD32F2F),
      ),
    );
    return _buildTheme(base);
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        surface: darkSurface,
        onSurface: Color(0xFFF5F5F5),
        error: Color(0xFFE57373),
      ),
    );
    return _buildTheme(base);
  }

  static ThemeData _buildTheme(ThemeData base) {
    final isDark = base.brightness == Brightness.dark;

    // Typography: Space Grotesk for headers, Inter for body
    final textTheme = base.textTheme
      .apply(fontFamily: GoogleFonts.inter().fontFamily)
      .copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkBg : lightBg,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 22),
      ),
      
      // Pill-shaped buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(), // Fully rounded
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
        ),
      ),

      // Rounded Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: base.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: base.colorScheme.error, width: 2),
        ),
      ),

      // Rounded Cards
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        color: isDark ? darkSurface : Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}