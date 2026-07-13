import 'package:flutter_test/flutter_test.dart';
import 'package:tilapiavision/data/models/detection_result.dart';

/// These tests exercise the CSV row <-> DetectionResult conversion
/// directly (no file I/O, no path_provider plugin needed), which is
/// the part of CsvStore most worth getting exactly right: get this
/// wrong and every history entry silently corrupts.
void main() {
  group('DetectionResult CSV round-trip', () {
    test('toCsvRow -> fromCsvRow preserves all fields', () {
      final original = DetectionResult(
        id: 7,
        farmProfile: 'Doongan Grow-Out Pond',
        timestamp: DateTime.parse('2026-07-08T14:30:00.000'),
        diseaseClass: 'hemorrhagic_ulcer',
        confidenceScore: 0.87,
        imagePath: '/data/visual_archive/12345.jpg',
        label: DetectionLabel.presumptivePositive,
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

    test('row order matches csvHeader exactly', () {
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
      ]);
    });

    test('an unrecognized label string falls back to lowMatch rather than throwing', () {
      final row = [1, 'Farm', DateTime.now().toIso8601String(), 'x', 0.5, '', 'not_a_real_label'];
      final restored = DetectionResult.fromCsvRow(row);
      expect(restored.label, DetectionLabel.lowMatch);
    });
  });
}
