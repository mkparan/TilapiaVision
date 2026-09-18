import 'package:flutter/foundation.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/verification/tflite_tilapia_verifier.dart';

/// Loads persisted thresholds (and the dark mode preference) at boot
/// and applies them — thresholds to [DetectionConfig] /
/// [TFLiteTilapiaVerifier], dark mode to [AppColors.isDark] — and
/// saves any change from the Settings screen immediately, so nothing
/// here is left to only live in memory.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository();

  final SettingsRepository _repository;

  double operatingThreshold = SettingsRepository.defaultOperatingThreshold;
  double verifierThreshold = SettingsRepository.defaultVerifierThreshold;
  bool darkModeEnabled = SettingsRepository.defaultDarkMode;
  bool loading = true;

  Future<void> load() async {
    operatingThreshold = await _repository.getOperatingThreshold();
    verifierThreshold = await _repository.getVerifierThreshold();
    darkModeEnabled = await _repository.getDarkMode();
    _apply();
    loading = false;
    notifyListeners();
  }

  Future<void> setOperatingThreshold(double v) async {
    operatingThreshold = v;
    _apply();
    notifyListeners();
    await _repository.setOperatingThreshold(v);
  }

  Future<void> setVerifierThreshold(double v) async {
    verifierThreshold = v;
    _apply();
    notifyListeners();
    await _repository.setVerifierThreshold(v);
  }

  Future<void> setDarkMode(bool enabled) async {
    darkModeEnabled = enabled;
    _apply();
    notifyListeners();
    await _repository.setDarkMode(enabled);
  }

  void _apply() {
    DetectionConfig.operatingThreshold = operatingThreshold;
    TFLiteTilapiaVerifier.threshold = verifierThreshold;
    AppColors.isDark = darkModeEnabled;
  }
}
