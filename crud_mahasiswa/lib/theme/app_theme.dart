import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF7F4EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF14532D);
  static const Color primaryDark = Color(0xFF0B3B20);
  static const Color gold = Color(0xFF9A6A1C);
  static const Color text = Color(0xFF1C2A22);
  static const Color muted = Color(0xFF5B6B61);
  static const Color border = Color(0xFFE3DED1);
  static const Color danger = Color(0xFFB3261E);
  static const Color softGreen = Color(0xFFE8F0E8);
}

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.gold,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        error: AppColors.danger,
        outline: AppColors.border,
        surfaceContainerHighest: AppColors.softGreen,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        color: AppColors.text,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
      titleLarge: TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: AppColors.text,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: AppColors.text, fontSize: 15, height: 1.45),
      bodyMedium: TextStyle(color: AppColors.text, fontSize: 14, height: 1.45),
      bodySmall: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.primaryDark,
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titleTextStyle: const TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}
