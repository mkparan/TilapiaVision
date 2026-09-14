import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Canvas, Offset, Paint, Size;
import 'package:share_plus/share_plus.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../data/models/detection_result.dart';
import '../../data/repositories/detection_repository.dart';
import '../../services/detection/i_detection_engine.dart';
import '../../services/storage_service.dart';
import '../../services/model_load_exceptions.dart';
import '../../services/verification/i_tilapia_verifier.dart';
import '../../services/verification/tflite_tilapia_verifier.dart';
import '../widgets/bounding_box_painter.dart';

/// The states a capture-to-result cycle can be in, driving which
/// view [ResultScreen] renders.
enum ScanStatus { idle, processing, success, timeout, error, notTilapia, modelMissing, modelFailed }

/// Orchestrates a single detection: runs the active [IDetectionEngine]
/// (Mock today, TFLite once the trained model lands), caches the
/// photo, and hands off to [DetectionRepository] for CSV persistence.
///
/// Swapping detection engines is the entire integration-day change:
/// only the `engine:` this is constructed with needs to differ once
/// [TFLiteDetectionEngine] is active. Swap `MockDetectionEngine()` for
/// `TFLiteDetectionEngine()` wherever this provider is constructed
/// (see `main.dart`) and nothing else in the app needs to change.
class DetectionProvider extends ChangeNotifier {
  DetectionProvider({
    required IDetectionEngine engine,
    required DetectionRepository repository,
    required StorageService storageService,
    ITilapiaVerifier? verifier,
  })  : _engine = engine,
        _repository = repository,
        _storageService = storageService,
        _verifier = verifier;

  final IDetectionEngine _engine;
  final DetectionRepository _repository;
  final StorageService _storageService;
  final ITilapiaVerifier? _verifier;

  ScanStatus status = ScanStatus.idle;
  DetectionResult? lastResult;
  List<DetectionResult> history = [];

  /// Populated on modelMissing/modelFailed with the full explanation.
  String errorDetail = '';

  Future<void> runDetection(File image, {required String farmProfile}) async {
    status = ScanStatus.processing;
    notifyListeners();

    try {
      // Species verification gate — if a verifier is wired in, confirm
      // the subject is a Tilapia before running the expensive detector.
      if (_verifier != null) {
        final isTilapia = await _verifier.isTilapia(image);
        if (!isTilapia) {
          status = ScanStatus.notTilapia;
          notifyListeners();
          return;
        }
      }

      if (!_engine.isReady) {
        await _engine.initialize();
      }

      final result = await _engine
          .analyze(image, farmProfile: farmProfile)
          .timeout(DetectionConfig.inferenceTimeout);

      // Low Match is a UI-only prompt per the detection spec — it is
      // not cached or logged, so don't spend the disk I/O
      // compressing/copying the photo for it.
      if (result.label == DetectionLabel.lowMatch) {
        lastResult = result;
      } else {
        final cachedPath = await _storageService.cacheImage(image);
        lastResult = DetectionResult(
          farmProfile: result.farmProfile,
          timestamp: result.timestamp,
          diseaseClass: result.diseaseClass,
          confidenceScore: result.confidenceScore,
          imagePath: cachedPath,
          label: result.label,
          boundingBox: result.boundingBox,
        );
      }

      status = ScanStatus.success;
    } on ModelMissingException catch (e) {
      errorDetail = e.toString();
      status = ScanStatus.modelMissing;
    } on ModelRunException catch (e) {
      errorDetail = e.toString();
      status = ScanStatus.modelFailed;
    } on TimeoutException {
      status = ScanStatus.timeout;
    } catch (e, st) {
      debugPrint('DetectionProvider.runDetection FAILED: $e');
      debugPrint('$st');
      status = ScanStatus.error;
    }

    notifyListeners();
  }

  Future<void> saveLastResultToHistory() async {
    if (lastResult == null) return;
    await _repository.saveDetection(lastResult!);
    await loadHistory();
  }

  Future<void> loadHistory() async {
    history = await _repository.getRecentDetections();
    notifyListeners();
  }

