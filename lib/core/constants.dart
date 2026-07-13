/// Central place for tunable detection parameters.
///
/// IMPORTANT — algorithm order: these three values are applied in a
/// fixed sequence to every raw model prediction, and that order
/// matters:
///   1. [confidenceFloor] — discard any candidate box below this
///      score BEFORE anything else runs. This is noise rejection,
///      not a decision.
///   2. [nmsIouThreshold] — among surviving boxes, Non-Max
///      Suppression collapses duplicate/overlapping boxes around the
///      same lesion down to one, using this IoU threshold.
///   3. [operatingThreshold] — of what's left, this is the line that
///      separates "Presumptive Positive" from "Low Match" for the UI.
///
/// [operatingThreshold] is a PLACEHOLDER until Sprint 5's empirical
/// calibration (Chapter 3, Section 3.9 of the proposal) determines
/// the real value. Update this constant — nothing else — once that
/// number is known.
///
/// TERMINOLOGY: none of these values are "accuracy." Accuracy,
/// mAP@50, and Recall are dataset-level evaluation statistics
/// computed once, offline, across a held-out test set — never
/// something this app calculates at runtime. What the app produces
/// per scan is a confidence score for a single prediction. Keep that
/// distinction in any UI copy, code comment, or panel-facing
/// documentation — the two terms are not interchangeable.
class DetectionConfig {
  DetectionConfig._();

  /// Pre-NMS confidence floor. Detections below this are discarded
  /// before Non-Max Suppression ever runs. Fixed by design, not tuned.
  static const double confidenceFloor = 0.50;

  /// IoU threshold used during Non-Max Suppression to collapse
  /// duplicate boxes around the same lesion.
  static const double nmsIouThreshold = 0.70;

  /// Operating threshold that separates "Presumptive Positive" from
  /// "Low Match". PLACEHOLDER — replace after Sprint 5 calibration.
  static double operatingThreshold = 0.70;

  /// Hard cap on how long inference is allowed to run before the UI
  /// gives up and shows a timeout state.
  static const Duration inferenceTimeout = Duration(milliseconds: 4000);

  /// Target end-to-end latency budget (capture -> result on screen).
  static const Duration targetLatency = Duration(milliseconds: 3000);

  /// How long a cached detection photo is kept on disk before the
  /// Visual Archive treats it as expired (Section 3.3).
  static const int imageRetentionDays = 30;

  /// Rough on-disk size cap per cached photo, per Section 1.5.1.
  static const int maxImageBytes = 200 * 1024;
}
