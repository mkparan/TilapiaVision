import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
enum ScanStatus {
  idle,
  processing,
  success,
  timeout,
  error,
  notTilapia,
  modelMissing,
  modelFailed
}

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
          boundingBoxes: result.boundingBoxes,
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
    final rendered = await _renderAnnotatedImage(result);
    if (rendered != null) {
      files.add(XFile(rendered.path, mimeType: 'image/png'));
    }
    final summary = _summaryText(result);
    if (files.isEmpty) {
      await Share.share(summary, subject: 'TilapiaVision Detection');
    } else {
      await Share.shareXFiles(files,
          text: summary, subject: 'TilapiaVision Detection');
    }
  }

  /// Composites the cached photo (with all bounding boxes) and a white
  /// info panel below it into one PNG file, then returns it.
  ///
  /// Layout:
  ///   ┌────────────────────────────┐
  ///   │   fish photo + all boxes   │  ← original pixel dimensions
  ///   ├────────────────────────────┤
  ///   │   white info panel         │  ← panelH pixels
  ///   │   • Result badge           │
  ///   │   • Farm / Date / Count    │
  ///   │   • Confidence             │
  ///   │   • TilapiaVision watermark│
  ///   └────────────────────────────┘
  Future<File?> _renderAnnotatedImage(DetectionResult result) async {
    if (result.imagePath == null) return null;
    final srcFile = File(result.imagePath!);
    if (!await srcFile.exists()) return null;

    try {
      final bytes = await srcFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final srcImage = frame.image;
      final w = srcImage.width.toDouble();
      final h = srcImage.height.toDouble();

      // ── panel dimensions ─────────────────────────────────────────────
      // Scale with image height — no hard upper cap so that a 2400-px-
      // tall phone photo gets a readable panel (~720 px), not a postage-
      // stamp one.
      final panelH = h * 0.30;
      final totalH = h + panelH;
      final pad = panelH * 0.08;
      final lineH = panelH * 0.15;
      final fontSize = lineH * 0.60;
      final labelFontSize = (w < h ? w : h) * 0.025;
      final strokeWidth = (w < h ? w : h) * 0.010;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // ── photo ────────────────────────────────────────────────────────
      canvas.drawImage(srcImage, Offset.zero, Paint());

      // ── bounding boxes ───────────────────────────────────────────────
      if (result.boundingBoxes.isNotEmpty) {
        MultiBoxPainter(
          boxes: result.boundingBoxes,
          color: result.label == DetectionLabel.presumptivePositive
              ? AppColors.amber
              : AppColors.slate,
          fallbackLabel: '${(result.confidenceScore * 100).round()}%',
          dashed: result.label == DetectionLabel.lowMatch,
          strokeWidth: strokeWidth.clamp(6.0, 14.0),
          labelFontSize: labelFontSize.clamp(16.0, 28.0),
        ).paint(canvas, Size(w, h));
      }

      // ── white info panel ─────────────────────────────────────────────
      final panelTop = h;
      canvas.drawRect(
        Rect.fromLTWH(0, panelTop, w, panelH),
        Paint()..color = const Color(0xFFFFFFFF),
      );

      // Accent bar at top of panel
      final accentColor = result.label == DetectionLabel.presumptivePositive
          ? AppColors.amber
          : result.label == DetectionLabel.clear
              ? AppColors.mint
              : AppColors.slate;
      canvas.drawRect(
        Rect.fromLTWH(0, panelTop, w, strokeWidth.clamp(4.0, 8.0)),
        Paint()..color = accentColor,
      );

      // Helper to paint a text line
      void drawText(
        String text, {
        required double y,
        double? x,
        double? size,
        Color color = const Color(0xFF1A1A2E),
        FontWeight weight = FontWeight.normal,
      }) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: size ?? fontSize,
              color: color,
              fontWeight: weight,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: w - pad * 2);
        tp.paint(canvas, Offset(x ?? pad, y));
      }

      String labelText;
      switch (result.label) {
        case DetectionLabel.presumptivePositive:
          labelText = 'Presumptive Positive';
          break;
        case DetectionLabel.lowMatch:
          labelText = 'Low Match';
          break;
        case DetectionLabel.clear:
          labelText = 'No Lesions Detected';
          break;
      }

      final lesionCount = result.boundingBoxes.length;
      final dateStr = '${result.timestamp.year}-'
          '${result.timestamp.month.toString().padLeft(2, '0')}-'
          '${result.timestamp.day.toString().padLeft(2, '0')}  '
          '${result.timestamp.hour.toString().padLeft(2, '0')}:'
          '${result.timestamp.minute.toString().padLeft(2, '0')}';

      var y = panelTop + pad + strokeWidth.clamp(4.0, 8.0) + pad * 0.5;

      drawText(labelText,
          y: y,
          size: fontSize * 1.15,
          color: accentColor,
          weight: FontWeight.bold);
      y += lineH;

      drawText('Farm: ${result.farmProfile}', y: y);
      y += lineH * 0.85;

      drawText('Date: $dateStr', y: y);
      y += lineH * 0.85;

      if (lesionCount > 0) {
        drawText(
          'Lesions detected: $lesionCount  •  '
          'Top confidence: ${(result.confidenceScore * 100).round()}%',
          y: y,
        );
        y += lineH * 0.85;
      }

      // Watermark
      drawText(
        'TilapiaVision',
        y: panelTop + panelH - pad - fontSize * 0.9,
        x: w - pad - fontSize * 6.5,
        size: fontSize * 0.75,
        color: const Color(0xFFB0B8C8),
      );

      // ── composite and save ──────────────────────────────────────────
      final composited = await recorder
          .endRecording()
          .toImage(srcImage.width, (totalH).round());
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
      debugPrint('Annotated render failed, exporting raw photo: $e');
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
