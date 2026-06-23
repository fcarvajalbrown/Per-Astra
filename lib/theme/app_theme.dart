import 'package:flutter/material.dart';

/// Per Astra design tokens and theme (ADR-010).
///
/// Space / star aesthetic matching the "Per Astra" name. Dark mode only in v1;
/// light mode is an explicit non-goal (ADR-010). All colors are defined here as
/// constants — there is no token-file-driven theming system, so contributors
/// must reference these constants rather than hard-coding colors.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF6C63FF); // indigo-violet
  static const Color secondary = Color(0xFFFFD166); // gold (XP, stars)
  static const Color background = Color(0xFF0D0D1A); // deep space dark
  static const Color surface = Color(0xFF1A1A2E); // card background
  static const Color success = Color(0xFF06D6A0); // correct answer, pass
  static const Color error = Color(0xFFEF476F); // wrong answer
  static const Color text = Color(0xFFF0F0F5); // primary text on dark
}

/// Shared shape tokens.
class AppRadii {
  AppRadii._();

  /// Default corner radius used throughout the app (ADR-010).
  static const double defaultRadius = 12;
}

/// Builds the single dark [ThemeData] for the app.
///
/// Built on Material 3 as a baseline, overriding color, typography, and shape
/// without a third-party component library (ADR-010).
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
    error: AppColors.error,
    onPrimary: AppColors.text,
    onSurface: AppColors.text,
  );

  const radius = BorderRadius.all(Radius.circular(AppRadii.defaultRadius));

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    cardTheme: base.cardTheme.copyWith(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: radius),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.text,
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: radius),
    ),
  );
}

/// Monospace text style for the prompt-writing exercise input (ADR-010).
///
/// Uses the platform monospace family rather than a downloaded font (v1 ships
/// system fonts only).
const TextStyle kPromptInputTextStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: <String>['Menlo', 'Consolas', 'Roboto Mono', 'monospace'],
  color: AppColors.text,
  height: 1.4,
);
