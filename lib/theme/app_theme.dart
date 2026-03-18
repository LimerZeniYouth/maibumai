import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF6C8EFF);
  static const _lightBackground = Color(0xFFF5F7FB);
  static const _darkBackground = Color(0xFF0B1020);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: Colors.white,
    );

    return _baseTheme(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF11182A),
    );

    return _baseTheme(scheme, Brightness.dark);
  }

  static ThemeData _baseTheme(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final theme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.dark ? _darkBackground : _lightBackground,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: scheme.primary,
        scaffoldBackgroundColor: brightness == Brightness.dark ? _darkBackground : _lightBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.45)),
        labelStyle: TextStyle(color: scheme.onSurface.withOpacity(0.72)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: scheme.primary.withOpacity(0.25), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: themeChip(scheme, isDark),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surface,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textTheme: Typography.blackMountainView.copyWith(
        displaySmall: const TextStyle(fontWeight: FontWeight.w700),
        headlineMedium: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        headlineSmall: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleLarge: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(height: 1.35),
      ),
    );

    return theme;
  }

  static ChipThemeData themeChip(ColorScheme scheme, bool isDark) {
    return ChipThemeData(
      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      selectedColor: scheme.primary.withValues(alpha: 0.14),
      side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}
