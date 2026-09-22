/// Thrown when a `.tflite` model file is missing from `assets/models/`.
///
/// The app ships without model files — they are produced by the Colab
/// training/quantization notebooks and copied in during integration.
/// Loading a missing asset otherwise surfaces as an opaque platform
/// exception, which is indistinguishable from a genuine inference
/// failure. This makes the distinction explicit so the UI can tell the
/// user "the model isn't installed yet" instead of "something went
/// wrong".
class ModelNotInstalledException implements Exception {
  const ModelNotInstalledException(this.assetPath, this.modelName);

  /// e.g. 'assets/models/best_int8.tflite'
  final String assetPath;

  /// Human-readable name, e.g. 'disease detector'
  final String modelName;

  @override
  String toString() =>
      'ModelNotInstalledException: the $modelName model was not found at '
      '$assetPath. Copy the exported .tflite file there and rebuild '
      '(a hot reload will not pick up a newly added asset).';
}
