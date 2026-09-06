import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'i_tilapia_verifier.dart';

/// On-device species verification gate backed by
/// `tilapia_verifier_int8.tflite`.
///
/// Runs before the (more expensive) disease detector to confirm the
/// photographed subject is a Nile Tilapia. If it isn't, the detector
/// is skipped entirely.
///
/// Model tensor contract:
///   INPUT  [1, 224, 224, 3]  uint8    — channels-last, raw pixel bytes
///   OUTPUT [1, 1]            uint8    — quantised probability
///
/// Output dequantisation (from model export):
///   scale      = 0.00390625  (1/256)
///   zero_point = 0
///   probability = raw_byte * scale
///   isTilapia  ⟺  probability >= 0.5
class TFLiteTilapiaVerifier implements ITilapiaVerifier {
  static const _modelAssetPath = 'assets/models/tilapia_verifier_int8.tflite';
  static const _inputSize = 224;

  /// Output quantisation parameters — obtained from
  /// `interpreter.get_output_details()[0]['quantization']`.
  static const double _outputScale = 0.00390625; // 1/256
  static const int _outputZeroPoint = 0;
  static const double _tilapiaThreshold = 0.5;

  Interpreter? _interpreter;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> initialize() async {
    // Same XNNPack delegate as TFLiteDetectionEngine, for a consistent
    // execution path across both models (see that class's doc comment
    // for why this matters — it's what avoids a native tensor-data
    // error on the disease detector).
    final options = InterpreterOptions()..addDelegate(XNNPackDelegate());
    _interpreter = await Interpreter.fromAsset(_modelAssetPath, options: options);
    _interpreter!.allocateTensors();

    final inputShape = _interpreter!.getInputTensor(0).shape;
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    debugPrint('TFLiteTilapiaVerifier — input shape:  $inputShape');
    debugPrint('TFLiteTilapiaVerifier — output shape: $outputShape');

    _ready = true;
  }

  @override
  Future<bool> isTilapia(File image) async {
    if (!_ready) await initialize();

    // ----------------------------------------------------------
    // 1. Decode & resize to 224×224
    // ----------------------------------------------------------
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      // Can't decode → let it through; the detector will fail or the
      // user will see an error on the next screen. Failing the gate
      // here on a decoding issue would be misleading.
      debugPrint('TFLiteTilapiaVerifier: could not decode image, passing through');
      return true;
    }
    final resized = img.copyResize(decoded, width: _inputSize, height: _inputSize);

    // ----------------------------------------------------------
    // 2. Build channels-last flat uint8 input [1, 224, 224, 3]
    // ----------------------------------------------------------
    final input = Uint8List(1 * _inputSize * _inputSize * 3);
    int idx = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[idx++] = pixel.r.toInt().clamp(0, 255);
        input[idx++] = pixel.g.toInt().clamp(0, 255);
        input[idx++] = pixel.b.toInt().clamp(0, 255);
      }
    }

    // ----------------------------------------------------------
    // 3. Run inference — output [1, 1] uint8
    // ----------------------------------------------------------
    final output = Uint8List(1);
    
    // Passing .buffer bypasses tflite_flutter's slow list conversion
    _interpreter!.run(input.buffer, output.buffer);

    // ----------------------------------------------------------
    // 4. Dequantise & threshold
    // ----------------------------------------------------------
    final rawByte = output[0];
    final probability = (rawByte - _outputZeroPoint) * _outputScale;
    debugPrint(
      'TFLiteTilapiaVerifier — raw=$rawByte  prob=${probability.toStringAsFixed(4)}  '
      'isTilapia=${probability >= _tilapiaThreshold}',
    );

    return probability >= _tilapiaThreshold;
  }
}
