# TilapiaVision — Project Context

Read this first when picking the project up. It records state,
decisions, and the traps that have already cost time.

---

## What this is

Offline Android app for small-scale tilapia farmers in Butuan/Caraga,
Philippines. Photograph a tilapia → get a presumptive screening result for
Motile Aeromonas Septicemia (hemorrhagic lesions).

**Capstone research**, Caraga State University. Positioned explicitly as
a *presumptive triage tool*, never a veterinary diagnosis — that framing
is deliberate and appears throughout the UI copy.

Two models, run in sequence:

1. **Species verifier** (MobileNetV2) — "is this a tilapia?" Runs
   **first**, on every photo.
2. **Disease detector** (YOLO11n) — "where is the lesion?" Runs **only**
   if step 1 says yes.

That order is the answer to the panel question *"what if you scan a
dog?"* — a dog is stopped at step 1 and never reaches the detector.

---

## Current state

### Models

| | Metric | Status |
|---|---|---|
| Species verifier | 94.5% accuracy, tilapia recall 0.956 | **Done — do not retrain** |
| | healthy recall **1.000**, diseased 0.912 | |
| Disease detector | mAP50 **0.617** float / **0.517** INT8 | Weak; target was 0.80 |

**Do not put 0.878 anywhere.** An earlier quantization run reported that
number; it came from evaluating a v3-trained model against the v6
dataset, where 87% of the "test set" had been in training. The
quantization notebook now has a fingerprint guard that halts on this.

### App

Both TFLite engines are implemented. `main.dart` wires the real ones.
The app builds and runs **without** model files and reports
`ScanStatus.modelMissing` with instructions rather than crashing.

---

## Decisions already made — do not relitigate

- **YOLO11n, not YOLO11s.** Tested on two datasets; the nano model won
  both times (+0.032, +0.028 mAP50). It's also the size needed for
  budget devices. Model capacity is not the bottleneck.
- **CSV, not SQLite.** Panel feedback. The log is a flat table with no
  joins, and the CSV doubles as the export format.
- **The verifier must accept diseased tilapia.** It gates the detector. If
  it rejects sick tilapia it blocks exactly what the app exists to find.
  Never "clean" diseased tilapia out of its tilapia class.
- **Datasets are compiled from public sources**, not original field
  photography. Describe them that way.

---

## Traps that have already cost time

**1. Channels-first input.** The detector's TFLite input is
`[1, 3, 640, 640]`, not the `[1, 640, 640, 3]` most Flutter examples
assume. Wrong order produces garbage detections with **no error**.

**2. XNNPack delegate is mandatory.** Without it, `tflite_flutter
0.12.1` fails natively with `Input tensor 207 lacks data` inside
`Interpreter.invoke()`. Both engines set it in `initialize()`. Don't
remove it.

**3. Assets need a full rebuild.** Hot reload will not pick up a newly
added `.tflite`. `flutter clean` first.

**4. Dataset version must match the model.** Evaluating a model against
a differently-split dataset causes silent leakage. Verify image counts:
v3 = 2604/195/236, v6 = 1608/160/221.

**5. Bounding boxes are draw-time overlays.** They are not in the stored
photo. Anything that exports an image must composite them first — see
`_renderImageWithBox()` in `detection_provider.dart`.

**6. Shortcut learning in the verifier.** The first version hit 93% in
testing but ~70% in the field: 64.5% of its tilapia examples had lesions
and 0% of its negatives did, so it learned lesions instead of species,
and rejected healthy tilapia. Fixed by rebuilding at exactly 50/50
healthy/diseased. **If you ever rebuild that dataset, keep the balance
and keep reporting healthy vs diseased recall separately.**

---

## Dataset facts worth knowing

- The four original public datasets share **83% of their source photos**
  — they are largely the same recycled pool, re-annotated by different
  people. 27% of recurring specimens had contradictory boxes (up to 15x
  disagreement in labelled area).
- The original compilation held ~209 unique specimens behind 3,035
  images. That diversity limit, not model capacity, capped detector
  performance.
- Three newer datasets (`tilapia-rpql9`, `orig-up`,
  `oreochrom-diseases`) add ~3,042 perceptually distinct specimens.
  **The species verifier uses them. The disease detector does not yet.**

---

## Highest-value work remaining, in order

