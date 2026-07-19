# TilapiaVision — App Project Template (v2.3)

An offline mobile app for presumptive screening of hemorrhagic lesions
in Nile Tilapia, built with Flutter. **This revision wires up real,
on-device YOLO11n inference** — the app no longer runs on simulated
results by default. Drop your exported model into
`assets/models/`, and the app is ready to test against it.

**This version's setup section has been rewritten end-to-end after a
real first-install run surfaced several Android toolchain issues.**
Every step below is verified against an actual successful build, not
just the standard Flutter docs — follow it in order and you should
avoid the whole ordeal.

---

## What Changed in This Revision

| Area | v1 | v2 | v2.1 | v2.2 | v2.3 |
|---|---|---|---|---|---|
| Local storage | SQLite (`sqflite`) | **Flat CSV log** (`csv` package) + cached images | — | — | — |
| Export | None | **Export CSV** button on History (native share sheet) | — | **+ per-record export** (photo + text summary) from the new detail screen | — |
| Icons | Material Icons | **Lucide Icons** (`lucide_icons_flutter`) throughout | — | — | — |
| Typography | System default | Google Fonts — Plus Jakarta Sans (headings) + Inter (body) | — | — | — |
| Visual style | Bordered cards | Soft-shadow cards, no hard borders, more whitespace | — | — | — |
| `tflite_flutter` | — | `^0.11.0` | **`^0.12.1`** — fixes an AGP namespace collision | — | — |
| Camera screen | Static flash icon (non-functional) | — | — | **Real flash/torch toggle**, top-left icon replaced with an "Offline" status pill, **gallery picker button** added beside the shutter | — |
| History screen | List only | — | — | Cards are now **tappable → detail screen** with delete + export; **30-day retention notice** banner added | — |
| Image cleanup | `clearExpiredImages()` defined but never called | — | — | **Now actually runs** on app startup | — |
| Setup docs | Basic | Basic | Full real-world Android setup path | — | — |
| Detection engine | — | `MockDetectionEngine` (fake, active by default) | — | — | **`TFLiteDetectionEngine` is now the active engine — real inference, not simulated.** The old mock engine is renamed `SimulatedDetectionEngine` and demoted to test-only use. |

