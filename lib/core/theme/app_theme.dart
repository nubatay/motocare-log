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

  static const Color primaryBlue = Color(0xFF5A82F0);
  static const Color lightBg = Color(0xFFF6F5F0);
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);

  static ThemeData get light {
    return _buildTheme(isDark: false);
  }

  static ThemeData get dark {
    return _buildTheme(isDark: true);
  }

  static ThemeData _buildTheme({required bool isDark}) {
    // 1. Setup the color scheme
    final colorScheme = isDark 
        ? const ColorScheme.dark(
            primary: primaryBlue,
            surface: darkSurface,
            onSurface: Color(0xFFF5F5F5),
            error: Color(0xFFE57373),
          )
        : const ColorScheme.light(
            primary: primaryBlue,
            surface: Colors.white,
            onSurface: Color(0xFF1A1A1A),
            error: Color(0xFFD32F2F),
          );

    // 2. Force text color based on theme
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

        // 3. Create the TextTheme explicitly (avoids the copyWith bug)
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: textColor),
      displayMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: textColor),
      displaySmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: textColor),
      
      headlineLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: textColor),
      headlineMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: textColor),
      headlineSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: textColor),
      
      titleLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: textColor, fontSize: 22), // For AppBars & Card Headers
      titleMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, color: textColor),
      titleSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: textColor),
      
      bodyLarge: GoogleFonts.inter(color: textColor, fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: textColor, fontSize: 14),
      bodySmall: GoogleFonts.inter(color: textColor.withValues(alpha: 0.7), fontSize: 12),
      
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textColor), // For Buttons
    );

    // 4. Build the entire ThemeData from scratch (avoids the copyWith bug)
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? darkBg : lightBg,
      colorScheme: colorScheme,
      textTheme: textTheme,
      
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkBg : lightBg,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontSize: 22),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(), 
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          foregroundColor: textColor, 
          side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)), 
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
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
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),

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