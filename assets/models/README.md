# Model assets

Place the trained, quantized model here once Sprint 5 finishes:

```
assets/models/best_int8.tflite
```

This directory is already registered in `pubspec.yaml`'s `assets:`
list, so no pubspec change is needed when the file lands — just drop
it in and follow the integration checklist at the top of
`lib/services/detection/tflite_detection_engine.dart`.
