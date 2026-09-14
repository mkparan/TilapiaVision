import 'package:shared_preferences/shared_preferences.dart';

/// Persists the two tunable thresholds so a value changed in Settings
/// survives an app restart, not just the current session.
class SettingsRepository {
  static const _kOperating = 'operating_threshold';
  static const _kVerifier = 'verifier_threshold';

  /// Preconfigured high to avoid false positives from random objects
  /// or misframed captures — the verifier's own accuracy is still
  /// being improved, so the gate is deliberately strict for now.
  static const defaultVerifierThreshold = 0.85;
  static const defaultOperatingThreshold = 0.70;

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
}