  /// Opens the platform share sheet with the detection log CSV file
  /// attached — the entire "export" feature. There's no separate
  /// export format to generate: the working log already IS the CSV.
  Future<void> exportCsv() async {
    final file = await _repository.exportCsvFile();
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: 'TilapiaVision detection log',
      subject: 'TilapiaVision detection log export',
    );
  }

  /// Exports a single detection's photo (if it hasn't expired) plus
  /// a short text summary. If the photo is gone, falls back to a
  /// text-only share — never fails silently, the farmer always gets
  /// something to hand to a technician.
  Future<void> exportSingleDetection(DetectionResult result) async {
    final files = <XFile>[];
    final rendered = await _renderImageWithBox(result);
    if (rendered != null) {
      files.add(XFile(rendered.path, mimeType: 'image/png'));
    }
    final summary = _summaryText(result);
    if (files.isEmpty) {
      await Share.share(summary, subject: 'TilapiaVision Detection');
    } else {
      await Share.shareXFiles(files, text: summary, subject: 'TilapiaVision Detection');
    }
  }

  /// Composites the cached photo and its bounding box into one new
  /// image file, and returns it.
  ///
  /// The box seen on screen is a [BoundingBoxPainter] overlay — it is
  /// never part of the stored JPEG. Sharing `result.imagePath` directly
  /// exports the raw photo with no box on it, which was the original
  /// bug here. The composite has to be produced at export time because
  /// it does not exist anywhere until now.
  Future<File?> _renderImageWithBox(DetectionResult result) async {
    if (result.imagePath == null) return null;
    final srcFile = File(result.imagePath!);
    if (!await srcFile.exists()) return null;
    if (result.boundingBox == null) return srcFile;

    try {
      final bytes = await srcFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final srcImage = frame.image;
      final w = srcImage.width.toDouble();
      final h = srcImage.height.toDouble();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImage(srcImage, Offset.zero, Paint());

      BoundingBoxPainter(
        box: result.boundingBox!,
        color: result.label == DetectionLabel.presumptivePositive
            ? AppColors.amber
            : AppColors.slate,
        label: '${(result.confidenceScore * 100).round()}%',
        dashed: result.label == DetectionLabel.lowMatch,
      ).paint(canvas, Size(w, h));

      final composited =
          await recorder.endRecording().toImage(srcImage.width, srcImage.height);
      final pngData =
          await composited.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) return srcFile;

      final dir = Directory.systemTemp;
      final out = File(
        '${dir.path}/tilapiavision_export_'
        '${result.id ?? DateTime.now().millisecondsSinceEpoch}.png',
      );
      await out.writeAsBytes(pngData.buffer.asUint8List());
      return out;
    } catch (e) {
      debugPrint('Bounding-box render failed, exporting raw photo: $e');
      return srcFile;
    }
  }

  /// For the Settings screen's model-status tiles — checks readiness
  /// without running a full scan.
  Future<bool> checkVerifierReady() async {
    try {
      final v = _verifier;
      if (v == null) return false;
      if (v is TFLiteTilapiaVerifier) {
        if (!v.isReady) await v.initialize();
        return v.isReady;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkDetectorReady() async {
    try {
      if (!_engine.isReady) await _engine.initialize();
      return _engine.isReady;
    } catch (_) {
      return false;
    }
  }

  String _summaryText(DetectionResult r) {
    String labelText;
    switch (r.label) {
      case DetectionLabel.presumptivePositive:
        labelText = 'Presumptive Positive — ${r.diseaseClass}';
        break;
      case DetectionLabel.lowMatch:
        labelText = 'Low Match';
        break;
      case DetectionLabel.clear:
        labelText = 'No Lesions Detected';
        break;
    }
    return 'TilapiaVision Detection\n'
        'Farm: ${r.farmProfile}\n'
        'Date: ${r.timestamp}\n'
        'Result: $labelText\n'
        'Confidence: ${(r.confidenceScore * 100).round()}%';
  }

  /// Removes a single record from the CSV log permanently.
  Future<void> deleteDetection(int id) async {
    await _repository.deleteDetection(id);
    await loadHistory();
  }

  void reset() {
    status = ScanStatus.idle;
    lastResult = null;
    notifyListeners();
  }
}
