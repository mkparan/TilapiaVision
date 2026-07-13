import 'dart:io';

import '../../data/models/detection_result.dart';
import 'i_detection_engine.dart';

/// Real, on-device implementation — wire this up once
/// `best_int8.tflite` exists (Sprint 5). Until then this throws so
/// it's obvious immediately if something accidentally tries to use it
/// before it's ready, rather than failing silently.
///
/// Integration checklist (see the App Development Masterplan):
///   1. Place the exported model at `assets/models/best_int8.tflite`
///      (it's already registered as an asset directory in pubspec.yaml).
///   2. Load it with `tflite_flutter`'s `Interpreter.fromAsset(...)`
///      inside [initialize].
///   3. In [analyze]: decode the image, resize/normalize to the
///      model's expected input tensor shape, run the interpreter,
///      then apply the confidence floor -> NMS -> operating threshold
///      pipeline exactly as described in Fig. 3-5 of the proposal.
///   4. Update [DetectionConfig.operatingThreshold] with the Sprint 5
///      calibrated value.
///   5. In `main.dart`, swap the provider binding from
///      `MockDetectionEngine()` to `TFLiteDetectionEngine()`.
///      Screens do not need to change — that's the whole point of
///      going through [IDetectionEngine].
///   6. Re-run the widget test suite. If it still passes without
///      modification, the abstraction boundary held.
class TFLiteDetectionEngine implements IDetectionEngine {
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    // TODO(sprint-5): final interpreter = await Interpreter.fromAsset(
    //   'models/best_int8.tflite',
    // );
    throw UnimplementedError(
      'TFLiteDetectionEngine.initialize() is not wired up yet. '
      'See this class\'s doc comment for the integration checklist.',
    );
  }

  @override
  Future<DetectionResult> analyze(File image, {required String farmProfile}) {
    throw UnimplementedError(
      'TFLiteDetectionEngine.analyze() is not wired up yet. '
      'See this class\'s doc comment for the integration checklist.',
    );
  }
}
