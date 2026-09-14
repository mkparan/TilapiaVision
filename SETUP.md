# TilapiaVision — Setup

This is the original project, patched — not a rewrite. The live
camera, capture flow, onboarding, result screens, and history are
untouched. What changed is listed below.

## 1. Install the models

```
assets/models/best_int8.tflite
assets/models/tilapia_verifier_int8.tflite
```

Then `flutter clean && flutter run`. Hot reload will not pick up a
newly added asset.

## 2. The "Model Failed to Run" fix

Both engines now load via `Interpreter.fromFile` instead of
`Interpreter.fromAsset`. The model is copied to a real file in
temporary storage on first use, then loaded from there.

**Why:** `fromAsset` reads through Android's `AssetManager`, which
can mmap a `.tflite` incorrectly on some builds even with
`noCompress` set — the model *loads* (tensor shapes read correctly
from the header) but *invoke* fails with "Input tensor N lacks data",
because the payload for large tensors reads back short. This matches
your Python-side testing showing the model itself is valid — the
failure was specific to how the file was being loaded on-device, not
the file's contents.

`fromFile` is the most-tested loading path in `tflite_flutter` and
sidesteps the AssetManager entirely.

**Please retest and let me know.** I could not run this on a device
myself, so I can't guarantee this is the final fix — if "Model Failed
to Run" still appears, send me the new console output (it will show
`TFLiteDetectionEngine — input shape:` before the failure either
way) and I'll narrow it further from there.

## 3. What else changed, and where

| Change | File(s) |
|---|---|
| Isolates for preprocessing | `tflite_detection_engine.dart`, `tflite_tilapia_verifier.dart` — `compute()` |
| Verifier threshold 0.5 → 0.85, persisted | `settings_repository.dart`, `settings_provider.dart` |
| Distinct model-missing vs model-failed errors | `model_load_exceptions.dart`, `detection_provider.dart`, `result_screen.dart` |
| Image export now has the box burned in | `detection_provider.dart` — `_renderImageWithBox` |
| 3-dot menu → Settings / About | `biosecurity_tips_screen.dart` |
| Reconfigure farm name | `farm_profile_provider.dart` — `updateName`, used by `settings_screen.dart` |
| Live model-ready check | `settings_screen.dart` — calls `checkVerifierReady()` / `checkDetectorReady()` |

**Nothing about the UI was changed** outside of the additions above —
same camera screen, same palette, same fonts, same layouts.

## 4. Settings persistence, specifically

Every threshold change in Settings calls `SharedPreferences` inside
`SettingsRepository` immediately — not on app close, not on a timer.
Backgrounding or force-quitting the app cannot lose a change. On next
launch, `main.dart` loads the saved values before the app can reach
the scan screen (`_RootRouter` waits on `SettingsProvider.loading`).

## 5. If it still won't compile

`flutter analyze` first. Two things worth knowing:

- `getOutputTensor(0).params` in the verifier reads quantization
  directly from the model rather than hardcoding it. If your
  `tflite_flutter` version names this differently, replace with the
  original hardcoded values: `scale = 0.00390625; zeroPoint = 0;`
- No new pubspec dependency was added — `path_provider` and
  `flutter/services` (for `rootBundle`) were already present.
