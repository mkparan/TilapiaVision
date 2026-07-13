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
/// Not persisted to the CSV log — it's only meaningful immediately
/// after a fresh detection, not for redisplaying history later.
class BoundingBox {
  const BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

/// One row of the `detection_log.csv` file (see [csvHeader] for exact
/// column order) plus, transiently, the [boundingBox] returned by a
/// fresh detection.
class DetectionResult {
  const DetectionResult({
    this.id,
    required this.farmProfile,
    required this.timestamp,
    required this.diseaseClass,
    required this.confidenceScore,
    this.imagePath,
    required this.label,
    this.boundingBox,
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
  final BoundingBox? boundingBox;

  /// Column order for the CSV log. Keep [toCsvRow] and [fromCsvRow]
  /// in sync with this if the schema ever changes.
  static const csvHeader = [
    'id',
    'farm_profile',
    'timestamp',
    'disease_class',
    'confidence_score',
    'image_path',
    'label',
  ];

  List<Object?> toCsvRow() {
    return [
      id,
      farmProfile,
      timestamp.toIso8601String(),
      diseaseClass,
      confidenceScore,
      imagePath ?? '',
      label.name,
    ];
  }

  factory DetectionResult.fromCsvRow(List<dynamic> row) {
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
    );
  }
}
