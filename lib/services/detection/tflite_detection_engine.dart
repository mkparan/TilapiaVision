import 'dart:io';
import 'dart:math';


import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/constants.dart';
import '../../data/models/detection_result.dart';
import '../model_load_exceptions.dart';
import 'i_detection_engine.dart';

/// Real, on-device YOLO11n disease-detection engine backed by
/// `best_int8.tflite`.
///
/// Model tensor contract (verified against the exported model):
///   INPUT  [1, 3, 640, 640]  float32  — channels-first, pixels in [0, 1]
///   OUTPUT [1, 5, 8400]      float32  — rows: cx, cy, w, h, score
///
/// **Channels-first** is critical: most Flutter TFLite examples use
/// channels-last `[1, H, W, 3]`. Feeding pixels in the wrong order
/// produces silent garbage, not an error.
class TFLiteDetectionEngine implements IDetectionEngine {
  static const _modelAssetPath = 'assets/models/best_int8.tflite';
  static const _inputSize = 640;
  static const _numDetections = 8400;

  Interpreter? _interpreter;
  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<void> initialize() async {
    if (_ready) return;

    // Load via a real filesystem file rather than Interpreter.fromAsset.
    // fromAsset reads through Android's AssetManager, which can mmap the
    // .tflite incorrectly for some builds even with noCompress set,
    // producing a load that *looks* fine (correct tensor shapes read
    // from the header) but fails at invoke() with "Input tensor N lacks
    // data" — the payload for large tensors reads back short or wrong.
    // Copying to a plain file and using fromFile sidesteps that path
    // entirely; it is the most-tested loading path in tflite_flutter.
    final File modelFile;
    try {
      modelFile = await _materializeAsset(_modelAssetPath);
    } on ModelMissingException {
      rethrow;
    }

    final options = InterpreterOptions()..addDelegate(XNNPackDelegate());
    try {
      _interpreter = Interpreter.fromFile(modelFile, options: options);
    } catch (e) {
      throw ModelRunException('disease detector', '$e');
    }

    final inputShape = _interpreter!.getInputTensor(0).shape;
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    debugPrint('TFLiteDetectionEngine — input shape:  $inputShape');
    debugPrint('TFLiteDetectionEngine — output shape: $outputShape');

    _ready = true;
  }

  @override
  Future<DetectionResult> analyze(
    File image, {
    required String farmProfile,
  }) async {
    assert(_ready, 'Call initialize() before analyze()');

    final bytes = await image.readAsBytes();

    // Decode, resize, and lay out the channels-first float buffer on a
    // background isolate. A 12 MP phone photo takes long enough to
    // decode that doing this on the main thread visibly freezes the UI.
    final input = await compute(_prepareChannelsFirst, bytes);

    final output = Float32List(1 * 5 * _numDetections);
    try {
      _interpreter!.run(input.buffer, output.buffer);
    } catch (e) {
      throw ModelRunException('disease detector', '$e');
    }

    // 1. confidence floor -> 2. NMS -> 3. operating threshold
    final rawBoxes = <_RawDetection>[];
    for (int i = 0; i < _numDetections; i++) {
      final score = output[4 * _numDetections + i];
      if (score < DetectionConfig.confidenceFloor) continue;
      rawBoxes.add(_RawDetection(
        cx: output[0 * _numDetections + i],
        cy: output[1 * _numDetections + i],
        w: output[2 * _numDetections + i],
        h: output[3 * _numDetections + i],
        score: score,
      ));
    }
    rawBoxes.sort((a, b) => b.score.compareTo(a.score));
    final kept = _nms(rawBoxes, DetectionConfig.nmsIouThreshold);

    if (kept.isEmpty) {
      return DetectionResult(
        farmProfile: farmProfile,
        timestamp: DateTime.now(),
        diseaseClass: 'none',
        confidenceScore: 0.0,
        imagePath: image.path,
        label: DetectionLabel.clear,
        boundingBox: null,
      );
    }

    final best = kept.first;
    final confidence = best.score;
    final label = confidence >= DetectionConfig.operatingThreshold
        ? DetectionLabel.presumptivePositive
        : DetectionLabel.lowMatch;

    // Box coordinates come out already normalised to 0.0-1.0.
    final normLeft = (best.cx - best.w / 2).clamp(0.0, 1.0);
    final normTop = (best.cy - best.h / 2).clamp(0.0, 1.0);
    final normWidth = best.w.clamp(0.0, 1.0);
    final normHeight = best.h.clamp(0.0, 1.0);

    return DetectionResult(
      farmProfile: farmProfile,
      timestamp: DateTime.now(),
      diseaseClass: 'hemorrhagic_ulcer',
      confidenceScore: confidence,
      imagePath: image.path,
      label: label,
      boundingBox: BoundingBox(
        left: normLeft,
        top: normTop,
        width: normWidth,
        height: normHeight,
      ),
    );
  }

