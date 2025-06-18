import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color primaryLight = Color(0xFF0A84FF);
  static const Color secondaryLight = Color(0xFF5856D6);
  static const Color accentLight = Color(0xFF30D158);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLight = Color(0xFFF1F1F1);
  static const Color onSurfaceLight = Color(0xFF000000);
  static const Color errorLight = Color(0xFFFF3B30);

  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF0A84FF);
  static const Color secondaryDark = Color(0xFF5856D6);
  static const Color accentDark = Color(0xFF30D158);
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF000000);
  static const Color surfaceContainerDark = Color(0xFF181818);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color errorDark = Color(0xFFFF453A);

  // Common Colors
  static const Color success = Color(0xFF34C759);
  static const Color info = Color(0xFF5AC8FA);
  static const Color warning = Color(0xFFFFCC00);

  // Get ColorScheme
  static ColorScheme lightColorScheme = ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: primaryLight,
    primary: primaryLight,
    secondary: secondaryLight,
    tertiary: accentLight,
    surface: surfaceLight,
    onSurface: onSurfaceLight,
    inverseSurface: onSurfaceDark,
    surfaceContainer: surfaceContainerLight,
    background: backgroundLight,
    error: errorLight,
    surfaceTint: Colors.transparent,
  );

  static ColorScheme darkColorScheme = ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: primaryDark,
    primary: primaryDark,
    secondary: secondaryDark,
    tertiary: accentDark,
    surface: surfaceDark,
    onSurface: onSurfaceDark,
    inverseSurface: onSurfaceLight,
    surfaceContainer: surfaceContainerDark,
    background: backgroundDark,
    error: errorDark,
    surfaceTint: Colors.transparent,
  );
}