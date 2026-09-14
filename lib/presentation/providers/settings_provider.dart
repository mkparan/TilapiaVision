import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/verification/tflite_tilapia_verifier.dart';

/// Loads persisted thresholds at boot and applies them to
/// [DetectionConfig] / [TFLiteTilapiaVerifier], and saves any change
/// from the Settings screen immediately — nothing is left to only
/// live in memory, so a value survives closing the app.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository();

  final SettingsRepository _repository;

  double operatingThreshold = SettingsRepository.defaultOperatingThreshold;
  double verifierThreshold = SettingsRepository.defaultVerifierThreshold;
  bool loading = true;

  Future<void> load() async {
    operatingThreshold = await _repository.getOperatingThreshold();
    verifierThreshold = await _repository.getVerifierThreshold();
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

  void _apply() {
    DetectionConfig.operatingThreshold = operatingThreshold;
    TFLiteTilapiaVerifier.threshold = verifierThreshold;
  }
}
