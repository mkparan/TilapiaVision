import 'package:flutter/material.dart';

/// Ocean Gradient palette — kept consistent with the project's
/// concept deck and high-fidelity UI/UX prototype, so the shipped
/// app matches what's already been reviewed.
///
/// Most fields below are getters rather than `static const` values:
/// they resolve to a light or dark shade depending on [AppColors.isDark],
/// which [SettingsProvider] keeps in sync with the persisted "Dark
/// mode" toggle in Settings. Call sites don't need to know which mode
/// is active — they just read `AppColors.ink`, `AppColors.surface`,
/// etc., and get the right shade for the current theme.
///
/// A handful of brand-accent colors (deepBlue, teal, mint, amber and
/// their "Dark" variants) stay identical in both themes — they're
/// already saturated enough to read well on both a light and a dark
/// background, and keeping them fixed preserves the brand identity.
class AppColors {
  AppColors._();

  /// Flipped by [SettingsProvider] whenever the user toggles dark
  /// mode. Widgets don't need to read this directly — they just use
  /// the color getters below, and the app forces a full rebuild after
  /// this flips (see `_RootRouter` in main.dart) so every screen
  /// re-resolves its colors.
  static bool isDark = false;

  // ---- Brand accents (identical across themes) ----
  static const deepBlue = Color(0xFF065A82);
  static const teal = Color(0xFF1C7293);
  static const mint = Color(0xFF02C39A);
  static const mintDark = Color(0xFF019078);
  static const amber = Color(0xFFF4A300);
  static const amberDark = Color(0xFFB97600);

  /// Fixed brand navy — used for decorative solid fills (e.g. the
  /// onboarding disclaimer screen background, the shutter-button
  /// spinner) that are deliberately dark in both themes. For navy
  /// used as *heading text*, use [heading] instead, since that needs
  /// to invert to a light color on a dark background.
  static const navy = Color(0xFF21295C);

  // ---- Theme-reactive roles ----
  static Color get heading =>
      isDark ? const Color(0xFFEAF1FB) : const Color(0xFF21295C);
  static Color get ink =>
      isDark ? const Color(0xFFE4E9F2) : const Color(0xFF16233D);
  static Color get slate =>
      isDark ? const Color(0xFF93A0B4) : const Color(0xFF64748B);
  static Color get slateLight =>
      isDark ? const Color(0xFF2A3446) : const Color(0xFFE2E8F0);
  static Color get ice =>
      isDark ? const Color(0xFF17324A) : const Color(0xFFEAF4F8);
  static Color get appBackground =>
      isDark ? const Color(0xFF0B1420) : const Color(0xFFF4F9FB);
  static Color get border =>
      isDark ? const Color(0xFF243044) : const Color(0xFFE2E8F0);

  /// Card / sheet / text-field fill color. `Colors.white` in light
  /// mode, a dark elevated surface in dark mode.
  static Color get surface => isDark ? const Color(0xFF141E2E) : Colors.white;
}

class AppTheme {
  AppTheme._();

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.isDark
              ? const Color(0x55000000)
              : const Color(0x14101E3C),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static ThemeData get light => _themeFor(Brightness.light);
  static ThemeData get dark => _themeFor(Brightness.dark);

  static ThemeData _themeFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background =
        isDark ? const Color(0xFF0B1420) : AppColors.appBackground;
    final ink = isDark ? const Color(0xFFE4E9F2) : const Color(0xFF16233D);
    final heading =
        isDark ? const Color(0xFFEAF1FB) : const Color(0xFF21295C);
    final surface = isDark ? const Color(0xFF141E2E) : Colors.white;
    final border = isDark ? const Color(0xFF243044) : const Color(0xFFE2E8F0);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepBlue,
        brightness: brightness,
        primary: AppColors.deepBlue,
        secondary: AppColors.teal,
        surface: surface,
      ),
      textTheme: (isDark ? ThemeData.dark() : ThemeData.light()).textTheme.apply(
            bodyColor: ink,
            displayColor: heading,
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark
              ? const Color(0xFF2E3A4E)
              : const Color(0xFFB9C6D6),
          disabledForegroundColor: isDark
              ? const Color(0xFF6B7A90)
              : const Color(0xFFEDF2F6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: heading,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: heading,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.deepBlue
                : (isDark ? const Color(0xFF8A97AA) : Colors.white)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.deepBlue.withValues(alpha: 0.5)
                : border),
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
