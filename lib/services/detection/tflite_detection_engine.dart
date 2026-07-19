import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/constants.dart';
import '../../data/models/detection_result.dart';
import 'i_detection_engine.dart';

/// Real, on-device YOLO11n inference via `tflite_flutter`.
///
/// **Setup:** drop your exported model at [_modelAssetPath] (already
/// registered as a Flutter asset directory in `pubspec.yaml`). This
/// is the active engine — `main.dart` wires it up by default.
///
/// **How this was written without the actual model file in hand:**
/// every `tflite_flutter` API call below was checked against the
/// package's official documentation before being used, not written
/// from memory. That covers the *mechanics* of loading a model and
/// running inference correctly. It does **not** cover your model's
/// *specific* export configuration, which no amount of documentation
/// reading can substitute for actually running against the real
/// file. Two things this implementation deliberately does NOT
/// hardcode, specifically so it adapts to your export automatically:
///
///  - **Input size and quantization** — read from
///    `interpreter.getInputTensor(0)` at load time, not assumed.
///  - **Output quantization** — read from
///    `interpreter.getOutputTensor(0)` the same way.
///
/// One thing this implementation DOES assume, because it can't be
/// introspected at runtime: a **single-class, raw (NMS-not-baked-in)
/// Ultralytics-style output** — a tensor with one dimension of size 5
/// (4 box values + 1 class confidence) and the other equal to the
/// anchor count. This matches Ultralytics' *default* TFLite export
/// behavior and mirrors your own methodology's separate NMS step
/// (Fig. 3-5), so it's the reasonable default — but if your export
/// used the `nms=True` option, or a different output layout, this
/// assumption is wrong and [_parseOutput] is the one place to fix it.
///
/// **First-run verification, recommended:** the debug print in
/// [initialize] logs the model's actual input/output shapes and
/// types the first time it loads. Check that output against what you
/// expect from your own export before trusting detection results.
class TFLiteDetectionEngine implements IDetectionEngine {
  /// Update this if your exported filename differs.
  static const String _modelAssetPath = 'assets/models/best_int8.tflite';

  Interpreter? _interpreter;
  IsolateInterpreter? _isolateInterpreter;

  late List<int> _inputShape; // [1, height, width, channels]
  late TensorType _inputType;
  late List<int> _outputShape; // [1, 5, numAnchors] or [1, numAnchors, 5]
  late TensorType _outputType;
  late QuantizationParams _outputParams;

  @override
  bool get isReady => _isolateInterpreter != null;

  @override
  Future<void> initialize() async {
    final interpreter = await Interpreter.fromAsset(_modelAssetPath);
    _interpreter = interpreter;
    _isolateInterpreter = await IsolateInterpreter.create(address: interpreter.address);

    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    _inputShape = inputTensor.shape;
    _inputType = inputTensor.type;
    _outputShape = outputTensor.shape;
    _outputType = outputTensor.type;
    _outputParams = outputTensor.params;

    // ignore: avoid_print
    print(
      'TFLiteDetectionEngine loaded — '
      'input: shape=$_inputShape type=$_inputType | '
      'output: shape=$_outputShape type=$_outputType. '
      'Verify these against your export before trusting results.',
    );
  }

  @override
  Future<DetectionResult> analyze(File image, {required String farmProfile}) async {
    final isolateInterpreter = _isolateInterpreter;
    if (isolateInterpreter == null) {
      throw StateError('TFLiteDetectionEngine.analyze() called before initialize().');
    }

    // ---- Preprocess: decode, resize to the model's actual input size ----
    final inputHeight = _inputShape[1];
    final inputWidth = _inputShape[2];

    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Could not decode the captured image for inference.');
    }
    final resized = img.copyResize(decoded, width: inputWidth, height: inputHeight);

    final input = _buildInputTensor(resized, inputWidth, inputHeight);
    final output = _buildEmptyOutputBuffer();

    // ---- Inference, off the main isolate ----
    await isolateInterpreter.run(input, output);

    // ---- Decode raw output -> confidence floor -> NMS -> threshold ----
    final aboveFloor = _parseOutput(output, inputWidth, inputHeight);
    final afterNms = _nonMaxSuppression(aboveFloor, DetectionConfig.nmsIouThreshold);

    if (afterNms.isEmpty) {
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

    afterNms.sort((a, b) => b.confidence.compareTo(a.confidence));
    final best = afterNms.first;
    final label = best.confidence >= DetectionConfig.operatingThreshold
        ? DetectionLabel.presumptivePositive
        : DetectionLabel.lowMatch;

    return DetectionResult(
      farmProfile: farmProfile,
      timestamp: DateTime.now(),
      diseaseClass: label == DetectionLabel.presumptivePositive ? 'hemorrhagic_ulcer' : 'uncertain',
      confidenceScore: best.confidence,
      imagePath: image.path,
      label: label,
      boundingBox: BoundingBox(left: best.left, top: best.top, width: best.width, height: best.height),
    );
  }

