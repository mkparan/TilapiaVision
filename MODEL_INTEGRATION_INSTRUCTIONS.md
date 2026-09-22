# Installing the Two Trained Models

The app is model-ready. It builds and runs right now **without** any
`.tflite` files — it will simply tell you the model isn't installed
when you try to scan. Follow this once the Colab notebooks have
produced the model files.

---

## Step 1 — Copy both files in

```
assets/models/
  best_int8.tflite               <- disease detector (~2.9 MB)
  tilapia_verifier_int8.tflite   <- species verifier (~2.6 MB)
```

Both come from `/content/drive/MyDrive/TilapiaVision/app_ready_model/`
in Google Drive.

**Filenames must match exactly.** They're hardcoded:
- `lib/services/detection/tflite_detection_engine.dart` → `_modelAssetPath`
- `lib/services/verification/tflite_tilapia_verifier.dart` → `_modelAssetPath`

No `pubspec.yaml` change needed — the whole `assets/models/` folder is
already registered.

## Step 2 — Full rebuild, not hot reload

```bash
flutter clean
flutter pub get
flutter run
```

**A hot reload will not pick up a newly added asset.** If the app still
says the model isn't installed after you've copied the files in, this
is almost always why.

## Step 3 — Confirm the tensor shapes on first run

`initialize()` prints the real shapes to the debug console:

```
TFLiteDetectionEngine — input shape:  [1, 3, 640, 640]
TFLiteDetectionEngine — output shape: [1, 5, 8400]
```

Compare against what you expect:

| Model | Expected input | Expected output |
|---|---|---|
| Disease detector | `[1, 3, 640, 640]` float32 | `[1, 5, 8400]` float32 |
| Species verifier | `[1, 224, 224, 3]` uint8 | `[1, 1]` uint8 |

**If the detector input prints `[1, 640, 640, 3]` instead**, your export
produced channels-last and the preprocessing code in `analyze()` needs
its axis order flipped. The app will not crash in that case — it will
produce nonsense boxes, which is much harder to spot. Check this on the
first run.

**If the output is `[1, 6, 8400]`**, your model has two classes
(Option A), not one. The parsing code assumes 5 rows = 4 box values +
1 score. Two classes needs a different parse.

## Step 4 — The species verifier's dequantization values

The verifier output is uint8 and must be dequantized. Get the exact
values from Colab:

```python
import tensorflow as tf
p = "/content/drive/MyDrive/TilapiaVision/app_ready_model/tilapia_verifier_int8.tflite"
i = tf.lite.Interpreter(model_path=p); i.allocate_tensors()
print("OUTPUT:", i.get_output_details()[0]['quantization'])
```

Then confirm `tflite_tilapia_verifier.dart` uses them:

```
probability = (raw_byte - zero_point) * scale
>= 0.5 means tilapia
```

## Step 5 — Test these five cases on a real device

1. **Diseased tilapia** → boxes drawn, "Presumptive Positive"
2. **Healthy tilapia** → passes the gate, no boxes
3. **Your hand / a bucket** → stopped with "not a tilapia"
4. **A different tilapia species** → also stopped
5. **Save to Gallery from a history entry** → the saved image **has every box burned in**

Case 3 is your panel demo. Case 5 was a real bug — verify it.

---

## Thresholds — already changed, read this before you tune

`lib/core/constants.dart` was recalibrated:

| | Was | Now | Why |
|---|---|---|---|
| `confidenceFloor` | 0.50 | **0.25** | Real detections peak ~0.503; the old floor discarded nearly everything before NMS |
| `operatingThreshold` | 0.70 | **0.40** | 0.70 was unreachable — every positive rendered as "Low Match" and "Presumptive Positive" could never appear |

These are provisional values chosen to make the pipeline functional.
They still need a formal calibration pass against the validation set.

The direction is deliberate and worth stating in your defense: for
disease screening, a missed infection costs the farmer far more than an
unnecessary check, so the thresholds err toward catching more cases.

---

## If something goes wrong

| Symptom | Cause |
|---|---|
| "Model is not installed yet" after copying files | Hot reload instead of full rebuild → `flutter clean` and re-run |
| Boxes in nonsense positions | Channels-first/last mismatch — see Step 3 |
| Everything rejected as "not a tilapia" | Wrong dequantization values in the verifier — see Step 4 |
| Nothing ever detected | Threshold still too high — try `confidenceFloor` 0.15 temporarily to confirm the model produces anything |
| Native crash: "Input tensor N lacks data" | The XNNPack delegate isn't applied. Both engines set it in `initialize()`; check it wasn't removed |
