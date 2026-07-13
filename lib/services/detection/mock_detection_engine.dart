import 'dart:io';
import 'dart:math';

import '../../core/constants.dart';
import '../../data/models/detection_result.dart';
import 'i_detection_engine.dart';

/// Which outcome [MockDetectionEngine] should deterministically
/// produce. Use the forced modes in widget tests to exercise every
/// branch of the Result screen without needing a trained model.
enum MockMode { forcePositive, forceLowMatch, forceClear, forceTimeout, random }

/// Fake implementation used for all app development while YOLO11n is
/// still training. Returns a plausible fake result after an
/// artificial delay that roughly matches the real latency budget, so
/// loading states feel representative during development.
class MockDetectionEngine implements IDetectionEngine {
  MockDetectionEngine({this.mode = MockMode.forcePositive});

  /// Which canned outcome to return. Defaults to a Presumptive
  /// Positive so the happy path is easy to demo out of the box.
  final MockMode mode;

  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ready = true;
  }

  @override
  Future<DetectionResult> analyze(File image, {required String farmProfile}) async {
    await Future.delayed(const Duration(milliseconds: 1600));

    if (mode == MockMode.forceTimeout) {
      // Deliberately outlast DetectionConfig.inferenceTimeout so
      // callers wrapping this in `.timeout(...)` can verify their
      // timeout-handling UI actually fires.
      await Future.delayed(DetectionConfig.inferenceTimeout + const Duration(seconds: 2));
    }

    final confidence = _confidenceFor(mode);
    final label = _labelFor(confidence);

    return DetectionResult(
      farmProfile: farmProfile,
      timestamp: DateTime.now(),
      diseaseClass: label == DetectionLabel.clear ? 'none' : 'hemorrhagic_ulcer',
      confidenceScore: confidence,
      imagePath: image.path,
      label: label,
      boundingBox: label == DetectionLabel.clear
          ? null
          : const BoundingBox(left: 0.32, top: 0.30, width: 0.34, height: 0.26),
    );
  }

  double _confidenceFor(MockMode mode) {
    final rand = Random();
    switch (mode) {
      case MockMode.forcePositive:
        return 0.82 + rand.nextDouble() * 0.15;
      case MockMode.forceLowMatch:
        final span = DetectionConfig.operatingThreshold - DetectionConfig.confidenceFloor;
        final safeSpan = span > 0.02 ? span - 0.02 : span;
        return DetectionConfig.confidenceFloor + rand.nextDouble() * safeSpan;
      case MockMode.forceClear:
        return 0.0;
      case MockMode.forceTimeout:
        return 0.0;
      case MockMode.random:
        return rand.nextDouble();
    }
  }

  DetectionLabel _labelFor(double confidence) {
    if (confidence <= 0) return DetectionLabel.clear;
    if (confidence >= DetectionConfig.operatingThreshold) return DetectionLabel.presumptivePositive;
    if (confidence >= DetectionConfig.confidenceFloor) return DetectionLabel.lowMatch;
    return DetectionLabel.clear;
  }
}