  // ============================================================
  // Preprocessing
  // ============================================================

  /// Builds a [1, height, width, 3] nested input matching whatever
  /// type the model's input tensor actually expects — uint8/int8 raw
  /// pixel values for a fully-integer-quantized input, or float32
  /// normalized to 0.0–1.0 otherwise (the common case even for models
  /// with INT8-quantized internals).
  Object _buildInputTensor(img.Image resized, int width, int height) {
    final isIntegerInput = _inputType == TensorType.uint8 || _inputType == TensorType.int8;

    return [
      List.generate(
        height,
        (y) => List.generate(width, (x) {
          final pixel = resized.getPixel(x, y);
          if (isIntegerInput) {
            return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
          }
          return [pixel.rNormalized, pixel.gNormalized, pixel.bNormalized];
        }),
      ),
    ];
  }

  // ============================================================
  // Output buffer + parsing
  // ============================================================

  /// Zero-filled buffer matching `_outputShape` exactly, using the
  /// same `List.filled(...).reshape(...)` pattern shown in
  /// tflite_flutter's own documentation.
  Object _buildEmptyOutputBuffer() {
    final totalSize = _outputShape.reduce((a, b) => a * b);
    return List.filled(totalSize, 0.0).reshape(_outputShape);
  }

  /// See the class-level doc comment for the output format this
  /// assumes and what to check if it's wrong for your export.
  List<_RawDetection> _parseOutput(Object output, int inputWidth, int inputHeight) {
    final batch = (output as List)[0]; // drop the batch=1 dimension

    final dim1 = _outputShape[1];
    final channelsFirst = dim1 == 5; // shape [1, 5, N] vs [1, N, 5]
    final numAnchors = channelsFirst ? _outputShape[2] : _outputShape[1];

    double valueAt(int channel, int anchor) {
      final Object raw;
      if (channelsFirst) {
        raw = ((batch as List)[channel] as List)[anchor];
      } else {
        raw = ((batch as List)[anchor] as List)[channel];
      }
      return _dequantizeOutput(raw);
    }

    final detections = <_RawDetection>[];
    for (var i = 0; i < numAnchors; i++) {
      final conf = valueAt(4, i);
      if (conf < DetectionConfig.confidenceFloor) continue;

      final cx = valueAt(0, i);
      final cy = valueAt(1, i);
      final w = valueAt(2, i);
      final h = valueAt(3, i);

      // cx/cy/w/h come out in the model's input pixel space for a
      // standard Ultralytics export — normalize to 0..1 fractions.
      final normCx = cx / inputWidth;
      final normCy = cy / inputHeight;
      final normW = w / inputWidth;
      final normH = h / inputHeight;

      detections.add(_RawDetection(
        left: _clamp01(normCx - normW / 2),
        top: _clamp01(normCy - normH / 2),
        width: _clamp01(normW),
        height: _clamp01(normH),
        confidence: conf,
      ));
    }
    return detections;
  }

  /// Standard TFLite dequantization: `real = scale * (quantized - zeroPoint)`.
  /// A no-op for already-float32 output tensors.
  double _dequantizeOutput(Object rawValue) {
    final numValue = (rawValue as num).toDouble();
    if (_outputType == TensorType.uint8 || _outputType == TensorType.int8) {
      return _outputParams.scale * (numValue - _outputParams.zeroPoint);
    }
    return numValue;
  }

  double _clamp01(double value) {
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
  }

  // ============================================================
  // Non-Max Suppression (Fig. 3-5, IoU 0.70 default)
  // ============================================================

  List<_RawDetection> _nonMaxSuppression(List<_RawDetection> boxes, double iouThreshold) {
    final sorted = [...boxes]..sort((a, b) => b.confidence.compareTo(a.confidence));
    final kept = <_RawDetection>[];
    for (final candidate in sorted) {
      final overlapsKept = kept.any((k) => _iou(candidate, k) > iouThreshold);
      if (!overlapsKept) kept.add(candidate);
    }
    return kept;
  }

  double _iou(_RawDetection a, _RawDetection b) {
    final interLeft = math.max(a.left, b.left);
    final interTop = math.max(a.top, b.top);
    final interRight = math.min(a.left + a.width, b.left + b.width);
    final interBottom = math.min(a.top + a.height, b.top + b.height);
    final interW = math.max(0.0, interRight - interLeft);
    final interH = math.max(0.0, interBottom - interTop);
    final interArea = interW * interH;
    final unionArea = a.width * a.height + b.width * b.height - interArea;
    if (unionArea <= 0) return 0.0;
    return interArea / unionArea;
  }
}

class _RawDetection {
  const _RawDetection({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.confidence,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double confidence;
}
