/// Thrown when a `.tflite` file is missing from `assets/models/`.
class ModelMissingException implements Exception {
  const ModelMissingException(this.assetPath, this.modelName);
  final String assetPath;
  final String modelName;
  @override
  String toString() =>
      'The $modelName model is not installed.\n\n'
      'Copy the exported .tflite file to $assetPath, then run\n'
      '"flutter clean && flutter run".\n\n'
      'A hot reload will not pick up a newly added asset.';
}

/// Thrown when a `.tflite` file loaded but the interpreter could not
/// run it (a native invoke failure, not a missing file).
class ModelRunException implements Exception {
  const ModelRunException(this.modelName, this.detail);
  final String modelName;
  final String detail;
  @override
  String toString() =>
      'The $modelName model loaded but failed to run.\n\n$detail';
}
