import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ocean Gradient palette — kept consistent with the project's
/// concept deck and UI/UX prototype, so the shipped app matches what
/// panelists have already reviewed.
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
  static const slateLight = Color(0xFFEEF2F6);
  static const border = Color(0xFFE7ECF1);
  static const appBackground = Color(0xFFFAFCFD);
  static const ink = Color(0xFF17203A);
}

class AppTheme {
  AppTheme._();

  /// Soft, low-opacity shadow used everywhere instead of hard
  /// borders — the "clean" look leans on elevation, not outlines.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(color: AppColors.navy.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 6)),
      ];

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);
    final bodyTextTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.navy,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.appBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepBlue,
        primary: AppColors.deepBlue,
        secondary: AppColors.teal,
        surface: Colors.white,
      ),
      textTheme: bodyTextTheme.copyWith(
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.navy,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCBD5E1),
          disabledForegroundColor: const Color(0xFFF1F5F9),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepBlue,
          side: const BorderSide(color: AppColors.border, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.appBackground,
        foregroundColor: AppColors.navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.navy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: AppColors.deepBlue, width: 1.6),
        ),
      ),
      dividerColor: AppColors.border,
    );
  }
}