  List<_RawDetection> _nms(List<_RawDetection> boxes, double iouThreshold) {
    final kept = <_RawDetection>[];
    final suppressed = List.filled(boxes.length, false);
    for (int i = 0; i < boxes.length; i++) {
      if (suppressed[i]) continue;
      kept.add(boxes[i]);
      for (int j = i + 1; j < boxes.length; j++) {
        if (suppressed[j]) continue;
        if (_iou(boxes[i], boxes[j]) > iouThreshold) suppressed[j] = true;
      }
    }
    return kept;
  }

  double _iou(_RawDetection a, _RawDetection b) {
    final ax1 = a.cx - a.w / 2, ay1 = a.cy - a.h / 2;
    final ax2 = a.cx + a.w / 2, ay2 = a.cy + a.h / 2;
    final bx1 = b.cx - b.w / 2, by1 = b.cy - b.h / 2;
    final bx2 = b.cx + b.w / 2, by2 = b.cy + b.h / 2;
    final ix1 = max(ax1, bx1), iy1 = max(ay1, by1);
    final ix2 = min(ax2, bx2), iy2 = min(ay2, by2);
    final interW = max(0.0, ix2 - ix1), interH = max(0.0, iy2 - iy1);
    final intersection = interW * interH;
    final union = a.w * a.h + b.w * b.h - intersection;
    return union > 0 ? intersection / union : 0.0;
  }
}

/// Copies a Flutter asset to a real file in temporary storage the
/// first time it's needed, and reuses that file afterward. Throws
/// [ModelMissingException] if the asset isn't bundled at all.
Future<File> _materializeAsset(String assetPath) async {
  final tmp = await getTemporaryDirectory();
  final fileName = assetPath.split('/').last;
  final file = File('${tmp.path}/$fileName');

  ByteData data;
  try {
    data = await rootBundle.load(assetPath);
  } catch (_) {
    final name = fileName.contains('verifier') ? 'species verifier' : 'disease detector';
    throw ModelMissingException(assetPath, name);
  }

  // Re-copy if missing or a different size (e.g. the model was updated).
  if (!await file.exists() || (await file.length()) != data.lengthInBytes) {
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
  }
  return file;
}

/// Runs on a background isolate via [compute]. Decodes the photo,
/// resizes to 640x640, and lays out a channels-first [1,3,640,640]
/// float32 buffer normalised to 0.0-1.0.
Float32List _prepareChannelsFirst(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('Could not decode image');
  const n = TFLiteDetectionEngine._inputSize;
  final resized = img.copyResize(decoded, width: n, height: n);

  final input = Float32List(3 * n * n);
  var idx = 0;
  for (int y = 0; y < n; y++) {
    for (int x = 0; x < n; x++) {
      input[idx++] = resized.getPixel(x, y).r / 255.0;
    }
  }
  for (int y = 0; y < n; y++) {
    for (int x = 0; x < n; x++) {
      input[idx++] = resized.getPixel(x, y).g / 255.0;
    }
  }
  for (int y = 0; y < n; y++) {
    for (int x = 0; x < n; x++) {
      input[idx++] = resized.getPixel(x, y).b / 255.0;
    }
  }
  return input;
}

class _RawDetection {
  const _RawDetection({
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.score,
  });
  final double cx, cy, w, h, score;
}
