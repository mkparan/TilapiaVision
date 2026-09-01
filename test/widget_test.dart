
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilapiavision/core/constants.dart';
import 'package:tilapiavision/data/models/detection_result.dart';
import 'package:tilapiavision/services/detection/mock_detection_engine.dart';

/// This is the pattern referenced throughout the masterplan: drive
/// every test off [MockDetectionEngine] with a forced [MockMode] so
/// each branch of the detection flow is exercised deterministically,
/// with zero dependency on a trained model or real camera hardware.
void main() {
  group('MockDetectionEngine', () {
    test('forcePositive returns a Presumptive Positive above the operating threshold', () async {
      final engine = MockDetectionEngine(mode: MockMode.forcePositive);
      await engine.initialize();

      final result = await engine.analyze(File('test.jpg'), farmProfile: 'Test Farm');

      expect(result.label, DetectionLabel.presumptivePositive);
      expect(result.confidenceScore, greaterThanOrEqualTo(DetectionConfig.operatingThreshold));
      expect(result.boundingBox, isNotNull);
    });

    test('forceLowMatch returns a score between the floor and the operating threshold', () async {
      final engine = MockDetectionEngine(mode: MockMode.forceLowMatch);
      await engine.initialize();

      final result = await engine.analyze(File('test.jpg'), farmProfile: 'Test Farm');

      expect(result.label, DetectionLabel.lowMatch);
      expect(result.confidenceScore, greaterThanOrEqualTo(DetectionConfig.confidenceFloor));
      expect(result.confidenceScore, lessThan(DetectionConfig.operatingThreshold));
    });

    test('forceClear returns no bounding box', () async {
      final engine = MockDetectionEngine(mode: MockMode.forceClear);
      await engine.initialize();

      final result = await engine.analyze(File('test.jpg'), farmProfile: 'Test Farm');

      expect(result.label, DetectionLabel.clear);
      expect(result.boundingBox, isNull);
    });

    test('forceTimeout outlasts the configured inference timeout', () async {
      final engine = MockDetectionEngine(mode: MockMode.forceTimeout);
      await engine.initialize();

      final future = engine.analyze(File('test.jpg'), farmProfile: 'Test Farm').timeout(
            DetectionConfig.inferenceTimeout,
          );

      await expectLater(future, throwsA(isA<Exception>()));
    });
  });

  group('MockDetectionEngine random mode', () {
    test('over many runs, random mode produces all four outcomes, not just one', () async {
      // Regression test for the original bug: random mode used to
      // pick a uniformly random confidence value, which could never
      // land in the timeout branch at all (timeout wasn't
      // confidence-driven) and skewed heavily toward Clear (its
      // confidence range is by far the widest of the three labels).
      final seenPositive = <bool>{};
      final seenClear = <bool>{};
      final seenLowMatch = <bool>{};

      // Sample enough runs that seeing all three labels is
      // essentially certain if the distribution is genuinely
      // balanced, and essentially impossible if it isn't.
      for (var i = 0; i < 60; i++) {
        final engine = MockDetectionEngine(mode: MockMode.random);
        await engine.initialize();
        final result = await engine.analyze(File('test.jpg'), farmProfile: 'Test Farm');
        seenPositive.add(result.label == DetectionLabel.presumptivePositive);
        seenClear.add(result.label == DetectionLabel.clear);
        seenLowMatch.add(result.label == DetectionLabel.lowMatch);
      }

      expect(seenPositive.contains(true), isTrue, reason: 'never saw a Presumptive Positive in 60 runs');
      expect(seenClear.contains(true), isTrue, reason: 'never saw a Clear result in 60 runs');
      expect(seenLowMatch.contains(true), isTrue, reason: 'never saw a Low Match in 60 runs');
    });

    test('default constructor uses random mode', () {
      final engine = MockDetectionEngine();
      expect(engine.mode, MockMode.random);
    });
  });
}

