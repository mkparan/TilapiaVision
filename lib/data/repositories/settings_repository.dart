import 'package:shared_preferences/shared_preferences.dart';

/// Persists the two tunable thresholds — and the dark mode preference
/// — so a value changed in Settings survives an app restart, not just
/// the current session.
class SettingsRepository {
  static const _kOperating = 'operating_threshold';
  static const _kVerifier = 'verifier_threshold';
  static const _kDarkMode = 'dark_mode_enabled';

  /// Preconfigured high to avoid false positives from random objects
  /// or misframed captures — the verifier's own accuracy is still
  /// being improved, so the gate is deliberately strict for now.
  static const defaultVerifierThreshold = 0.85;
  static const defaultOperatingThreshold = 0.60; //60 as per calibrated
  static const defaultDarkMode = false;

  Future<double> getOperatingThreshold() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_kOperating) ?? defaultOperatingThreshold;
  }

  Future<void> setOperatingThreshold(double v) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kOperating, v);
  }

  Future<double> getVerifierThreshold() async {
    final p = await SharedPreferences.getInstance();
    return p.getDouble(_kVerifier) ?? defaultVerifierThreshold;
  }

  Future<void> setVerifierThreshold(double v) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kVerifier, v);
  }

  Future<bool> getDarkMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kDarkMode) ?? defaultDarkMode;
  }

  Future<void> setDarkMode(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDarkMode, enabled);
  }
}
