import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../data/models/detection_result.dart';
import '../../data/repositories/detection_repository.dart';
import '../../services/detection/i_detection_engine.dart';
import '../../services/storage_service.dart';
import '../../services/verification/i_tilapia_verifier.dart';

/// The states a capture-to-result cycle can be in, driving which
/// view [ResultScreen] renders.
enum ScanStatus { idle, processing, success, timeout, error, notTilapia }

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
    if (result.imagePath != null) {
      final imgFile = File(result.imagePath!);
      if (await imgFile.exists()) {
        files.add(XFile(imgFile.path, mimeType: 'image/jpeg'));
      }
    }
    final summary = _summaryText(result);
    if (files.isEmpty) {
      await Share.share(summary, subject: 'TilapiaVision Detection');
    } else {
      await Share.shareXFiles(files, text: summary, subject: 'TilapiaVision Detection');
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