**1. Retrain the disease detector on the new data.** Two of the three
new datasets arrive already annotated — 2,173 aeromonas boxes, no
labeling needed. The detector is still training on ~209 unique
specimens while ~3,042 sit unused. This is the largest available gain.

When merging: cap the old v6 data to ~3 variants per source photo. It
averages ~8 images per tilapia versus ~1.1 in the new data; without
capping, 207 old tilapia outweigh 1,600 new ones.

**2. Install the models and test on a device.** See
`MODEL_INTEGRATION_INSTRUCTIONS.md`.

**3. Calibrate thresholds properly.** `confidenceFloor` and
`operatingThreshold` currently hold provisional values.

**4. Paper gaps:**
   - Objective 1 (p.7) describes a synthetic Copy-Paste/Poisson-Blending
     pipeline that was never built. Decide: rewrite, or build it.
   - The species-verification methodology exists **only** as one box in
     Figure 3-5 — no written section anywhere. It's the answer to the
     panel's dog question and needs to be in text.
   - Table 3-3 (p.94) still lists 7 CSV columns; the schema has 11.
   - Six datasets need citing — all CC BY 4.0, so attribution is a
     license requirement, not a courtesy.

---

## Architecture notes

- `IDetectionEngine` / `ITilapiaVerifier` are the swap points. Mock and
  TFLite implementations both exist; changing engines is a one-line
  change in `main.dart`.
- `DetectionProvider` orchestrates: verify species → run detector →
  cache image → persist to CSV.
- Low Match results are deliberately **not** saved to history — UI-only
  prompt, so no disk write.
- `ScanStatus` has 7 values. Adding one requires updating the switch in
  `result_screen.dart` or it won't compile.
- **Save to Gallery** (Result screen after a scan, and History detail
  screen) is one shared widget, `SaveToGalleryButton`, backed by
  `DetectionProvider.saveDetectionToGallery` and the `gal` package.
  On the detail screen it is the filled primary button (`filled: true`,
  the old Export button's design and position, next to Delete); on the
  Result screen it stays the outlined full-width button. It saves the
  box-burned-in image plus a caption strip under the photo (farm name,
  result and date; result text in the app's language) into a
  `TilapiaVision` album. The old single-scan Share/Export button (and
  `exportSingleDetection`) was removed on purpose; only the whole-log
  **Export CSV** (`exportCsv`) remains. Android 11+ needs no permission (MediaStore);
  the manifest declares `WRITE_EXTERNAL_STORAGE` capped at
  `maxSdkVersion="29"` plus `requestLegacyExternalStorage` for Android
  10 and older only. `flutter pub get` is needed after pulling this.
- **About screen states the app's scope**: Aeromonas only, Nile Tilapia
  only (`about_scope_*` keys, all three languages).
- **Developer options**: the two threshold sliders (species verifier +
  lesion detector) are hidden in the normal app. Tapping the logo on the
  About screen 7 times in quick succession (`TapSequence`, max 2 s
  between taps; a countdown shows for the last 3 taps) sets
  `SettingsProvider.developerOptionsEnabled`, which is persisted, and
  the sliders appear in Settings under "Developer Options". A Hide
  button there locks them again. Hiding does NOT reset the thresholds;
  saved values keep applying. Event-handler code must not call
  `context.tr` (it uses `context.watch`, only legal during build) — see
  `AboutScreen._onLogoTap` and `SaveToGalleryButton._save` for the
  `AppLocalizations(context.read<LocaleProvider>().locale)` pattern.
- **Multiple bounding boxes per scan (do not revert to a single box).**
  `DetectionResult.boundingBoxes` is a list (highest confidence first);
  `boundingBox` is only a convenience getter for the first one. Each
  `BoundingBox` carries its own `confidence`. `TFLiteDetectionEngine`
  returns every box that survives NMS (confidence floor 0.50, IoU 0.70),
  not just the best one, and logs the candidate count before and after
  NMS plus the top scores. `MultiBoxPainter` (in `bounding_box_painter.dart`)
  draws all of them on the Result screen, the History detail screen and
  the shared / gallery-saved image. The CSV log uses the v2 schema (a
  single `bboxes` JSON column); v1 rows (four `bbox_*` columns) and
  older still load. Two boxes appear only when two lesions are spatially
  distinct (IoU below 0.70) and each scores at or above the 0.50 floor.
