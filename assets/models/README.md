# Model assets

This folder is where the trained, quantized model gets placed once
Sprint 5 (Coding and Model Training) produces it.

Expected file: `best_int8.tflite`

Until then, this folder stays empty (aside from this note) — the app
runs entirely on `MockDetectionEngine` and never looks in here. See:

- `lib/services/detection/tflite_detection_engine.dart` for the
  integration checklist.
- `README.md` (project root) for the full build-now/integrate-later
  explanation.

Because trained model files are large binaries, `.gitignore` excludes
`*.tflite` from this folder by default — decide deliberately whether
to track the final model in git directly or via Git LFS once it
exists.
