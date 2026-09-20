/// Counts rapid, consecutive taps — used to unlock developer options by
/// tapping the logo on the About screen.
///
/// Pure Dart on purpose (the caller passes in the time), so the
/// behaviour is unit-testable without a widget tree or a real clock.
class TapSequence {
  TapSequence({
    this.length = 7,
    this.window = const Duration(seconds: 2),
  });

  /// Taps needed to complete the sequence.
  final int length;

  /// Longest allowed pause between two taps. A longer pause starts the
  /// count over.
  final Duration window;

  int _count = 0;
  DateTime? _last;

  /// Registers a tap at [now] and returns how many taps are still
  /// needed. `0` means the sequence has just completed; the counter
  /// resets at that point so it can be used again.
  int tap(DateTime now) {
    final last = _last;
    if (last == null || now.difference(last) > window) {
      _count = 0;
    }
    _last = now;
    _count++;

    if (_count >= length) {
      _count = 0;
      _last = null;
      return 0;
    }
    return length - _count;
  }
}