**Why drop SQLite?** The panel's feedback was correct: this app never
does anything a relational database is for. There's one table, no
foreign keys, no joins, and exactly one query pattern ("give me every
row, newest first"). A CSV file does that with a fraction of the code
— and as a direct bonus, it doubles as the export format
farmers/researchers actually want, since it opens in Excel or Google
Sheets with zero conversion step. See
`lib/data/local/csv_store.dart` for the implementation.

---

## Prerequisites

- **Flutter SDK** 3.19 or newer (`flutter --version` to check)
- **Android Studio** (for the Android SDK/emulator) or a physical
  Android device with USB debugging enabled
- A code editor with Flutter support — Android Studio or VS Code with
  the Flutter extension both work well

If you don't have Flutter installed yet, follow the official
installer for your OS: <https://docs.flutter.dev/get-started/install>

Run `flutter doctor` and resolve everything it flags **before**
continuing — specifically:

- **`Android toolchain` shows `cmdline-tools component is missing`:**
  Open Android Studio → **More Actions → SDK Manager → SDK Tools tab**
  → check **Android SDK Command-line Tools (latest)** → Apply.
- **`Android license status unknown`:** run
  `flutter doctor --android-licenses` and accept each one.
- **`Visual Studio` warnings on Windows:** ignore these — that
  checkmark is only for building Windows desktop apps, irrelevant to
  this Android project.

---

## Setup

```bash
# 1. From the project root, fetch all dependencies
flutter pub get

# 2. Generate the Android platform folder (NOT included in this
#    template on purpose — generated code doesn't belong hand-written
#    into a starting scaffold). This is a required step; skipping it
#    is the #1 cause of "no supported devices" on first run.
flutter create --platforms=android .
```

**Now, before your first `flutter run`, apply the Gradle settings
below** — this is the exact `android/gradle.properties` configuration
that took this project from repeatedly failing to actually building,
verified against a real successful install. Skipping this and hoping
for the best is how that whole ordeal happened in the first place.

Open `android/gradle.properties` and add these three lines:
```properties
kotlin.jvm.target.validation.mode=warning
org.gradle.parallel=false
kotlin.incremental=false
```

**Why each one is needed:**

- **`kotlin.jvm.target.validation.mode=warning`** — three plugins
  this app depends on (`tflite_flutter`, `share_plus`,
  `shared_preferences_android`) don't consistently declare their
  Java/Kotlin compile targets, and current Android Gradle Plugin
  treats any mismatch as a hard build failure by default. This
  downgrades that specific check to a warning instead.
- **`org.gradle.parallel=false`** and **`kotlin.incremental=false`**
  — prevent a Kotlin incremental-compilation daemon cache corruption
  ("Storage for [...] is already registered") that surfaces when
  multiple modules compile concurrently under this same dependency
  set. Builds are a little slower with these off; that's a small,
  known trade for a build that actually completes.

See
[Known Android Toolchain Setup Issues](#known-android-toolchain-setup-issues)
below for the full story on each of these, including the several
things that were tried first and didn't work.

Then:
```bash
# 3. Confirm a device is available (emulator or physical phone)
flutter devices

# 4. Run the app
flutter run
```

No API keys, no backend, no accounts to configure beyond the Android
SDK setup above. The app itself is fully offline by design.

### Running the tests

```bash
flutter test
```

This runs two suites:
- `test/widget_test.dart` — exercises every `SimulatedDetectionEngine`
  outcome (Presumptive Positive, Low Match, Clear, Timeout).
- `test/csv_store_test.dart` — verifies the CSV row ↔ `DetectionResult`
  conversion round-trips exactly, including the null-`imagePath` edge
  case and unrecognized-label fallback.

### Camera on emulators

Android emulators can emulate a camera, but you may need to set the
emulator's camera source to "Webcam0" (or similar) in the AVD's
extended controls. On a physical device this isn't an issue. If no
camera is available at all, `CameraCaptureScreen` falls back to a
placeholder viewfinder so the rest of the UI stays testable.

---

## Known Android Toolchain Setup Issues

Everything in this section was hit and resolved during an actual
first-time setup on Windows with a fresh Android Studio install.
None of these are bugs in this template's Dart code — they're all
Android/Gradle/JDK toolchain friction that's easy to lose hours to if
you don't know the shape of the fix already. Documented here so
nobody has to rediscover them.

### "NDK ... did not have a source.properties file"

```
[CXX1101] NDK at .../sdk/ndk/28.2.13676358 did not have a source.properties file
```

Caused by a corrupted/interrupted NDK download (antivirus scanning
mid-download is a common culprit on Windows). Fix:

```bash
rm -rf "/c/Users/<you>/AppData/Local/Android/sdk/ndk/28.2.13676358"
flutter run
```

Gradle will detect the missing NDK and re-download it automatically.
If it doesn't, reinstall it manually via Android Studio's SDK
Manager → SDK Tools → check "Show Package Details" → NDK (Side by
side) → reinstall.

### "Inconsistent JVM Target Compatibility Between Java and Kotlin Tasks"

```
Inconsistent JVM-target compatibility detected for tasks
'compileDebugJavaWithJavac' (1.8) and 'compileDebugKotlin' (21).
```

This is the one already fixed by the `kotlin.jvm.target.validation.mode=warning`
line in the [Setup](#setup) section above. If you're reading this
because you skipped that step or it got lost (e.g. you re-ran
`flutter create .` and it overwrote your `gradle.properties`), just
re-add that line and re-run.

**Why it happens at all:** `tflite_flutter`, `share_plus`, and
`shared_preferences_android` don't all declare consistent Java/Kotlin
compile targets internally. Recent Android Gradle Plugin (8.0+)
treats any such mismatch as a build-breaking error by default, where
older AGP only warned. The validation-mode setting restores the
old (non-fatal) behavior for this specific check.

We initially tried to fix this by forcing a consistent JVM target
across all subprojects via custom Gradle config — multiple different
approaches, all eventually broke something else (crashed on Gradle's
`Property` finalization lifecycle, or silently failed to take effect,
or in one case stripped the Android SDK classpath from
`permission_handler_android` entirely). The `validation.mode=warning`
property is the correct fix precisely because it doesn't try to force
consistency at all — it just stops treating the (harmless, in this
case) inconsistency as fatal.

### "Storage for [...] is already registered" / "Could not close incremental caches"

A Kotlin incremental-compilation daemon cache corruption. It shows up
after multiple modules compile concurrently under this dependency
set, and gets worse the more failed builds accumulate, since the
daemon is a separate long-lived process from Gradle itself and
doesn't get reset by `flutter clean` alone.

**This is already prevented by the `org.gradle.parallel=false` and
`kotlin.incremental=false` lines in the [Setup](#setup) section** —
if you added those, you shouldn't see this at all. If you're reading
this because you skipped that step, or because a corrupted cache
already built up before you added those lines, clear it out first:

```bash
cd android
./gradlew --stop
cd ..
taskkill //F //IM java.exe //T   # Windows; kills the stale daemon process
flutter clean
rm -rf build
rm -rf android/build
```

Then confirm `android/gradle.properties` has both lines from
[Setup](#setup) and run `flutter run` again.

### "Namespace ... is used in multiple modules and/or libraries" (tensorflow-lite)

```
Namespace 'org.tensorflow.lite' is used in multiple modules and/or
libraries: org.tensorflow:tensorflow-lite:2.11.0, ...-gpu:2.11.0, ...-api:2.11.0
```

Already fixed in this template's `pubspec.yaml` — `tflite_flutter` is
pinned to `^0.12.1`, not `^0.11.0`. The older version pulls in a
TensorFlow Lite release where three native artifacts all declare the
same Android namespace, which current AGP rejects outright. If you
ever see this again after changing that dependency, bump
`tflite_flutter` forward again and re-run `flutter pub get`.

### `./gradlew` says "JAVA_HOME is not set"

Only relevant if you run `gradlew` directly (e.g. `./gradlew --stop`
above) rather than through `flutter run`/`flutter clean`. Flutter's
own commands use their own internal JDK detection and don't need
`JAVA_HOME` set in your shell — this error is harmless in that
context and doesn't indicate a real problem.

### General troubleshooting order, if something new comes up

1. `flutter clean && rm -rf build android/build`
2. `cd android && ./gradlew --stop && cd ..`
3. `flutter pub get`
4. `flutter run`

If a fresh build still fails after that sequence, the error is very
likely genuinely new — paste the **first** error in the log (the
real one is often buried under a long stack trace of downstream
symptoms) rather than the whole output.

---

## Project Structure

```
tilapiavision_app/
├── pubspec.yaml                       # Dependencies — see below
├── analysis_options.yaml
├── .gitignore
├── README.md                          # This file
├── assets/
│   └── models/
│       └── README.md                  # Placeholder — trained model goes here later
├── test/
│   ├── widget_test.dart               # SimulatedDetectionEngine outcome tests
│   └── csv_store_test.dart            # CSV round-trip tests
└── lib/
    ├── main.dart                       # App entry point, provider wiring
    ├── core/
    │   ├── app_theme.dart              # Ocean Gradient palette + Google Fonts ThemeData
    │   └── constants.dart              # DetectionConfig (thresholds, timeouts)
    ├── data/
    │   ├── models/
    │   │   ├── detection_result.dart   # DetectionResult, BoundingBox, DetectionLabel
    │   │   │                           #   + toCsvRow()/fromCsvRow()
    │   │   └── farm_profile.dart
    │   ├── local/
    │   │   └── csv_store.dart          # ← replaces the old database_helper.dart
    │   └── repositories/
    │       ├── detection_repository.dart
    │       └── farm_profile_repository.dart   # SharedPreferences-backed (unchanged)
    ├── services/
    │   ├── detection/
    │   │   ├── i_detection_engine.dart          # Strategy interface
    │   │   ├── tflite_detection_engine.dart     # ← the app runs on this — real inference
    │   │   └── simulated_detection_engine.dart  # ← test-only, not used by the running app
    │   ├── verification/
    │   │   ├── i_tilapia_verifier.dart
    │   │   └── stub_tilapia_verifier.dart      # ← always returns true for now
    │   └── storage_service.dart                # Image caching + 30-day expiry
    └── presentation/
        ├── providers/
        │   ├── detection_provider.dart          # Orchestrates a scan + CSV export
        │   └── farm_profile_provider.dart
        ├── app_shell.dart                       # Bottom nav: Scan / History / Tips
        ├── screens/
        │   ├── onboarding/
        │   │   ├── disclaimer_gate_screen.dart
        │   │   └── farm_profile_setup_screen.dart
        │   ├── capture/
        │   │   └── camera_capture_screen.dart
        │   ├── result/
        │   │   └── result_screen.dart           # Handles all scan outcomes
        │   ├── history/
        │   │   ├── detection_history_screen.dart   # + Export CSV button, tappable cards
        │   │   └── detection_detail_screen.dart     # Per-record view: delete + export
        │   └── biosecurity/
        │       └── biosecurity_tips_screen.dart
        └── widgets/
            └── bounding_box_painter.dart
```

Note: `android/` and `ios/` are **not** included in this zip — you
generate them yourself with `flutter create --platforms=android .`
(see [Setup](#setup)). This is deliberate: generated platform
scaffolding doesn't belong hand-maintained in a code template, and
keeping it out avoids this template silently going stale against
whatever Flutter/AGP version you actually have installed.

---

## Camera Screen Controls

- **Flash/torch toggle** (top-right) actually works now — it wasn't
  wired to anything in an earlier pass. It toggles `FlashMode.torch`
  (a steady fill light) rather than a one-shot flash burst, since a
  steady light is easier to frame a close-up capture under. The icon
  fills amber when active.
- **"Offline" status pill** (top-left) replaced what used to be a
  shortcut to Biosecurity Tips (redundant with the bottom tab bar
  anyway). It's a static label for now — see the doc comment in
  `camera_capture_screen.dart` for how to make it reflect real model
  load state once `TFLiteDetectionEngine` exists.
- **Gallery button** (bottom-left, beside the shutter) opens the
  system photo picker via `image_picker` and runs the picked image
  through the exact same `ResultScreen` flow as a fresh camera
  capture — no separate code path to maintain.

## Detection History & Detail

- History cards are tappable and open `DetectionDetailScreen`,
  showing the full photo (or the expired-archive fallback), every
  stored field, and two actions:
  - **Delete** — asks for confirmation, then permanently removes the
    row from the CSV log via `CsvStore.deleteById`.
  - **Export** — shares the cached photo *and* a text summary
    together in one share-sheet action (`DetectionProvider.exportSingleDetection`).
    If the photo has already expired, it falls back to a text-only
    share rather than failing.
- A retention notice banner at the top of the History screen states
  the 30-day photo deletion policy explicitly. This is now backed by
  real behavior, not just UI copy — see the next section.

## The 30-Day Photo Cleanup Is Now Actually Wired Up

`StorageService.clearExpiredImages()` existed since the first CSV
revision but was never called from anywhere — a real gap, found while
adding the retention notice banner to the History screen (writing UI
copy that claims a behavior is a good way to notice the behavior
doesn't exist yet). It now runs as a fire-and-forget call in `main()`
on every app launch. A failure there is caught and swallowed
deliberately — cleanup is best-effort and should never block startup.

---



`lib/data/local/csv_store.dart` maintains a single append-only file,
`detection_log.csv`, in the app's private documents directory.

**Columns** (see `DetectionResult.csvHeader`):

```
id, farm_profile, timestamp, disease_class, confidence_score, image_path, label
```

**How it works:**
- On first launch, the file is created with just the header row.
- Every saved detection appends one row (`CsvStore.insert`) —
  `id` auto-increments by reading the current max `id` in the file.
- Reading (`CsvStore.getAll`) parses the whole file and sorts newest
  first — perfectly fine at the scale this app operates at (a
  farmer's own scan history, not a shared multi-user dataset).
- **Export** (`DetectionProvider.exportCsv`) doesn't generate a
  separate file — it hands the *live* CSV straight to the OS share
  sheet via `share_plus`. What you export is exactly what's stored,
  by construction.
- Photos are cached separately as compressed JPEGs and referenced by
  path in the `image_path` column. Low Match results are
  intentionally never written to the CSV at all — see
  [Design Decisions](#design-decisions-worth-knowing) below.

---

## Model Integration — Ready Now

**The real model integration is done — this isn't a "wire it up
later" checklist anymore.** `TFLiteDetectionEngine`
(`lib/services/detection/tflite_detection_engine.dart`) is a full,
working implementation, and `main.dart` uses it by default. What's
left is genuinely just:

```bash
# 1. Drop your exported model in place (filename must match, or
#    update _modelAssetPath in tflite_detection_engine.dart)
cp your_model.tflite assets/models/best_int8.tflite

# 2. Run the app
flutter run
```

That's it — no code changes required for a standard export. Read on
for exactly what "standard" means here and how to verify it.

### What the real engine actually does

1. Loads the model via `Interpreter.fromAsset`, wrapped in an
   `IsolateInterpreter` so inference runs off the main thread (this
   is the literal "Dart Isolate for inference" from your tech stack —
   not just a name, the actual mechanism).
2. **Reads the model's real input/output tensor shape and type at
   load time** — it does not hardcode an input resolution or assume
   float32 vs. quantized. Whatever your export actually is, the
   preprocessing and dequantization logic adapts to it automatically.
3. Preprocesses the captured photo: decode → resize to the model's
   actual input size → normalize (0–1 float, or raw pixel values if
   the input tensor is uint8/int8 — determined dynamically, not
   guessed).
4. Runs inference, then decodes the raw output through the exact
   pipeline your methodology describes: **confidence floor → Non-Max
   Suppression → operating threshold** (see below).

### The one assumption that can't be introspected — verify this

Tensor shape and quantization are read from the model file itself, so
those adapt automatically. **The output *layout* can't be — TFLite
doesn't encode "this is a YOLO detection head" anywhere in the file.**
This implementation assumes a single-class, raw Ultralytics-style
output (a tensor with one dimension of size 5 — 4 box values + 1
class confidence — and the other equal to the anchor count, NMS *not*
baked into the graph). This is Ultralytics' default TFLite export
behavior, and it matches your own methodology's separate NMS step, so
it's the reasonable default assumption — but it's still an assumption
about a file I've never seen.

**First thing to do when you drop the model in:** run the app, make
one capture, and check the console output. `initialize()` logs a line
like:
```
TFLiteDetectionEngine loaded — input: shape=[1, 640, 640, 3] type=float32 | output: shape=[1, 5, 8400] type=float32.
```
Compare that against what you know about your own export (input size,
whether you used `nms=True`). If the output shape doesn't look like
"one dimension is 5, the other is a few thousand," the output-parsing
assumption above is wrong for your file, and `_parseOutput()` in
`tflite_detection_engine.dart` is the one place to adjust it — the
rest of the pipeline (floor → NMS → threshold → `DetectionResult`)
doesn't need to change.

### The detection algorithm — order of operations

This is the part the panel asked to have double-checked, so it's
documented explicitly in `lib/core/constants.dart`, in
`tflite_detection_engine.dart`, and repeated here. Every raw model
prediction is processed in this fixed order:

1. **Confidence floor (0.50)** — discard any candidate box below this
   score during output parsing. This is noise rejection, not a
   decision.
2. **Non-Max Suppression (IoU 0.70)** — among surviving boxes, collapse
   duplicate/overlapping boxes around the same lesion down to one.
   Implemented as a real greedy IoU-based algorithm in
   `TFLiteDetectionEngine._nonMaxSuppression` — this only had
   somewhere to run once real (non-simulated) multi-box output
   existed, which is why it's new in this revision.
3. **Operating threshold (placeholder 0.70)** — of what's left, this
   line separates *Presumptive Positive* from *Low Match* for the UI.
   **This is still a placeholder** until your Sprint 5 empirical
   calibration (Chapter 3, Section 3.9) determines the real number —
   update `DetectionConfig.operatingThreshold` and nothing else when
   that happens. Wiring up the real model didn't remove this
   dependency; calibration is a separate, later step.

**Terminology, precisely:** nothing in this app displays an
"accuracy" figure at runtime. `DetectionResult.confidenceScore` is a
single prediction's confidence — a per-scan number. Accuracy, mAP@50,
and Recall are dataset-level evaluation statistics computed once,
offline, across a held-out test set during model development. They
are never something the app itself calculates. This distinction is
enforced in the code's doc comments so it doesn't quietly blur in UI
copy later.

### Testing without a device handy

`SimulatedDetectionEngine` (`lib/services/detection/simulated_detection_engine.dart`)
still exists, purely for `flutter test` — it lets the automated suite
exercise every Result-screen branch deterministically without needing
a loaded model or camera hardware. It is **not** used by the running
app; `main.dart` wires up `TFLiteDetectionEngine` unconditionally.
If you ever want to force a specific outcome for manual UI testing
without a model loaded, you'd temporarily swap the engine in
`main.dart` — but that's a deliberate, visible one-line change now,
not the default behavior.

### The Tilapia Verification Gate — separate, still open

The two-stage pipeline's *first* stage (confirming the subject is a
Nile Tilapia before disease detection runs) is a different model from
the one this section covers, and remains a stub
(`StubTilapiaVerifier`, always returns `true`). Nothing in this
revision changes that — see that class's doc comment for the
recommended next step (a small MobileNetV2 binary classifier) if/when
that model exists too.

---

## Design Decisions Worth Knowing

- **State management: Provider**, not Bloc/Riverpod — the app's
  state is simple and linear (one scan result at a time, one Farm
  Profile), and Provider keeps the learning curve low for a small
  team on a deadline.
- **CSV, not SQLite** — see [What Changed](#what-changed-in-this-revision)
  above. Screens never touch the CSV file directly, only
  `DetectionRepository`.
- **Low Match results are never written to the log.** They render a
  UI-only prompt; only Presumptive Positive and Clear results get
  cached to the Visual Archive and appended to `detection_log.csv`.
  This also means Low Match scans don't show up in an exported CSV —
  intentional, since they're not a confirmed reading.
- **Colors are deliberately not alarmist.** Presumptive Positive uses
  amber, not red, to discourage panic-driven antibiotic misuse — a
  specific usability consideration from the proposal, not an
  arbitrary style choice.
- **Icons: Lucide, not Material.** Every icon in the app resolves to a
  verified-existing identifier in `lucide_icons_flutter` — see the
  in-code `import 'package:lucide_icons_flutter/lucide_icons.dart';`
  at the top of any screen file for the exact API.
- **Typography: Google Fonts (Plus Jakarta Sans + Inter).** Loaded via
  `google_fonts`, which downloads and caches the font file on first
  use — no manual font asset bundling required.

---

## Known Gaps in This Template

This is a starting scaffold, not a finished app. Things intentionally
left for you to build next:

- A real `ITilapiaVerifier` implementation — the verification gate
  remains a stub (`StubTilapiaVerifier`, always returns `true`); see
  [Model Integration](#model-integration--ready-now) for why this is
  a separate model from the one this revision wires up.
- Runtime camera/storage permission request flow (the `camera` plugin
  handles the OS permission prompt on first use, but you may want a
  friendlier pre-permission explainer screen).
- A "Clear History" action (the repository already exposes
  `clearAll()` — it just isn't wired to a button yet).
- App icon, splash screen, and store listing assets.
- A real Android `applicationId` — `flutter create` defaults to
  `com.example.tilapiavision`; change this in
  `android/app/build.gradle.kts` before any real release build or
  Play Store submission.

---

## Reference Documents

This template was generated to match:
- The **App Development Masterplan** (parallel-track strategy, sprint
  timeline, package choices)
- The **TilapiaVision Concept Deck** (system architecture, technology
  stack)
- The **high-fidelity UI/UX prototype** (screen flow and copy this
  codebase implements)

Keep those in sync with this code as the project evolves — if a
screen's copy or flow changes here, update the prototype too (or vice
versa) so panel reviewers see one consistent story. Note the
prototype and deck currently describe the pre-revision (SQLite)
architecture in a couple of spots (e.g. the "Local Data Layer" slide)
— worth a quick pass to reflect the CSV switch before your next
panel session.
