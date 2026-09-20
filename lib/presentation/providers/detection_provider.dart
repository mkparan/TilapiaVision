import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Canvas, Offset, Paint, Size;
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
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

/// What happened when a saved result was written to the phone gallery.
/// The detail screen maps each value to a localized message.
enum GallerySaveOutcome { saved, photoUnavailable, accessDenied, failed }

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

  /// Saves a detection's photo — with all of its bounding boxes burned
  /// in — into the phone's photo gallery, in a "TilapiaVision" album.
  ///
  /// It never throws: every failure comes back as a
  /// [GallerySaveOutcome] so the caller can show a message.
  ///
  /// The gallery copy also gets a caption strip under the photo with
  /// the farm name, the result and the scan date.
  /// [resultLabel] is the already-localized result text (the caller has
  /// the app language); if it is omitted, an English label is used.
  ///
  /// Gal requests storage access itself when the device needs it
  /// (Android 10 and older); Android 11+ needs no permission at all.
  Future<GallerySaveOutcome> saveDetectionToGallery(
      DetectionResult result, {String? resultLabel}) async {
    File? namedCopy;
    try {
      final farm = result.farmProfile.trim();
      final rendered = await _renderImageWithBox(
        result,
        captionLines: [
          if (farm.isNotEmpty)
            _CaptionLine(farm, color: const ui.Color(0xFFFFFFFF)),
          _CaptionLine(
            resultLabel ?? _englishResultLabel(result.label),
            color: result.label == DetectionLabel.presumptivePositive
                ? AppColors.amber
                : (result.label == DetectionLabel.clear
                    ? AppColors.mint
                    : const ui.Color(0xFFD7ECF2)),
            scale: 0.9,
            weight: ui.FontWeight.w700,
          ),
          _CaptionLine(
            // Same format the Result and Detail screens use for the date.
            DateFormat('MMM d, yyyy — h:mm a').format(result.timestamp),
            color: const ui.Color(0xB3FFFFFF),
            scale: 0.75,
            weight: ui.FontWeight.w500,
          ),
        ],
      );
      if (rendered == null) return GallerySaveOutcome.photoUnavailable;

      // Gal takes the gallery file name from the source file name and
      // requires an extension. Copy to a readable, timestamp-based name
      // (e.g. TilapiaVision_20260919_143005.png) rather than exposing
      // the internal archive/export name. Only this COPY is deleted
      // afterwards — never [rendered], which may be the archive photo.
      final ext = p.extension(rendered.path).isEmpty
          ? '.jpg'
          : p.extension(rendered.path);
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(result.timestamp);
      namedCopy = await rendered
          .copy('${Directory.systemTemp.path}/TilapiaVision_$stamp$ext');

      await Gal.putImage(namedCopy.path, album: 'TilapiaVision');
      return GallerySaveOutcome.saved;
    } on GalException catch (e) {
      debugPrint('Save to gallery failed: $e');
      return e.type == GalExceptionType.accessDenied
          ? GallerySaveOutcome.accessDenied
          : GallerySaveOutcome.failed;
    } catch (e, st) {
      debugPrint('Save to gallery failed: $e');
      debugPrint('$st');
      return GallerySaveOutcome.failed;
    } finally {
      try {
        await namedCopy?.delete();
      } catch (_) {
        // Best-effort temp cleanup only.
      }
    }
  }

  /// Composites the cached photo and all of its bounding boxes into one
  /// new image file, and returns it.
  ///
  /// The boxes seen on screen are a [MultiBoxPainter] overlay — they are
  /// never part of the stored JPEG. Sharing `result.imagePath` directly
  /// exports the raw photo with no box on it, which was the original
  /// bug here. The composite has to be produced at export time because
  /// it does not exist anywhere until now.
  ///
  /// If [captionLines] is given, a caption strip with those lines is added
  /// UNDER the photo (so it never covers the fish) and the result is
  /// rendered even when there is no bounding box. Without it, only the
  /// boxes are burned in. (Today the only caller, the gallery save, always
  /// passes a caption.)
  Future<File?> _renderImageWithBox(
    DetectionResult result, {
    List<_CaptionLine>? captionLines,
  }) async {
    if (result.imagePath == null) return null;
    final srcFile = File(result.imagePath!);
    if (!await srcFile.exists()) return null;
    final hasCaption = captionLines != null && captionLines.isNotEmpty;
    if (result.boundingBoxes.isEmpty && !hasCaption) return srcFile;

    try {
      final bytes = await srcFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final srcImage = frame.image;
      final w = srcImage.width.toDouble();
      final h = srcImage.height.toDouble();

      // Lay the caption out first: its height decides how tall the
      // final image is.
      final caption = (captionLines != null && captionLines.isNotEmpty)
          ? _CaptionLayout.build(
              lines: captionLines,
              width: w,
              shortSide: w < h ? w : h,
            )
          : null;
      final captionHeight = caption?.height ?? 0.0;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImage(srcImage, Offset.zero, Paint());

      if (result.boundingBoxes.isNotEmpty) {
        MultiBoxPainter(
          boxes: result.boundingBoxes,
          color: result.label == DetectionLabel.presumptivePositive
              ? AppColors.amber
              : AppColors.slate,
          fallbackLabel: '${(result.confidenceScore * 100).round()}%',
          dashed: result.label == DetectionLabel.lowMatch,
          // The UI overlay is painted in logical pixels, while this export
          // canvas uses the source photo's full pixel dimensions.
          strokeWidth: ((w < h ? w : h) * 0.008).clamp(6.0, 14.0).toDouble(),
          labelFontSize:
              ((w < h ? w : h) * 0.018).clamp(16.0, 28.0).toDouble(),
        ).paint(canvas, Size(w, h));
      }

      caption?.paint(canvas, top: h);

      final composited = await recorder
          .endRecording()
          .toImage(srcImage.width, srcImage.height + captionHeight.ceil());
      final pngData =
          await composited.toByteData(format: ui.ImageByteFormat.png);
      if (pngData == null) return srcFile;

      final dir = Directory.systemTemp;
      // A captioned render gets its own file name so it can never
      // overwrite (or be overwritten by) a caption-less render of the
      // same scan.
      final suffix = hasCaption ? '_caption' : '';
      final out = File(
        '${dir.path}/tilapiavision_export_'
        '${result.id ?? DateTime.now().millisecondsSinceEpoch}$suffix.png',
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

  /// English result label, used only when the caller doesn't pass a
  /// localized one.
  String _englishResultLabel(DetectionLabel label) {
    switch (label) {
      case DetectionLabel.presumptivePositive:
        return 'Presumptive Positive';
      case DetectionLabel.lowMatch:
        return 'Low Match';
      case DetectionLabel.clear:
        return 'No Lesions Detected';
    }
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

/// One line of text in the gallery caption strip.
class _CaptionLine {
  const _CaptionLine(
    this.text, {
    required this.color,
    this.scale = 1.0,
    this.weight = ui.FontWeight.w600,
  });

  final String text;
  final ui.Color color;

  /// Font size relative to the caption's base size (1.0 = base).
  final double scale;
  final ui.FontWeight weight;
}

/// The caption strip drawn under a gallery photo: the given lines, top to
/// bottom, on a dark navy band.
///
/// Laid out with plain dart:ui paragraphs so it works on the export
/// canvas, at the photo's full pixel size, with no widget tree.
class _CaptionLayout {
  _CaptionLayout._(
      this.paragraphs, this.width, this.padding, this.gap, this.height);

  final List<ui.Paragraph> paragraphs;

  /// Full width of the strip in pixels (the photo's width).
  final double width;
  final double padding;
  final double gap;

  /// Total height of the strip in pixels.
  final double height;

  factory _CaptionLayout.build({
    required List<_CaptionLine> lines,
    required double width,
    required double shortSide,
  }) {
    // Scales with the photo (archived photos keep their full camera
    // resolution), so the text stays readable when the gallery shrinks it.
    final baseSize = (shortSide * 0.032).clamp(22.0, 96.0).toDouble();
    final padding = baseSize * 0.8;
    final gap = baseSize * 0.3;
    final maxWidth = width - padding * 2;

    final paragraphs = <ui.Paragraph>[];
    var textHeight = 0.0;
    for (final line in lines) {
      final size = baseSize * line.scale;
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
        fontSize: size,
        fontWeight: line.weight,
      ))
        ..pushStyle(ui.TextStyle(
          color: line.color,
          fontSize: size,
          fontWeight: line.weight,
        ))
        ..addText(line.text);
      final paragraph = builder.build()
        ..layout(ui.ParagraphConstraints(width: maxWidth));
      paragraphs.add(paragraph);
      textHeight += paragraph.height;
    }
    textHeight += gap * (paragraphs.length - 1);
    return _CaptionLayout._(
        paragraphs, width, padding, gap, textHeight + padding * 2);
  }

  /// Paints the band and its text with the band's top edge at [top].
  void paint(Canvas canvas, {required double top}) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, top, width, height),
      Paint()..color = AppColors.navy,
    );
    var y = top + padding;
    for (final paragraph in paragraphs) {
      canvas.drawParagraph(paragraph, Offset(padding, y));
      y += paragraph.height + gap;
    }
  }
}
