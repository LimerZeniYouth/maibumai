import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF3478FF);
  static const _lightBackground = Color(0xFFF4F7FB);
  static const _darkBackground = Color(0xFF0B1120);

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
      surface: const Color(0xFF121A2C),
    );

    return _baseTheme(scheme, Brightness.dark);
  }

  static ThemeData _baseTheme(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseTextTheme =
        isDark ? Typography.whiteMountainView : Typography.blackMountainView;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? _darkBackground : _lightBackground,
      canvasColor: isDark ? _darkBackground : _lightBackground,
      dividerColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFD9E2F0),
      hintColor: isDark
          ? Colors.white.withValues(alpha: 0.64)
          : const Color(0xFF6B7280),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: scheme.primary,
        scaffoldBackgroundColor: isDark ? _darkBackground : _lightBackground,
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
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.42)),
        labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.24),
            width: 1.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : const Color(0xFFD8E0ED),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: _chipTheme(scheme, isDark),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF162035) : Colors.white,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displaySmall: const TextStyle(fontWeight: FontWeight.w700),
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        headlineSmall: const TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        titleLarge: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: const TextStyle(fontWeight: FontWeight.w700),
        bodyLarge: const TextStyle(height: 1.35),
        bodyMedium: const TextStyle(height: 1.3),
      ),
    );
  }

  static ChipThemeData _chipTheme(ColorScheme scheme, bool isDark) {
    return ChipThemeData(
      backgroundColor:
          isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      selectedColor: scheme.primary.withValues(alpha: 0.14),
      side: BorderSide(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}
