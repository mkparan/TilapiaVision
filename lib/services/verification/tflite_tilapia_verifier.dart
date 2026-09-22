import 'dart:io';


import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../model_load_exceptions.dart';
import 'i_tilapia_verifier.dart';

/// On-device species verification gate backed by
/// `tilapia_verifier_int8.tflite`.
///
/// Runs before the (more expensive) disease detector to confirm the
/// photographed subject is a Nile Tilapia. If it isn't, the detector
/// is skipped entirely.
///
/// Model tensor contract:
///   INPUT  [1, 224, 224, 3]  uint8  — channels-last, raw pixel bytes
///   OUTPUT [1, 1]            uint8  — quantised probability
///
/// probability = raw_byte * scale (scale/zero_point read from the
/// model itself, not hardcoded, so a re-exported model stays correct).
class TFLiteTilapiaVerifier implements ITilapiaVerifier {
  static const _modelAssetPath = 'assets/models/tilapia_verifier_int8.tflite';

  /// Preconfigured high (see SettingsRepository.defaultVerifierThreshold)
  /// to avoid accepting random objects or misframed captures while the
  /// verifier's own accuracy is still being improved. Adjustable from
  /// Settings, and that change is what updates this value.
  static double threshold = 0.85;

  Interpreter? _interpreter;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> initialize() async {
    if (_ready) return;

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
      throw ModelRunException('species verifier', '$e');
    }

    final inputShape = _interpreter!.getInputTensor(0).shape;
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    debugPrint('TFLiteTilapiaVerifier — input shape:  $inputShape');
    debugPrint('TFLiteTilapiaVerifier — output shape: $outputShape');

    _ready = true;
  }

  @override
  Future<bool> isTilapia(File image) async {
    if (!_ready) await initialize();

    final bytes = await image.readAsBytes();
    // Decode/resize on a background isolate so a large phone photo
    // doesn't stall the UI thread.
    final input = await compute(_prepareChannelsLastUint8, bytes);

    final output = Uint8List(1);
    try {
      _interpreter!.run(input.buffer, output.buffer);
    } catch (e) {
      throw ModelRunException('species verifier', '$e');
    }

    final params = _interpreter!.getOutputTensor(0).params;
    final scale = params.scale == 0 ? 1 / 256.0 : params.scale;
    final probability = (output[0] - params.zeroPoint) * scale;
    debugPrint('TFLiteTilapiaVerifier — raw=${output[0]}  '
        'prob=${probability.toStringAsFixed(4)}  '
        'isTilapia=${probability >= threshold}');

    return probability >= threshold;
  }

  /// Copies the asset to a real file on first use, so loading goes
  /// through Interpreter.fromFile — the most-tested loading path in
  /// tflite_flutter — instead of the AssetManager/mmap path that
  /// fromAsset uses, which can produce a model that loads (correct
  /// tensor shapes read from the header) but fails at invoke() with
  /// "Input tensor N lacks data" on some builds.
  Future<File> _materializeAsset(String assetPath) async {
    ByteData data;
    try {
      data = await rootBundle.load(assetPath);
    } catch (_) {
      throw ModelMissingException(assetPath, 'species verifier');
    }
    final fileName = assetPath.split('/').last;
    final file = File('${Directory.systemTemp.path}/$fileName');
    if (!await file.exists() || (await file.length()) != data.lengthInBytes) {
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return file;
  }
}

/// Runs on a background isolate via [compute]. Decodes the photo,
/// resizes to 224x224, and lays out a channels-last [1,224,224,3]
/// uint8 buffer of raw pixel bytes (no normalisation — this model
/// was exported expecting 0-255 directly).
Uint8List _prepareChannelsLastUint8(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('Could not decode image');
  const n = 224;
  final resized = img.copyResize(decoded, width: n, height: n);

  final input = Uint8List(n * n * 3);
  var idx = 0;
  for (int y = 0; y < n; y++) {
    for (int x = 0; x < n; x++) {
      final p = resized.getPixel(x, y);
      input[idx++] = p.r.toInt().clamp(0, 255);
      input[idx++] = p.g.toInt().clamp(0, 255);
      input[idx++] = p.b.toInt().clamp(0, 255);
    }
  }
  return input;
}
