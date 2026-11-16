// lib/core/theme/app_theme.dart
//
// Central Material 3 theme for MotoCare Log.
// Every screen should read colours/styles from Theme.of(context),
// never hardcode them. Changing the seed colour here re-skins the whole app.

import 'package:flutter/material.dart';

/// A small holder for spacing values, so screens never use magic numbers
/// like `SizedBox(height: 16)` — they use `AppSpacing.md` instead.
/// If you later decide 16 is too much, you change it in one place.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// The single source of truth for visual style.
class AppTheme {
  AppTheme._();

  /// Seed colour. Material 3 derives the whole palette (primary, surface,
  /// container colours, etc.) from one hex value. A strong blue reads as
  /// "tool / utility / motorcycle dashboard" and passes contrast checks
  /// in both light and dark modes.
  static const Color seed = Color(0xFF1E5AA8);

  // -----------------------------------------------------------------
  // Light theme
  // -----------------------------------------------------------------
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  // -----------------------------------------------------------------
  // Dark theme
  // -----------------------------------------------------------------
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  // -----------------------------------------------------------------
  // Shared pieces used by BOTH light and dark.
  // This is the "template" that both themes call. If you want to change
  // how every button looks, change it here — once.
  // -----------------------------------------------------------------
  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,

      // AppBar: flat (no shadow), transparent background so it blends
      // with the page, centred title in most Material 3 samples.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
      ),

      // ---- Text fields ----
      // OutlineBorder by default, filled for readability, rounded corners.
      // `errorMaxLines: 2` gives validator messages room to wrap on phones.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        errorMaxLines: 2,
      ),

      // ---- Buttons ----
      // FilledButton = primary action ("Log in", "Save"). Consistent height
      // across the whole app avoids "buttons of different sizes" mistakes.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // TextButton = secondary actions ("Register instead", "Forgot?").
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // OutlinedButton = tertiary actions ("Archive", "Cancel").
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ---- Cards ----
      // Used on "My motorcycles" later. Subtle elevation, rounded corners.
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      // ---- Snack bars ----
      // `behavior: floating` lifts the snack bar slightly off the bottom;
      // nicer than the default flush-to-bottom look on phones.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ---- Text scale ----
      // Material 3 default `bodyMedium` is a good base; we only tune headers.
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(fontSize: 15),
      ),

      // ---- Focus ----
      // A visible focus outline helps keyboard users (accessibility) and
      // screen-reader users. It also happens to be visible in screenshots
      // for your documentation.
      focusColor: scheme.primary.withValues(alpha: 0.24),
    );
  }
}