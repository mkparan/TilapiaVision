import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilapiavision/core/constants.dart';
import 'package:tilapiavision/data/models/detection_result.dart';
import 'package:tilapiavision/services/detection/simulated_detection_engine.dart';

/// Drives every test off [SimulatedDetectionEngine] with a forced
/// [SimulatedMode] so each branch of the detection flow is exercised
/// deterministically, with zero dependency on a trained model, a
/// loaded `.tflite` file, or real camera hardware. The running app
/// uses [TFLiteDetectionEngine] instead — see that class.
void main() {
  group('SimulatedDetectionEngine', () {
    test('forcePositive returns a Presumptive Positive above the operating threshold', () async {
      final engine = SimulatedDetectionEngine(mode: SimulatedMode.forcePositive);
      await engine.initialize();

      final result = await engine.analyze(File('test.jpg'), farmProfile: 'Test Farm');

      expect(result.label, DetectionLabel.presumptivePositive);
      expect(result.confidenceScore, greaterThanOrEqualTo(DetectionConfig.operatingThreshold));
      expect(result.boundingBox, isNotNull);
    });

    test('forceLowMatch returns a score between the floor and the operating threshold', () async {
      final engine = SimulatedDetectionEngine(mode: SimulatedMode.forceLowMatch);
      await engine.initialize();

      final result = await engine.analyze(File('test.jpg'), farmProfile: 'Test Farm');

      expect(result.label, DetectionLabel.lowMatch);
      expect(result.confidenceScore, greaterThanOrEqualTo(DetectionConfig.confidenceFloor));
      expect(result.confidenceScore, lessThan(DetectionConfig.operatingThreshold));
    });

    test('forceClear returns no bounding box', () async {
      final engine = SimulatedDetectionEngine(mode: SimulatedMode.forceClear);
      await engine.initialize();

      final result = await engine.analyze(File('test.jpg'), farmProfile: 'Test Farm');

      expect(result.label, DetectionLabel.clear);
      expect(result.boundingBox, isNull);
    });

    test('forceTimeout outlasts the configured inference timeout', () async {
      final engine = SimulatedDetectionEngine(mode: SimulatedMode.forceTimeout);
      await engine.initialize();

      final future = engine.analyze(File('test.jpg'), farmProfile: 'Test Farm').timeout(
            DetectionConfig.inferenceTimeout,
          );

      await expectLater(future, throwsA(isA<Exception>()));
    });
  });
}
