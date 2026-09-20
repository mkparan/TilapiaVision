import 'package:flutter_test/flutter_test.dart';
import 'package:tilapiavision/core/tap_sequence.dart';

void main() {
  final t0 = DateTime(2026, 9, 19, 12);
  DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

  test('seven quick taps complete the sequence on the seventh', () {
    final seq = TapSequence(length: 7);
    final remaining = [for (var i = 0; i < 7; i++) seq.tap(at(i * 300))];
    expect(remaining, [6, 5, 4, 3, 2, 1, 0]);
  });

  test('fewer taps than required never completes', () {
    final seq = TapSequence(length: 7);
    for (var i = 0; i < 6; i++) {
      expect(seq.tap(at(i * 200)), isNot(0));
    }
  });

  test('a pause longer than the window starts the count over', () {
    final seq = TapSequence(length: 7);
    for (var i = 0; i < 5; i++) {
      seq.tap(at(i * 300));
    }
    // 3 s after the last tap: longer than the 2 s window.
    expect(seq.tap(at(4 * 300 + 3000)), 6);
  });

  test('a pause exactly equal to the window does not reset the count', () {
    final seq = TapSequence(length: 3, window: const Duration(seconds: 2));
    seq.tap(at(0));
    expect(seq.tap(at(2000)), 1);
  });

  test('the counter resets after completing, so it can be used again', () {
    final seq = TapSequence(length: 3);
    seq.tap(at(0));
    seq.tap(at(100));
    expect(seq.tap(at(200)), 0);
    expect(seq.tap(at(300)), 2);
  });
}
