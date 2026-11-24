import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color seedColor = Color(0xFF2D9CDB);

  static ThemeData get light {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF087FB8),
          surface: const Color(0xFFFFFFFF),
          surfaceContainer: const Color(0xFFF0F5FA),
          surfaceContainerHigh: const Color(0xFFE4ECF4),
          outline: const Color(0xFFC3D0DD),
          error: const Color(0xFFBA1A1A),
          errorContainer: const Color(0xFFFFDAD6),
        );

    return _baseTheme(scheme);
  }

  static ThemeData get dark {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF67D5FF),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF80D8FF),
          surface: const Color(0xFF1C2940),
          surfaceContainer: const Color(0xFF18253A),
          surfaceContainerHigh: const Color(0xFF24334A),
          outline: const Color(0xFF3A4B65),
          error: const Color(0xFFFF8A9B),
          errorContainer: const Color(0xFF2A1D29),
        );

    return _baseTheme(scheme);
  }

  static ThemeData _baseTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.brightness == Brightness.dark
          ? const Color(0xFF08111F)
          : const Color(0xFFF4F8FC),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.25),
        selectionHandleColor: scheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
