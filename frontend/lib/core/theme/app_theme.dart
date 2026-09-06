import 'package:flutter/material.dart';

/// Dashboard palette — dark navy theme with mint-green accent.
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF0D1117);
  static const Color bgElevated = Color(0xFF161B22);
  static const Color card = Color(0xFF1F242D);
  static const Color cardAlt = Color(0xFF252A34);
  static const Color border = Color(0xFF2E3644);
  static const Color accent = Color(0xFF50FA7B);
  static const Color accentDim = Color(0xFF57C785);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color warning = Color(0xFFE3B341);
  static const Color danger = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);
  static const Color track = Color(0xFF2C333D);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      primary: AppColors.accent,
      surface: AppColors.card,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textSecondary),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
  );
}
