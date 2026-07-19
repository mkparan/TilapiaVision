import 'dart:io';

import '../../data/models/detection_result.dart';

/// Strategy interface for running disease detection on a captured
/// image.
///
/// [TFLiteDetectionEngine] is the active, real implementation — wired
/// up by default in `main.dart`. [SimulatedDetectionEngine] exists
/// purely for the automated test suite. No screen or provider outside
/// this folder should ever need to know which implementation is
/// active.
abstract class IDetectionEngine {
  /// Loads model weights / prepares the engine. Called lazily on
  /// first use if not already ready.
  Future<void> initialize();

  bool get isReady;

  /// Runs inference on [image] for the given [farmProfile] and
  /// returns a result. Callers are expected to wrap this in
  /// `.timeout(DetectionConfig.inferenceTimeout)`.
  Future<DetectionResult> analyze(File image, {required String farmProfile});
}
