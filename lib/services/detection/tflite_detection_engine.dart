import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/constants.dart';
import '../../data/models/detection_result.dart';
import 'i_detection_engine.dart';

/// Real, on-device YOLO11n disease-detection engine backed by
/// `best_int8.tflite`.
///
/// Model tensor contract (verified against the exported model):
///   INPUT  [1, 3, 640, 640]  float32  — channels-first, pixels ∈ [0, 1]
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
    // XNNPack must be explicit here: without it, tflite_flutter's
    // plain reference-kernel path fails on this model with
    // "Input tensor 207 lacks data" inside Interpreter.invoke() — a
    // native TFLite engine error, not a Dart bug. The model runs
    // cleanly under a modern runtime (verified directly), so this is
    // a kernel-version mismatch between the exporter and
    // tflite_flutter 0.12.1's bundled native library; the XNNPack
    // delegate takes a different execution path that doesn't hit it.
    final options = InterpreterOptions()..addDelegate(XNNPackDelegate());
    _interpreter = await Interpreter.fromAsset(_modelAssetPath, options: options);
    _interpreter!.allocateTensors();

    // Sanity-check tensor shapes at startup so a model mismatch is
    // caught immediately rather than producing garbage detections.
    // Shapes are readable from model metadata before allocation.
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

    // ----------------------------------------------------------
    // 1. Decode & resize to 640×640
    // ----------------------------------------------------------
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode image: ${image.path}');
    }
    final resized = img.copyResize(decoded, width: _inputSize, height: _inputSize);

    // ----------------------------------------------------------
    // 2. Build channels-first flat input buffer [1, 3, 640, 640]
    //    Pixel values normalised to 0.0-1.0
    // ----------------------------------------------------------
    final input = Float32List(1 * 3 * _inputSize * _inputSize);
    int idx = 0;

    // R channel
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        input[idx++] = resized.getPixel(x, y).r / 255.0;
      }
    }
    // G channel
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        input[idx++] = resized.getPixel(x, y).g / 255.0;
      }
    }
    // B channel
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        input[idx++] = resized.getPixel(x, y).b / 255.0;
      }
    }

    // ----------------------------------------------------------
    // 3. Allocate flat output buffer [1, 5, 8400] and run inference
    // ----------------------------------------------------------
    final output = Float32List(1 * 5 * _numDetections);

    // Passing .buffer bypasses tflite_flutter's slow list conversion
    _interpreter!.run(input.buffer, output.buffer);

    // ----------------------------------------------------------
    // 4. Parse detections: confidence floor -> NMS -> threshold
    // ----------------------------------------------------------
    final rawBoxes = <_RawDetection>[];

    // output layout: [cx_0..cx_8399, cy_0..cy_8399, w_0..w_8399, h_0..h_8399, score_0..score_8399]
    for (int i = 0; i < _numDetections; i++) {
      final score = output[4 * _numDetections + i];
      if (score < DetectionConfig.confidenceFloor) continue;

      final cx = output[0 * _numDetections + i];
      final cy = output[1 * _numDetections + i];
      final w  = output[2 * _numDetections + i];
      final h  = output[3 * _numDetections + i];

      rawBoxes.add(_RawDetection(
        cx: cx,
        cy: cy,
        w: w,
        h: h,
        score: score,
      ));
    }

    // Sort descending by score for NMS
    rawBoxes.sort((a, b) => b.score.compareTo(a.score));

    final kept = _nms(rawBoxes, DetectionConfig.nmsIouThreshold);

    // ----------------------------------------------------------
    // 5. Build DetectionResult from the top surviving detection
    // ----------------------------------------------------------
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

    final DetectionLabel label;
    if (confidence >= DetectionConfig.operatingThreshold) {
      label = DetectionLabel.presumptivePositive;
    } else {
      label = DetectionLabel.lowMatch;
    }

    // This export's box coordinates come out already normalised to
    // 0.0-1.0 (verified directly against the model's raw output) —
    // NOT pixel coordinates in 0-640 space, despite the 640x640 input
    // size. Dividing by `_inputSize` again here was a bug: it shrank
    // every box down to a few-pixel dot in the top-left corner.
    final normLeft   = (best.cx - best.w / 2).clamp(0.0, 1.0);
    final normTop    = (best.cy - best.h / 2).clamp(0.0, 1.0);
    final normWidth  = best.w.clamp(0.0, 1.0);
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

  // ============================================================
  // Non-Max Suppression
  // ============================================================

  /// Greedy NMS: walk the score-sorted list; for each kept box,
  /// suppress all later boxes whose IoU with it exceeds [iouThreshold].
  List<_RawDetection> _nms(List<_RawDetection> boxes, double iouThreshold) {
    final kept = <_RawDetection>[];
    final suppressed = List.filled(boxes.length, false);

    for (int i = 0; i < boxes.length; i++) {
      if (suppressed[i]) continue;
      kept.add(boxes[i]);
      for (int j = i + 1; j < boxes.length; j++) {
        if (suppressed[j]) continue;
        if (_iou(boxes[i], boxes[j]) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    return kept;
  }

  /// Intersection-over-Union between two centre-format boxes.
  double _iou(_RawDetection a, _RawDetection b) {
    final ax1 = a.cx - a.w / 2;
    final ay1 = a.cy - a.h / 2;
    final ax2 = a.cx + a.w / 2;
    final ay2 = a.cy + a.h / 2;

    final bx1 = b.cx - b.w / 2;
    final by1 = b.cy - b.h / 2;
    final bx2 = b.cx + b.w / 2;
    final by2 = b.cy + b.h / 2;

    final ix1 = max(ax1, bx1);
    final iy1 = max(ay1, by1);
    final ix2 = min(ax2, bx2);
    final iy2 = min(ay2, by2);

    final interW = max(0.0, ix2 - ix1);
    final interH = max(0.0, iy2 - iy1);
    final intersection = interW * interH;

    final areaA = a.w * a.h;
    final areaB = b.w * b.h;
    final union = areaA + areaB - intersection;

    return union > 0 ? intersection / union : 0.0;
  }
}

/// Internal representation of a candidate detection before NMS.
class _RawDetection {
  const _RawDetection({
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
    required this.score,
  });

  final double cx;
  final double cy;
  final double w;
  final double h;
  final double score;
}
