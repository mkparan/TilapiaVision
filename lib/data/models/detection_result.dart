import 'dart:convert';

/// The three UI-facing outcome categories a scan can resolve to.
///
/// [lowMatch] is deliberately NOT the same thing as [clear] — a Low
/// Match means "something was detected but confidence was too low to
/// call it," while [clear] means the model found nothing at all above
/// the confidence floor. See the Result screen for how each is framed.
///
/// IMPORTANT — terminology note: nothing in this app displays an
/// "accuracy" figure at runtime. [DetectionResult.confidenceScore] is
/// a single prediction's confidence, not a model accuracy metric.
/// Accuracy, mAP@50, and Recall are evaluation statistics computed
/// once, offline, across a held-out test set during model
/// development (Chapter 3) — they are never something the app itself
/// calculates or shows to a farmer. Keeping this distinction sharp in
/// the code and copy is deliberate; conflating "confidence" with
/// "accuracy" is a common — and easily criticized — mistake.
enum DetectionLabel { presumptivePositive, lowMatch, clear }

/// A normalized (0.0–1.0) bounding box, expressed as fractions of the
/// source image's width/height so it can be rendered onto any
/// display size without needing the original image's pixel dimensions.
///
/// Persisted to the CSV log as a JSON object inside the `bboxes` column
/// so multiple boxes per detection can be stored in a single row.
class BoundingBox {
  const BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.confidence,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  /// Per-box confidence score — present on fresh detections, may be
  /// null when loaded from old CSV rows that pre-date this field.
  final double? confidence;

  Map<String, dynamic> toJson() => {
        'l': left,
        't': top,
        'w': width,
        'h': height,
        if (confidence != null) 'c': confidence,
      };

  factory BoundingBox.fromJson(Map<String, dynamic> j) => BoundingBox(
        left: (j['l'] as num).toDouble(),
        top: (j['t'] as num).toDouble(),
        width: (j['w'] as num).toDouble(),
        height: (j['h'] as num).toDouble(),
        confidence: j['c'] != null ? (j['c'] as num).toDouble() : null,
      );
}

/// One row of the `detection_log.csv` file (see [csvHeader] for exact
/// column order) including all detected [boundingBoxes], if any.
class DetectionResult {
  const DetectionResult({
    this.id,
    required this.farmProfile,
    required this.timestamp,
    required this.diseaseClass,
    required this.confidenceScore,
    this.imagePath,
    required this.label,
    this.boundingBoxes = const [],
  });

  final int? id;
  final String farmProfile;
  final DateTime timestamp;
  final String diseaseClass;

  /// A single prediction's confidence (0.0–1.0) — NOT a model
  /// accuracy figure. See the [DetectionLabel] doc comment.
  final double confidenceScore;
  final String? imagePath;
  final DetectionLabel label;

  /// All detected lesion boxes for this scan, sorted highest-confidence
  /// first. May be empty (e.g. [DetectionLabel.clear] results).
  final List<BoundingBox> boundingBoxes;

  /// Convenience getter — the primary (highest-confidence) box, or null.
  BoundingBox? get boundingBox =>
      boundingBoxes.isNotEmpty ? boundingBoxes.first : null;

  /// Column order for the CSV log. Keep [toCsvRow] and [fromCsvRow]
  /// in sync with this if the schema ever changes.
  ///
  /// v2 schema: the four individual bbox_* columns are replaced by a
  /// single `bboxes` column containing a compact JSON array so multiple
  /// lesion boxes can be stored per row.
  static const csvHeader = [
    'id',
    'farm_profile',
    'timestamp',
    'disease_class',
    'confidence_score',
    'image_path',
    'label',
    'bboxes', // JSON array of {l,t,w,h,c} objects  (v2 schema)
  ];

  List<Object?> toCsvRow() {
    final bboxJson = boundingBoxes.isEmpty
        ? ''
        : jsonEncode(boundingBoxes.map((b) => b.toJson()).toList());
    return [
      id,
      farmProfile,
      timestamp.toIso8601String(),
      diseaseClass,
      confidenceScore,
      imagePath ?? '',
      label.name,
      bboxJson,
    ];
  }

  factory DetectionResult.fromCsvRow(List<dynamic> row) {
    double? parseOrNull(dynamic v) =>
        v == null || v.toString().isEmpty ? null : double.tryParse(v.toString());

    // ── v2 schema: 8 columns, last is JSON bbox array ──────────────
    // v1 rows also have ≥ 8 columns (11) but column 7 is a plain
    // numeric string (bbox_left), NOT JSON. Detect v2 by checking that
    // col 7 starts with '[' or '{' or is empty.
    if (row.length >= 8) {
      final col7 = row[7].toString().trim();
      final isJsonBboxes = col7.isEmpty || col7.startsWith('[') || col7.startsWith('{');

      if (isJsonBboxes) {
        List<BoundingBox> boxes = [];
        if (col7.isNotEmpty && col7.startsWith('[')) {
          try {
            final decoded = jsonDecode(col7) as List<dynamic>;
            boxes = decoded
                .map((e) => BoundingBox.fromJson(e as Map<String, dynamic>))
                .toList();
          } catch (_) {
            boxes = [];
          }
        } else if (col7.isNotEmpty && col7.startsWith('{')) {
          try {
            boxes = [BoundingBox.fromJson(jsonDecode(col7) as Map<String, dynamic>)];
          } catch (_) {}
        }

        return DetectionResult(
          id: int.tryParse(row[0].toString()),
          farmProfile: row[1].toString(),
          timestamp: DateTime.parse(row[2].toString()),
          diseaseClass: row[3].toString(),
          confidenceScore: double.tryParse(row[4].toString()) ?? 0.0,
          imagePath: row[5].toString().isEmpty ? null : row[5].toString(),
          label: DetectionLabel.values.firstWhere(
            (e) => e.name == row[6].toString(),
            orElse: () => DetectionLabel.lowMatch,
          ),
          boundingBoxes: boxes,
        );
      }
    }

    // ── v1 schema: 11 columns with individual bbox_* columns ────────
    // Kept so old CSV files still load correctly after an update.
    final left = parseOrNull(row.length > 7 ? row[7] : null);
    final top = parseOrNull(row.length > 8 ? row[8] : null);
    final width = parseOrNull(row.length > 9 ? row[9] : null);
    final height = parseOrNull(row.length > 10 ? row[10] : null);

    return DetectionResult(
      id: int.tryParse(row[0].toString()),
      farmProfile: row[1].toString(),
      timestamp: DateTime.parse(row[2].toString()),
      diseaseClass: row[3].toString(),
      confidenceScore: double.tryParse(row[4].toString()) ?? 0.0,
      imagePath: row[5].toString().isEmpty ? null : row[5].toString(),
      label: DetectionLabel.values.firstWhere(
        (e) => e.name == row[6].toString(),
        orElse: () => DetectionLabel.lowMatch,
      ),
      boundingBoxes: (left != null && top != null && width != null && height != null)
          ? [BoundingBox(left: left, top: top, width: width, height: height)]
          : [],
    );
  }
}
