import 'package:flutter/material.dart';

/// Ocean Gradient palette — kept consistent with the project's
/// concept deck and high-fidelity UI/UX prototype, so the shipped
/// app matches what's already been reviewed.
class AppColors {
  AppColors._();

  static const navy = Color(0xFF21295C);
  static const deepBlue = Color(0xFF065A82);
  static const teal = Color(0xFF1C7293);
  static const ice = Color(0xFFEAF4F8);
  static const mint = Color(0xFF02C39A);
  static const mintDark = Color(0xFF019078);
  static const amber = Color(0xFFF4A300);
  static const amberDark = Color(0xFFB97600);
  static const slate = Color(0xFF64748B);
  static const slateLight = Color(0xFFE2E8F0);
  static const appBackground = Color(0xFFF4F9FB);
  static const ink = Color(0xFF16233D);
  static const border = Color(0xFFE2E8F0);
}

class AppTheme {
  AppTheme._();

  static const cardShadow = [
    BoxShadow(color: Color(0x14101E3C), blurRadius: 10, offset: Offset(0, 2)),
  ];

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.appBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepBlue,
        primary: AppColors.deepBlue,
        secondary: AppColors.teal,
        surface: Colors.white,
      ),
      textTheme: ThemeData.light().textTheme.apply(
            bodyColor: AppColors.ink,
            displayColor: AppColors.navy,
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB9C6D6),
          disabledForegroundColor: const Color(0xFFEDF2F6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBackground,
        foregroundColor: AppColors.navy,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      // NOTE: checkboxTheme deliberately omitted — an earlier version
      // used CheckboxThemeData with WidgetStateProperty.resolveWith,
      // which isn't available on older Flutter versions. Checkboxes
      // instead set `activeColor: AppColors.deepBlue` explicitly per
      // widget (see disclaimer_gate_screen.dart and
      // farm_profile_setup_screen.dart) for broader compatibility.
    );
  }
}
