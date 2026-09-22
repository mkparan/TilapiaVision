import 'package:flutter_test/flutter_test.dart';
import 'package:tilapiavision/data/models/detection_result.dart';

/// These tests exercise the CSV row <-> DetectionResult conversion
/// directly (no file I/O, no path_provider plugin needed), which is
/// the part of CsvStore most worth getting exactly right: get this
/// wrong and every history entry silently corrupts.
void main() {
  group('DetectionResult CSV round-trip', () {
    test('toCsvRow -> fromCsvRow preserves all fields, including boundingBoxes', () {
      final original = DetectionResult(
        id: 7,
        farmProfile: 'Doongan Grow-Out Pond',
        timestamp: DateTime.parse('2026-07-08T14:30:00.000'),
        diseaseClass: 'hemorrhagic_ulcer',
        confidenceScore: 0.87,
        imagePath: '/data/visual_archive/12345.jpg',
        label: DetectionLabel.presumptivePositive,
        boundingBoxes: const [
          BoundingBox(left: 0.32, top: 0.30, width: 0.34, height: 0.26, confidence: 0.87),
          BoundingBox(left: 0.10, top: 0.50, width: 0.20, height: 0.15, confidence: 0.71),
        ],
      );

      final row = original.toCsvRow();
      final restored = DetectionResult.fromCsvRow(row);

      expect(restored.id, original.id);
      expect(restored.farmProfile, original.farmProfile);
      expect(restored.timestamp, original.timestamp);
      expect(restored.diseaseClass, original.diseaseClass);
      expect(restored.confidenceScore, original.confidenceScore);
      expect(restored.imagePath, original.imagePath);
      expect(restored.label, original.label);
      expect(restored.boundingBoxes.length, 2);
      expect(restored.boundingBox, isNotNull);
      expect(restored.boundingBox!.left, original.boundingBox!.left);
      expect(restored.boundingBox!.top, original.boundingBox!.top);
      expect(restored.boundingBox!.width, original.boundingBox!.width);
      expect(restored.boundingBox!.height, original.boundingBox!.height);
    });

    test('empty boundingBoxes round-trips as empty, not null', () {
      final original = DetectionResult(
        farmProfile: 'Test Farm',
        timestamp: DateTime.now(),
        diseaseClass: 'none',
        confidenceScore: 0.0,
        label: DetectionLabel.clear,
        // no boundingBoxes
      );

      final restored = DetectionResult.fromCsvRow(original.toCsvRow());

      expect(restored.boundingBoxes, isEmpty);
      expect(restored.boundingBox, isNull);
    });

    test('a null imagePath round-trips as null, not the string "null"', () {
      final original = DetectionResult(
        farmProfile: 'Test Farm',
        timestamp: DateTime.now(),
        diseaseClass: 'none',
        confidenceScore: 0.0,
        label: DetectionLabel.clear,
      );

      final restored = DetectionResult.fromCsvRow(original.toCsvRow());

      expect(restored.imagePath, isNull);
    });

    test('row order and length match csvHeader exactly (8 columns with bboxes JSON)', () {
      final result = DetectionResult(
        id: 1,
        farmProfile: 'F',
        timestamp: DateTime.parse('2026-01-01T00:00:00.000'),
        diseaseClass: 'hemorrhagic_ulcer',
        confidenceScore: 0.5,
        label: DetectionLabel.lowMatch,
      );
      final row = result.toCsvRow();

      expect(row.length, DetectionResult.csvHeader.length);
      expect(DetectionResult.csvHeader, [
        'id',
        'farm_profile',
        'timestamp',
        'disease_class',
        'confidence_score',
        'image_path',
        'label',
        'bboxes',
      ]);
    });

    test('a legacy 7-column row (pre-bbox schema) still parses, with empty boundingBoxes', () {
      final legacyRow = [1, 'Farm', DateTime.now().toIso8601String(), 'x', 0.5, '', 'lowMatch'];
      final restored = DetectionResult.fromCsvRow(legacyRow);
      expect(restored.boundingBox, isNull);
      expect(restored.boundingBoxes, isEmpty);
      expect(restored.farmProfile, 'Farm');
    });

    test('a v1 11-column row (bbox_left/top/width/height) still parses into 1 box', () {
      // Simulates an old CSV row with the 4-column bbox format.
      final v1row = [1, 'Farm', DateTime.now().toIso8601String(), 'x', 0.5, '', 'presumptivePositive',
          '0.1', '0.2', '0.3', '0.4'];
      final restored = DetectionResult.fromCsvRow(v1row);
      expect(restored.boundingBoxes.length, 1);
      expect(restored.boundingBox!.left, 0.1);
    });

    test('an unrecognized label string falls back to lowMatch rather than throwing', () {
      final row = [1, 'Farm', DateTime.now().toIso8601String(), 'x', 0.5, '', 'not_a_real_label'];
      final restored = DetectionResult.fromCsvRow(row);
      expect(restored.label, DetectionLabel.lowMatch);
    });
  });
}
