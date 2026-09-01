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
  MockDetectionEngine({this.mode = MockMode.random});

  /// Which canned outcome to return. Defaults to [MockMode.random] so
  /// day-to-day manual testing sees every screen state — Presumptive
  /// Positive, Low Match, No Lesions Detected, and the hardware
  /// timeout screen — with roughly equal likelihood on repeated
  /// captures, rather than always landing on the same one. Pass an
  /// explicit forced mode (e.g. in widget tests) to pin a specific
  /// outcome deterministically.
  final MockMode mode;

  bool _ready = false;
  final _random = Random();

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

    // Resolve `random` to one of the four concrete outcomes with
    // equal (25%) probability each, chosen ONCE up front. This is
    // deliberately NOT "pick a uniformly random confidence value" —
    // that skews heavily toward whichever confidence range happens
    // to be widest (Clear's range from 0 up to the confidence floor
    // dwarfs Low Match's narrow band between the floor and the
    // operating threshold) and can never produce a
    // timeout at all, since timeout isn't confidence-driven. Picking
    // the outcome bucket first, then generating a representative
    // confidence for that bucket, is what actually balances the
    // screens you see across repeated test captures.
    final effectiveMode = mode == MockMode.random ? _pickRandomMode() : mode;

    if (effectiveMode == MockMode.forceTimeout) {
      // Deliberately outlast DetectionConfig.inferenceTimeout so
      // callers wrapping this in `.timeout(...)` can verify their
      // timeout-handling UI actually fires. DetectionProvider's own
      // `.timeout()` call resolves first and moves the UI to
      // ScanStatus.timeout — nothing awaits this Future's eventual
      // (unused) return value after that.
      await Future.delayed(DetectionConfig.inferenceTimeout + const Duration(seconds: 2));
    }

    final confidence = _confidenceFor(effectiveMode);
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

  /// Picks uniformly among the four concrete outcomes — this is the
  /// "balance" knob. Adjust the list (e.g. duplicate an entry) if you
  /// want to skew testing toward a particular screen temporarily.
  MockMode _pickRandomMode() {
    const outcomes = [
      MockMode.forcePositive,
      MockMode.forceLowMatch,
      MockMode.forceClear,
      MockMode.forceTimeout,
    ];
    return outcomes[_random.nextInt(outcomes.length)];
  }

  double _confidenceFor(MockMode mode) {
    switch (mode) {
      case MockMode.forcePositive:
        return 0.82 + _random.nextDouble() * 0.15;
      case MockMode.forceLowMatch:
        final span = DetectionConfig.operatingThreshold - DetectionConfig.confidenceFloor;
        final safeSpan = span > 0.02 ? span - 0.02 : span;
        return DetectionConfig.confidenceFloor + _random.nextDouble() * safeSpan;
      case MockMode.forceClear:
        return 0.0;
      case MockMode.forceTimeout:
        // Unused by the caller in practice (see analyze()'s comment
        // above) but kept well-formed rather than a fake sentinel.
        return 0.0;
      case MockMode.random:
        // Never actually reached — analyze() always resolves
        // `random` to a concrete mode via _pickRandomMode() before
        // calling this. Kept exhaustive for switch-completeness.
        return _random.nextDouble();
    }
  }

  DetectionLabel _labelFor(double confidence) {
    if (confidence <= 0) return DetectionLabel.clear;
    if (confidence >= DetectionConfig.operatingThreshold) return DetectionLabel.presumptivePositive;
    if (confidence >= DetectionConfig.confidenceFloor) return DetectionLabel.lowMatch;
    return DetectionLabel.clear;
  }
}
