# TilapiaVision — Codebase Study Guide

> **Purpose:** A comprehensive reference for navigating every function, class, and file in the TilapiaVision project. Use this to prepare for panel questions about how the app works and where to find each piece of logic.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Directory Structure](#2-directory-structure)
3. [Architecture Diagram](#3-architecture-diagram)
4. [App Entry Point — `main.dart`](#4-app-entry-point--maindart)
5. [Core Layer — `lib/core/`](#5-core-layer--libcore)
6. [Data Layer — `lib/data/`](#6-data-layer--libdata)
7. [Services Layer — `lib/services/`](#7-services-layer--libservices)
8. [Presentation Layer — `lib/presentation/`](#8-presentation-layer--libpresentation)
9. [Detection Pipeline — End-to-End Flow](#9-detection-pipeline--end-to-end-flow)
10. [Key Design Patterns & Decisions](#10-key-design-patterns--decisions)
11. [Quick-Find Index — Every Function by File](#11-quick-find-index--every-function-by-file)
12. [Anticipated Panel Questions & Where to Point](#12-anticipated-panel-questions--where-to-point)

---

## 1. Project Overview

| Field | Value |
|---|---|
| **App Name** | TilapiaVision |
| **Framework** | Flutter (Dart) |
| **Target** | Android (offline, on-device) |
| **Purpose** | Presumptive screening for hemorrhagic lesions (Motile Aeromonas Septicemia) in Nile Tilapia |
| **ML Models** | 2 TFLite models — Species Verifier + YOLO11n Disease Detector |
| **State Management** | Provider (ChangeNotifier) |
| **Local Storage** | CSV flat file (detection log) + SharedPreferences (settings, farm profile) |
| **Languages** | English, Tagalog, Cebuano (Bisaya) |

---

## 2. Directory Structure

```
tilapiavision_app/
├── assets/
│   ├── images/
│   │   └── tilapiavision_logo.png          # App branding logo
│   └── models/
│       ├── best_int8.tflite                # YOLO11n disease detector (quantized INT8)
│       ├── tilapia_verifier_int8.tflite    # Species verification model (quantized INT8)
│       └── README.md
├── lib/
│   ├── main.dart                           # ★ App entry point, splash screen, root router
│   ├── core/                               # Shared constants, theming, localization
│   │   ├── app_localizations.dart          # Trilingual string translations
│   │   ├── app_theme.dart                  # Ocean Gradient color palette + ThemeData
│   │   ├── constants.dart                  # DetectionConfig thresholds & timeouts
│   │   └── tap_sequence.dart               # Dev options Easter-egg counter
│   ├── data/                               # Data models & persistence
│   │   ├── local/
│   │   │   └── csv_store.dart              # Append-only CSV log (the "database")
│   │   ├── models/
│   │   │   ├── detection_result.dart       # DetectionResult, BoundingBox, DetectionLabel
│   │   │   └── farm_profile.dart           # FarmProfile model
│   │   └── repositories/
│   │       ├── detection_repository.dart   # Abstraction over CsvStore
│   │       ├── farm_profile_repository.dart# SharedPreferences-backed profile
│   │       └── settings_repository.dart    # Threshold & dark mode persistence
│   ├── services/                           # ML inference & file management
│   │   ├── detection/
│   │   │   ├── i_detection_engine.dart     # ★ Strategy interface (abstract)
│   │   │   ├── tflite_detection_engine.dart# ★ Real YOLO11n inference + NMS
│   │   │   ├── mock_detection_engine.dart  # Fake engine for UI dev/testing
│   │   │   └── simulated_detection_engine.dart # Deterministic engine for unit tests
│   │   ├── verification/
│   │   │   ├── i_tilapia_verifier.dart     # ★ Verifier interface (abstract)
│   │   │   ├── tflite_tilapia_verifier.dart# ★ Real species gate
│   │   │   └── stub_tilapia_verifier.dart  # Always-true stub for dev
│   │   ├── storage_service.dart            # Visual Archive cache + expiry
│   │   ├── model_load_exceptions.dart      # ModelMissingException, ModelRunException
│   │   └── model_not_installed_exception.dart
│   └── presentation/                       # UI layer
│       ├── app_shell.dart                  # Bottom navigation bar (Scan/History/Tips)
│       ├── providers/
│       │   ├── detection_provider.dart     # ★ Central orchestrator for scan lifecycle
│       │   ├── farm_profile_provider.dart  # Loads/saves farm profile
│       │   ├── locale_provider.dart        # Language preference
│       │   └── settings_provider.dart      # Threshold + dark mode state
│       ├── screens/
│       │   ├── onboarding/
│       │   │   ├── disclaimer_gate_screen.dart   # Mandatory disclaimer acknowledgment
│       │   │   └── farm_profile_setup_screen.dart # Name entry + storage notice
│       │   ├── capture/
│       │   │   └── camera_capture_screen.dart     # Live viewfinder + gallery import
│       │   ├── result/
│       │   │   └── result_screen.dart             # ★ Detection results display
│       │   ├── history/
│       │   │   ├── detection_history_screen.dart  # Scrollable detection log
│       │   │   └── detection_detail_screen.dart   # Single record detail view
│       │   ├── settings/
│       │   │   ├── settings_screen.dart           # All user preferences
│       │   │   └── about_screen.dart              # App info + dev options Easter egg
│       │   └── biosecurity/
│       │       └── biosecurity_tips_screen.dart   # Practical biosecurity guidance
│       └── widgets/
│           ├── bounding_box_painter.dart          # CustomPainter for lesion box overlays
│           ├── save_to_gallery_button.dart        # Reusable "Save to Gallery" widget
│           └── terms_and_conditions_modal.dart    # Bottom-sheet T&C modal
├── test/                                   # Unit & widget tests
│   ├── csv_store_test.dart
│   ├── localization_test.dart
│   ├── settings_repository_test.dart
│   ├── tap_sequence_test.dart
│   └── widget_test.dart
└── pubspec.yaml                            # Dependencies & asset declarations
```

---

## 3. Architecture Diagram

The project follows a **clean-ish 3-layer architecture**:

```
┌──────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
│  Screens ←→ Providers (ChangeNotifier) ←→ Widgets            │
│  (UI only — no direct model/DB access)                       │
├──────────────────────────────────────────────────────────────┤
│                       DATA LAYER                             │
│  Repositories ←→ Local Store (CsvStore, SharedPreferences)   │
│  Models (DetectionResult, FarmProfile, BoundingBox)          │
├──────────────────────────────────────────────────────────────┤
│                      SERVICES LAYER                          │
│  Detection Engines (IDetectionEngine → TFLite / Mock)        │
│  Verification Gate  (ITilapiaVerifier → TFLite / Stub)       │
│  StorageService (Visual Archive cache + expiry)              │
└──────────────────────────────────────────────────────────────┘
```

**Key rule:** Screens never touch `CsvStore` directly — only `DetectionRepository` does. Screens never know which detection engine is active — only `DetectionProvider` does.

---

## 4. App Entry Point — `main.dart`

📄 **File:** [`lib/main.dart`](file:///d:/tilapiavision_app/lib/main.dart)

### Functions & Classes

| Name | Type | Line | What It Does |
|---|---|---|---|
| `main()` | Function | L27 | App entry. Initializes Flutter bindings, fires off background image cleanup, runs `TilapiaVisionApp`. |
| `_clearExpiredImagesInBackground()` | Function | L36 | Fire-and-forget: deletes detection photos older than 30 days via `StorageService().clearExpiredImages()`. |
| `TilapiaVisionApp` | StatelessWidget | L44 | Root widget. Sets up 4 `ChangeNotifierProvider`s in a `MultiProvider`, applies theme, starts splash. |
| `_SplashEntry` | StatelessWidget | L92 | Thin wrapper that passes `RootRouter` to `_SplashScreen`. |
| `_SplashScreen` | StatefulWidget | L109 | Branded splash (2.5s fade-in + scale-up animation of logo), then navigates to `RootRouter`. |
| `_SplashScreenState.initState()` | Method | L127 | Creates animation controller, schedules navigation timer. |
| `_SplashScreenState._navigateNext()` | Method | L144 | Push-replaces splash with the next screen using a fade transition. |
| `RootRouter` | StatelessWidget | L249 | **Decision gate:** If no farm profile → shows `DisclaimerGateScreen`. Otherwise → shows `AppShell`. Waits for all providers to finish loading first. |

### Provider Setup (inside `TilapiaVisionApp.build()`)

```dart
MultiProvider(
  providers: [
    FarmProfileProvider()..load(),     // Farm identity
    LocaleProvider()..load(),          // Language preference
    SettingsProvider()..load(),        // Thresholds + dark mode
    DetectionProvider(                 // Scan orchestrator
      engine: TFLiteDetectionEngine(), // ← REAL inference
      repository: DetectionRepository(),
      storageService: StorageService(),
      verifier: TFLiteTilapiaVerifier(), // ← REAL species gate
    ),
  ],
)
```

> **Panel tip:** This is where you'd swap `TFLiteDetectionEngine()` for `MockDetectionEngine()` to go back to fake data for UI testing.

---

## 5. Core Layer — `lib/core/`

### 5.1 `constants.dart` — Detection Thresholds

📄 **File:** [`lib/core/constants.dart`](file:///d:/tilapiavision_app/lib/core/constants.dart)

| Constant | Value | Purpose |
|---|---|---|
| `confidenceFloor` | 0.50 | Pre-NMS noise rejection. Discard any box scoring below this **before** NMS. |
| `nmsIouThreshold` | 0.70 | Non-Max Suppression — boxes sharing >70% overlap are collapsed. |
| `operatingThreshold` | 0.60 (mutable) | Separates "Presumptive Positive" (≥60%) from "Low Match" (<60%). Adjustable via Settings. |
| `inferenceTimeout` | 4000ms | Hard cap before UI shows timeout. |
| `targetLatency` | 3000ms | Target end-to-end budget (capture → result). |
| `imageRetentionDays` | 30 | Days before cached photos auto-delete. |
| `maxImageBytes` | 200 KB | Size cap per cached photo. |

> **Critical terminology note (in the file comments):** "Confidence" is a per-prediction score. "Accuracy" and "mAP@50" are dataset-level evaluation metrics computed offline — the app **never** calculates accuracy at runtime. Don't confuse the two in front of panelists.

### 5.2 `app_theme.dart` — Color System

📄 **File:** [`lib/core/app_theme.dart`](file:///d:/tilapiavision_app/lib/core/app_theme.dart)

| Element | Purpose |
|---|---|
| `AppColors` class | Theme-reactive color palette. Has `isDark` static flag flipped by `SettingsProvider`. |
| Brand colors | `deepBlue` (#065A82), `teal` (#1C7293), `mint` (#02C39A), `amber` (#F4A300), `navy` (#21295C) |
| Theme-reactive getters | `AppColors.ink`, `AppColors.surface`, `AppColors.heading`, etc. — auto-resolve to light/dark variants. |
| `AppTheme.light` / `AppTheme.dark` | Produce full `ThemeData` objects from the palette. |

### 5.3 `app_localizations.dart` — Trilingual Support

📄 **File:** [`lib/core/app_localizations.dart`](file:///d:/tilapiavision_app/lib/core/app_localizations.dart)

| Function | Purpose |
|---|---|
| `AppLocalizations.of(context)` | Reads current locale from `LocaleProvider` via widget tree. |
| `tr(key)` | Returns translated string for `key`, falls back to English. |
| `context.tr(key)` | Extension method — shorthand for `AppLocalizations.of(this).tr(key)`. |
| `context.trFmt(key, args)` | Same but replaces `{placeholder}` tokens (e.g., `{days}` → `30`). |

Supports: `AppLocale.english`, `AppLocale.tagalog`, `AppLocale.cebuano`.

### 5.4 `tap_sequence.dart` — Developer Options Easter Egg

📄 **File:** [`lib/core/tap_sequence.dart`](file:///d:/tilapiavision_app/lib/core/tap_sequence.dart)

| Function | Purpose |
|---|---|
| `TapSequence(length: 7, window: 2s)` | Constructor — requires 7 taps within 2-second gaps to trigger. |
| `tap(DateTime now)` → `int` | Registers a tap, returns taps remaining. `0` = sequence completed (resets internally). |

---

## 6. Data Layer — `lib/data/`

### 6.1 Models

#### `detection_result.dart`

📄 **File:** [`lib/data/models/detection_result.dart`](file:///d:/tilapiavision_app/lib/data/models/detection_result.dart)

**`DetectionLabel` enum** — Three possible outcomes:

| Label | Meaning |
|---|---|
| `presumptivePositive` | Lesion detected with confidence ≥ operating threshold |
| `lowMatch` | Something detected but confidence too low to call |
| `clear` | Model found nothing above the confidence floor |

**`BoundingBox` class** — Normalized 0.0–1.0 box coordinates:

| Field | Type | Purpose |
|---|---|---|
| `left`, `top`, `width`, `height` | `double` | Fractions of image dimensions |
| `confidence` | `double?` | Per-box confidence score |
| `toJson()` / `fromJson()` | Methods | Compact JSON serialization (`l`, `t`, `w`, `h`, `c`) |

**`DetectionResult` class** — One row of the CSV log:

| Field | Purpose |
|---|---|
| `id` | Auto-incremented row ID |
| `farmProfile` | Farm/owner name at time of scan |
| `timestamp` | Scan date-time |
| `diseaseClass` | `'hemorrhagic_ulcer'` or `'none'` |
| `confidenceScore` | 0.0–1.0 top prediction confidence |
| `imagePath` | Path to cached photo (nullable) |
| `label` | `DetectionLabel` enum value |
| `boundingBoxes` | List of all detected lesion boxes |

| Method | Purpose |
|---|---|
| `toCsvRow()` | Serialize to CSV column list |
| `fromCsvRow(row)` | Deserialize from CSV — handles both v1 (11-col) and v2 (8-col JSON bbox) schemas |
| `boundingBox` getter | Returns primary (highest-confidence) box or null |

#### `farm_profile.dart`

📄 **File:** [`lib/data/models/farm_profile.dart`](file:///d:/tilapiavision_app/lib/data/models/farm_profile.dart)

| Field | Purpose |
|---|---|
| `name` | Farm/owner name |
| `createdAt` | Profile creation timestamp |
| `acknowledgedStorageNotice` | Whether user accepted the 30-day notice |
| `toJson()` / `fromJson()` | JSON serialization for SharedPreferences |

### 6.2 Local Storage — `csv_store.dart`

📄 **File:** [`lib/data/local/csv_store.dart`](file:///d:/tilapiavision_app/lib/data/local/csv_store.dart)

**Singleton:** `CsvStore.instance`

| Method | Purpose |
|---|---|
| `_logFile` (getter) | Lazily creates `detection_log.csv` in app documents directory, writes header if new. |
| `_peekNextId()` | Scans existing rows to find max ID, returns max+1. |
| `_readRows()` | Reads entire CSV, drops header row, filters out short/blank rows. |
| `insert(result)` | Appends a new detection row with auto-incremented ID. |
| `getAll({limit})` | Returns all records sorted newest-first, optionally limited. |
| `clearAll()` | Wipes log, rewrites header only. |
| `deleteById(id)` | Removes one row by ID, rewrites file. |
| `exportFile()` | Returns the live CSV file handle (no copy needed — it IS the export). |

> **Panel tip:** "Why CSV instead of SQLite?" — The panelists previously gave feedback that a relational DB is unnecessary overhead for a single flat log with no joins. CSV doubles as the export format farmers actually want (opens in Excel/Google Sheets directly).

### 6.3 Repositories

#### `detection_repository.dart`

📄 **File:** [`lib/data/repositories/detection_repository.dart`](file:///d:/tilapiavision_app/lib/data/repositories/detection_repository.dart)

| Method | Delegates To |
|---|---|
| `saveDetection(result)` | `CsvStore.insert()` |
| `getRecentDetections({limit})` | `CsvStore.getAll()` |
| `clearAll()` | `CsvStore.clearAll()` |
| `deleteDetection(id)` | `CsvStore.deleteById()` |
| `exportCsvFile()` | `CsvStore.exportFile()` |

#### `farm_profile_repository.dart`

📄 **File:** [`lib/data/repositories/farm_profile_repository.dart`](file:///d:/tilapiavision_app/lib/data/repositories/farm_profile_repository.dart)

| Method | Purpose |
|---|---|
| `getProfile()` | Reads JSON from `SharedPreferences` key `'farm_profile'`. |
| `saveProfile(profile)` | Writes JSON to SharedPreferences. |
| `hasProfile()` | Returns `true` if key exists. |

#### `settings_repository.dart`

📄 **File:** [`lib/data/repositories/settings_repository.dart`](file:///d:/tilapiavision_app/lib/data/repositories/settings_repository.dart)

| Method | Key | Default |
|---|---|---|
| `getOperatingThreshold()` / `set…` | `operating_threshold` | 0.60 |
| `getVerifierThreshold()` / `set…` | `verifier_threshold` | 0.85 |
| `getDarkMode()` / `set…` | `dark_mode_enabled` | `false` |
| `getDeveloperOptions()` / `set…` | `developer_options_enabled` | `false` |

---

## 7. Services Layer — `lib/services/`

### 7.1 Detection Engine — The Strategy Pattern

📄 **Interface:** [`lib/services/detection/i_detection_engine.dart`](file:///d:/tilapiavision_app/lib/services/detection/i_detection_engine.dart)

```dart
abstract class IDetectionEngine {
  Future<void> initialize();
  bool get isReady;
  Future<DetectionResult> analyze(File image, {required String farmProfile});
}
```

Three implementations exist:

#### 7.1.1 `TFLiteDetectionEngine` — THE REAL ENGINE ★

📄 **File:** [`lib/services/detection/tflite_detection_engine.dart`](file:///d:/tilapiavision_app/lib/services/detection/tflite_detection_engine.dart)

| Function | Line | Purpose |
|---|---|---|
| `initialize()` | L38 | Copies `best_int8.tflite` from assets to a temp file, loads `Interpreter` with XNNPack delegate. |
| `analyze(image, farmProfile)` | L72 | **Full inference pipeline:** decode image → resize 640×640 → channels-first float32 → run interpreter → parse output → confidence floor → NMS → operating threshold → build `DetectionResult`. |
| `_nms(boxes, iouThreshold)` | L165 | Greedy Non-Max Suppression — suppresses overlapping boxes above IoU threshold. |
| `_iou(a, b)` | L179 | Computes Intersection-over-Union between two raw detections. |
| `_prepareChannelsFirst(bytes)` | L219 | **Runs on background isolate via `compute()`**. Decodes photo, resizes to 640×640, lays out `[1, 3, 640, 640]` channels-first float32 buffer normalized 0.0–1.0. |
| `_materializeAsset(path)` | L196 | Copies Flutter asset to a real temp file (workaround for Android AssetManager mmap issues). |

**Model tensor contract:**
- **INPUT:** `[1, 3, 640, 640]` float32 — channels-first, pixels in [0, 1]
- **OUTPUT:** `[1, 5, 8400]` float32 — rows: cx, cy, w, h, score

**The 3-step post-processing pipeline:**
1. **Confidence Floor (0.50)** → discard noise
2. **NMS (IoU 0.70)** → collapse duplicates
3. **Operating Threshold (0.60)** → classify result label

#### 7.1.2 `MockDetectionEngine` — Dev Engine

📄 **File:** [`lib/services/detection/mock_detection_engine.dart`](file:///d:/tilapiavision_app/lib/services/detection/mock_detection_engine.dart)

Returns fake results after 1.6s delay. Modes: `forcePositive`, `forceLowMatch`, `forceClear`, `forceTimeout`, `random`.

#### 7.1.3 `SimulatedDetectionEngine` — Test Engine

📄 **File:** [`lib/services/detection/simulated_detection_engine.dart`](file:///d:/tilapiavision_app/lib/services/detection/simulated_detection_engine.dart)

Deterministic outcomes for automated widget tests. **Not used by the running app.**

### 7.2 Species Verification Gate — Two-Stage Pipeline

📄 **Interface:** [`lib/services/verification/i_tilapia_verifier.dart`](file:///d:/tilapiavision_app/lib/services/verification/i_tilapia_verifier.dart)

```dart
abstract class ITilapiaVerifier {
  Future<bool> isTilapia(File image);
}
```

#### 7.2.1 `TFLiteTilapiaVerifier` — THE REAL VERIFIER ★

📄 **File:** [`lib/services/verification/tflite_tilapia_verifier.dart`](file:///d:/tilapiavision_app/lib/services/verification/tflite_tilapia_verifier.dart)

| Function | Line | Purpose |
|---|---|---|
| `initialize()` | L40 | Loads `tilapia_verifier_int8.tflite` with XNNPack delegate. |
| `isTilapia(image)` | L64 | Resizes to 224×224, runs classifier, dequantizes output, compares probability against `threshold` (default 0.85). |
| `_prepareChannelsLastUint8(bytes)` | (top-level) | **Background isolate.** Decodes, resizes 224×224, outputs `[1, 224, 224, 3]` uint8 channels-last buffer. |
| `_materializeAsset(path)` | L100 | Same asset-to-file pattern as the disease detector. |

**Model tensor contract:**
- **INPUT:** `[1, 224, 224, 3]` uint8 — channels-last, raw pixel bytes 0–255
- **OUTPUT:** `[1, 1]` uint8 — quantized probability

#### 7.2.2 `StubTilapiaVerifier` — Always True

📄 **File:** [`lib/services/verification/stub_tilapia_verifier.dart`](file:///d:/tilapiavision_app/lib/services/verification/stub_tilapia_verifier.dart)

`isTilapia()` always returns `true`. Used during development before the real verifier was trained.

### 7.3 `StorageService` — Visual Archive

📄 **File:** [`lib/services/storage_service.dart`](file:///d:/tilapiavision_app/lib/services/storage_service.dart)

| Method | Purpose |
|---|---|
| `_archiveDir()` | Returns (creating if needed) the `visual_archive/` folder in app documents. |
| `cacheImage(source)` | Compresses photo to JPEG (starts at quality 85, steps down by 10 until ≤200 KB), saves to archive, returns path. |
| `clearExpiredImages()` | Deletes any file in `visual_archive/` older than 30 days. Called once at app launch. |
| `imageExists(path)` | Returns `true` if the given file still exists on disk. Used by History screen for "expired" fallback. |

### 7.4 Model Exceptions

📄 **File:** [`lib/services/model_load_exceptions.dart`](file:///d:/tilapiavision_app/lib/services/model_load_exceptions.dart)

| Exception | When Thrown |
|---|---|
| `ModelMissingException` | `.tflite` file not found in assets — tells user to copy file and rebuild. |
| `ModelRunException` | Interpreter loaded but `run()` failed — gives native error detail. |

---

## 8. Presentation Layer — `lib/presentation/`

### 8.1 `app_shell.dart` — Bottom Navigation

📄 **File:** [`lib/presentation/app_shell.dart`](file:///d:/tilapiavision_app/lib/presentation/app_shell.dart)

Uses `IndexedStack` to keep all 3 tabs alive:
- Tab 0: `CameraCaptureScreen` (Scan)
- Tab 1: `DetectionHistoryScreen` (History)
- Tab 2: `BiosecurityTipsScreen` (Tips)

### 8.2 Providers

#### `DetectionProvider` — The Central Orchestrator ★

📄 **File:** [`lib/presentation/providers/detection_provider.dart`](file:///d:/tilapiavision_app/lib/presentation/providers/detection_provider.dart)

| Property/Method | Purpose |
|---|---|
| `status` (`ScanStatus` enum) | Drives which view `ResultScreen` renders: `idle`, `processing`, `success`, `timeout`, `error`, `notTilapia`, `modelMissing`, `modelFailed`. |
| `lastResult` | The most recent `DetectionResult`. |
| `history` | List of all saved detections. |
| `runDetection(image, farmProfile)` | **The main pipeline:** (1) Species verifier gate → (2) Initialize engine if needed → (3) Run `analyze()` with timeout → (4) Cache image if not Low Match → (5) Set status. |
| `saveLastResultToHistory()` | Writes `lastResult` to CSV via repository, reloads history. |
| `loadHistory()` | Reads all records from repository, notifies listeners. |
| `exportCsv()` | Gets CSV file from repository, opens platform share sheet via `share_plus`. |
| `saveDetectionToGallery(result)` | Renders photo with bounding boxes and caption strip burned in, saves to phone gallery via `Gal`. |
| `_renderImageWithBox(result)` | **Canvas compositing:** draws source image → overlays bounding boxes via `MultiBoxPainter` → adds caption strip below → encodes as PNG. |
| `checkVerifierReady()` | For Settings screen — checks if verifier model is loaded without running a scan. |
| `checkDetectorReady()` | For Settings screen — checks if detector model is loaded. |
| `deleteDetection(id)` | Deletes one record from CSV, reloads history. |
| `reset()` | Sets status back to idle, clears lastResult. |

#### `FarmProfileProvider`

📄 **File:** [`lib/presentation/providers/farm_profile_provider.dart`](file:///d:/tilapiavision_app/lib/presentation/providers/farm_profile_provider.dart)

| Method | Purpose |
|---|---|
| `load()` | Reads saved profile from `FarmProfileRepository`. |
| `createProfile(name)` | Creates new profile, saves to disk. |
| `updateName(name)` | Renames farm, keeps original creation date. |
| `hasProfile` getter | Returns `true` if profile exists (determines onboarding vs. main app). |

#### `LocaleProvider`

📄 **File:** [`lib/presentation/providers/locale_provider.dart`](file:///d:/tilapiavision_app/lib/presentation/providers/locale_provider.dart)

| Method | Purpose |
|---|---|
| `load()` | Reads `app_locale` from `SharedPreferences`. |
| `setLocale(locale)` | Updates in-memory + persists to SharedPreferences. |

#### `SettingsProvider`

📄 **File:** [`lib/presentation/providers/settings_provider.dart`](file:///d:/tilapiavision_app/lib/presentation/providers/settings_provider.dart)

| Method | Purpose |
|---|---|
| `load()` | Reads all 4 settings from `SettingsRepository`, calls `_apply()`. |
| `setOperatingThreshold(v)` | Updates + persists + applies to `DetectionConfig.operatingThreshold`. |
| `setVerifierThreshold(v)` | Updates + persists + applies to `TFLiteTilapiaVerifier.threshold`. |
| `setDarkMode(enabled)` | Updates + persists + applies to `AppColors.isDark`. |
| `setDeveloperOptionsEnabled(enabled)` | Shows/hides threshold sliders in Settings. |
| `_apply()` | Syncs in-memory settings to the static fields that the engines read. |

### 8.3 Screens

#### Onboarding Flow

**1. `DisclaimerGateScreen`** — [`lib/presentation/screens/onboarding/disclaimer_gate_screen.dart`](file:///d:/tilapiavision_app/lib/presentation/screens/onboarding/disclaimer_gate_screen.dart)

- Mandatory disclaimer: "This is a presumptive screening tool, not a diagnosis."
- Checkbox must be checked before "Continue" button is enabled.
- Language selector dropdown at top-right.

**2. `FarmProfileSetupScreen`** — [`lib/presentation/screens/onboarding/farm_profile_setup_screen.dart`](file:///d:/tilapiavision_app/lib/presentation/screens/onboarding/farm_profile_setup_screen.dart)

| Function | Purpose |
|---|---|
| `_showTermsModal()` | Opens `showTermsAndConditionsModal()` bottom sheet. |
| `_createProfile()` | Calls `FarmProfileProvider.createProfile()`, navigates to `AppShell`. |
| `_canContinue` getter | Name not empty + checkbox checked + not saving. |

#### Camera & Result

**`CameraCaptureScreen`** — [`lib/presentation/screens/capture/camera_capture_screen.dart`](file:///d:/tilapiavision_app/lib/presentation/screens/capture/camera_capture_screen.dart)

| Function | Purpose |
|---|---|
| `_setupCamera()` | Finds back camera, creates `CameraController`, initializes. |
| `_toggleFlash()` | Toggles torch mode on/off. |
| `_capture()` | Takes picture, navigates to `ResultScreen`. |
| `_pickFromGallery()` | Opens `ImagePicker` for gallery selection, navigates to `ResultScreen`. |
| `_goToResult(image)` | Reads farm name from provider, pushes `ResultScreen`. |

**`ResultScreen`** — [`lib/presentation/screens/result/result_screen.dart`](file:///d:/tilapiavision_app/lib/presentation/screens/result/result_screen.dart)

| Widget | When Shown |
|---|---|
| `_ProcessingView` | During `idle` / `processing` — dimmed photo with spinner |
| `_ErrorView` | On `timeout`, `error`, `notTilapia`, `modelMissing`, `modelFailed` |
| `_ResultView` | On `success` — full result with badge, heading, body, action box, detection details, bounding box overlay |

The `_ResultView` renders three different visual themes via `_ResultTheme.of(label)`:

| Label | Badge Color | Accent |
|---|---|---|
| Presumptive Positive | Amber | Solid bounding box |
| Low Match | Slate/Gray | Dashed bounding box |
| Clear | Mint/Green | No bounding box |

**Bottom actions:**
- Presumptive Positive / Clear → "Save to History" button
- Low Match → "Retake Photo" button (Low Match is NOT saved to history)
- All outcomes → "Save to Gallery" and "Scan Another"

#### History

**`DetectionHistoryScreen`** — [`lib/presentation/screens/history/detection_history_screen.dart`](file:///d:/tilapiavision_app/lib/presentation/screens/history/detection_history_screen.dart)

| Function | Purpose |
|---|---|
| `initState()` | Calls `DetectionProvider.loadHistory()` after first frame. |
| `_handleExport()` | Calls `DetectionProvider.exportCsv()`. |
| `_HistoryCard` | Shows thumbnail (or "Expired" fallback), title, colored dot, confidence %, chevron. |

**`DetectionDetailScreen`** — [`lib/presentation/screens/history/detection_detail_screen.dart`](file:///d:/tilapiavision_app/lib/presentation/screens/history/detection_detail_screen.dart)

| Function | Purpose |
|---|---|
| `_handleDelete()` | Shows confirmation dialog, then calls `DetectionProvider.deleteDetection()`. |
| Image display | Shows cached photo with `MultiBoxPainter` overlay, or "Image Expired" fallback. |
| Bottom actions | "Delete" (outlined amber) + "Save to Gallery" (filled). |

#### Settings & About

**`SettingsScreen`** — [`lib/presentation/screens/settings/settings_screen.dart`](file:///d:/tilapiavision_app/lib/presentation/screens/settings/settings_screen.dart)

Sections:
1. **Language** — Radio selector for English/Tagalog/Cebuano
2. **Farm name** — Editable text field + Save button
3. **Appearance** — Dark mode toggle
4. **Developer Options** (hidden until unlocked) — Two threshold sliders
5. **Model Status** — FutureBuilder tiles showing verifier/detector readiness
6. **Stored Data** — Export CSV button

**`AboutScreen`** — [`lib/presentation/screens/settings/about_screen.dart`](file:///d:/tilapiavision_app/lib/presentation/screens/settings/about_screen.dart)

| Function | Purpose |
|---|---|
| `_onLogoTap()` | Registers tap on `TapSequence`. After 7 rapid taps: unlocks developer options in Settings. Shows countdown from tap 5 onward. |

Info cards: What the app does, detection scope, dataset source, how it works (two-stage pipeline), limitations, data retention.

#### Biosecurity Tips

**`BiosecurityTipsScreen`** — [`lib/presentation/screens/biosecurity/biosecurity_tips_screen.dart`](file:///d:/tilapiavision_app/lib/presentation/screens/biosecurity/biosecurity_tips_screen.dart)

Static list of 4 biosecurity tips (sanitize hands, disinfect nets, keep phone dry, isolate suspects). Available from tab bar — not forced during onboarding.

### 8.4 Reusable Widgets

#### `BoundingBoxPainter` / `MultiBoxPainter`

📄 **File:** [`lib/presentation/widgets/bounding_box_painter.dart`](file:///d:/tilapiavision_app/lib/presentation/widgets/bounding_box_painter.dart)

| Class | Purpose |
|---|---|
| `BoundingBoxPainter` | Draws a single normalized bounding box with confidence label tag. |
| `MultiBoxPainter` | Draws ALL bounding boxes in one pass. Each box gets its own per-box confidence tag. |
| `_paintBox()` | Shared drawing logic — renders rounded rect (solid or dashed), confidence label tag above (or inside if near top edge). |
| `_drawDashedRRect()` | Draws a dashed rounded rectangle using path metrics. |

#### `SaveToGalleryButton`

📄 **File:** [`lib/presentation/widgets/save_to_gallery_button.dart`](file:///d:/tilapiavision_app/lib/presentation/widgets/save_to_gallery_button.dart)

Reusable button used on both Result screen (outlined style) and Detail screen (filled style). Calls `DetectionProvider.saveDetectionToGallery()` and shows outcome in a SnackBar.

#### `TermsAndConditionsModal`

📄 **File:** [`lib/presentation/widgets/terms_and_conditions_modal.dart`](file:///d:/tilapiavision_app/lib/presentation/widgets/terms_and_conditions_modal.dart)

Bottom sheet with 3 sections: Scope of Detection, Dataset Origin, Data Retention. Optional "I Agree" button that auto-checks the acknowledgment checkbox on the setup screen.

---

## 9. Detection Pipeline — End-to-End Flow

```
User taps SHUTTER or picks from GALLERY
         │
         ▼
  CameraCaptureScreen._capture() / _pickFromGallery()
         │
         ▼
  ResultScreen → initState() triggers:
  DetectionProvider.runDetection(image, farmProfile)
         │
         ▼
  ┌─ STAGE 1: Species Verification Gate ─────────────────┐
  │  TFLiteTilapiaVerifier.isTilapia(image)              │
  │  ├─ Decode image on background isolate               │
  │  ├─ Resize to 224×224, channels-last uint8           │
  │  ├─ Run tilapia_verifier_int8.tflite                 │
  │  ├─ Dequantize output: probability = raw * scale     │
  │  └─ probability >= 0.85 threshold?                   │
  │       ├─ NO  → status = notTilapia → STOP            │
  │       └─ YES → continue to Stage 2                   │
  └──────────────────────────────────────────────────────┘
         │
         ▼
  ┌─ STAGE 2: Disease Detection ─────────────────────────┐
  │  TFLiteDetectionEngine.analyze(image, farmProfile)   │
  │  ├─ Decode image on background isolate               │
  │  ├─ Resize to 640×640, channels-first float32 [0,1]  │
  │  ├─ Run best_int8.tflite (YOLO11n)                   │
  │  ├─ Parse output [1, 5, 8400]:                       │
  │  │   rows = cx, cy, w, h, score for 8400 candidates  │
  │  │                                                   │
  │  ├─ POST-PROCESSING:                                 │
  │  │   1. Confidence Floor (0.50) → discard noise      │
  │  │   2. NMS (IoU 0.70) → collapse duplicates         │
  │  │   3. Operating Threshold (0.60) → classify:       │
  │  │      ├─ No boxes survived    → DetectionLabel.clear│
  │  │      ├─ Top score >= 0.60    → .presumptivePositive│
  │  │      └─ Top score < 0.60     → .lowMatch          │
  │  │                                                   │
  │  └─ Return DetectionResult with all bounding boxes   │
  └──────────────────────────────────────────────────────┘
         │
         ▼
  DetectionProvider post-processing:
  ├─ Low Match? → Don't cache image (not saved to history)
  ├─ Otherwise  → StorageService.cacheImage() (compress ≤200KB)
  └─ status = ScanStatus.success → notifyListeners()
         │
         ▼
  ResultScreen rebuilds via Consumer<DetectionProvider>
  └─ Shows _ResultView with appropriate theme:
     ├─ Presumptive Positive (amber, solid box)
     ├─ Low Match (gray, dashed box, "Retake" instead of "Save")
     └─ Clear (mint, no box)
```

---

## 10. Key Design Patterns & Decisions

### Pattern: Strategy (Detection Engine)
- **Interface:** `IDetectionEngine`
- **Real:** `TFLiteDetectionEngine` — swapped in `main.dart`
- **Mock:** `MockDetectionEngine` — comment-swap for UI dev
- **Why:** Entire app was built and tested before the real ML model existed.

### Pattern: Strategy (Species Verifier)
- **Interface:** `ITilapiaVerifier`
- **Real:** `TFLiteTilapiaVerifier` — runs before the detector
- **Stub:** `StubTilapiaVerifier` — always returns true

### Pattern: Repository
- Screens → Provider → Repository → CsvStore
- Screens **never** touch `CsvStore` directly.

### Decision: CSV instead of SQLite
- Panel feedback: relational DB is overkill for a single flat log.
- Bonus: CSV IS the export format — no conversion step needed.

### Decision: No-Login Architecture
- No account, no internet, no passwords.
- `FarmProfile` in SharedPreferences replaces user accounts.
- Farmer gets instant access even during an emergency.

### Decision: 30-Day Photo Auto-Delete
- Photos cached in `visual_archive/`, auto-deleted after 30 days.
- Detection records (CSV rows) persist indefinitely until user deletes.
- "Graceful degradation" — history cards show "Image Expired" fallback.

### Decision: Low Match ≠ Clear
- Low Match = "something was detected but below threshold" → dashed box, prompt to retake.
- Clear = "nothing at all above confidence floor" → no box.
- Low Match is **not saved to history** (no disk I/O for image caching).

### Decision: Confidence ≠ Accuracy
- The app shows a per-prediction **confidence score** (0–100%).
- It never displays **accuracy**, **mAP@50**, or **recall** — those are offline evaluation metrics.
- This distinction is explicitly maintained in code comments and UI copy.

### Decision: Background Isolates for Image Processing
- Both `_prepareChannelsFirst()` and `_prepareChannelsLastUint8()` run via `compute()`.
- Prevents UI thread freeze when decoding 12MP phone photos.

---

## 11. Quick-Find Index — Every Function by File

### `main.dart`
| Function | Line |
|---|---|
| `main()` | 27 |
| `_clearExpiredImagesInBackground()` | 36 |
| `TilapiaVisionApp.build()` | 48 |
| `_SplashScreenState.initState()` | 127 |
| `_SplashScreenState._navigateNext()` | 144 |
| `RootRouter.build()` | 253 |

### `core/constants.dart`
| Constant | Line |
|---|---|
| `DetectionConfig.confidenceFloor` | ~1181 |
| `DetectionConfig.nmsIouThreshold` | ~1187 |
| `DetectionConfig.operatingThreshold` | ~1191 |
| `DetectionConfig.inferenceTimeout` | ~1195 |
| `DetectionConfig.imageRetentionDays` | ~1202 |

### `services/detection/tflite_detection_engine.dart`
| Function | Line |
|---|---|
| `initialize()` | 38 |
| `analyze()` | 72 |
| `_nms()` | 165 |
| `_iou()` | 179 |
| `_materializeAsset()` | 196 |
| `_prepareChannelsFirst()` | 219 |

### `services/verification/tflite_tilapia_verifier.dart`
| Function | Line |
|---|---|
| `initialize()` | 40 |
| `isTilapia()` | 64 |
| `_materializeAsset()` | 100 |
| `_prepareChannelsLastUint8()` | (top-level) |

### `presentation/providers/detection_provider.dart`
| Function | Line |
|---|---|
| `runDetection()` | 1888 |
| `saveLastResultToHistory()` | 1948 |
| `loadHistory()` | 1954 |
| `exportCsv()` | 1962 |
| `saveDetectionToGallery()` | 1984 |
| `_renderImageWithBox()` | 2061 |
| `checkVerifierReady()` | 2138 |
| `checkDetectorReady()` | 2152 |
| `deleteDetection()` | 2175 |
| `reset()` | 2180 |

### `data/local/csv_store.dart`
| Function | Purpose |
|---|---|
| `insert()` | Append row |
| `getAll()` | Read all, sort newest-first |
| `clearAll()` | Wipe + rewrite header |
| `deleteById()` | Remove one row, rewrite |
| `exportFile()` | Return file handle |

### `data/models/detection_result.dart`
| Function | Purpose |
|---|---|
| `toCsvRow()` | Serialize to CSV |
| `fromCsvRow()` | Deserialize (v1 + v2 compat) |
| `BoundingBox.toJson()` | Compact JSON |
| `BoundingBox.fromJson()` | Parse JSON |

---

## 12. Anticipated Panel Questions & Where to Point

| Question | Where to Find the Answer |
|---|---|
| **"How does the detection pipeline work?"** | [Section 9 — End-to-End Flow](#9-detection-pipeline--end-to-end-flow). Two-stage: verifier gate → YOLO11n disease detector → 3-step post-processing. |
| **"What model architecture are you using?"** | YOLO11n INT8 quantized (`best_int8.tflite`). See [`tflite_detection_engine.dart`](file:///d:/tilapiavision_app/lib/services/detection/tflite_detection_engine.dart) L16–25 for tensor contract. |
| **"How does the species verification work?"** | Binary classifier (tilapia vs. not-tilapia), `tilapia_verifier_int8.tflite`, 224×224 input. See [`tflite_tilapia_verifier.dart`](file:///d:/tilapiavision_app/lib/services/verification/tflite_tilapia_verifier.dart). |
| **"What is NMS and why do you use it?"** | Non-Max Suppression collapses duplicate overlapping boxes. See `_nms()` at line 165 in [`tflite_detection_engine.dart`](file:///d:/tilapiavision_app/lib/services/detection/tflite_detection_engine.dart#L165-L177). IoU threshold = 0.70. |
| **"What are the thresholds and what do they mean?"** | [`constants.dart`](file:///d:/tilapiavision_app/lib/core/constants.dart) — confidence floor (0.50), NMS IoU (0.70), operating threshold (0.60). See [Section 5.1](#51-constantsdart--detection-thresholds). |
| **"Is this displaying accuracy?"** | **No.** The app shows per-prediction **confidence**, not accuracy. See the terminology note in [`constants.dart`](file:///d:/tilapiavision_app/lib/core/constants.dart) and [`detection_result.dart`](file:///d:/tilapiavision_app/lib/data/models/detection_result.dart). |
| **"Why CSV instead of SQLite?"** | Panel feedback: no joins, no FK, one flat log. CSV doubles as export format. See [`csv_store.dart`](file:///d:/tilapiavision_app/lib/data/local/csv_store.dart) header comment. |
| **"How do you handle no internet?"** | Everything runs on-device. No network calls anywhere. Models bundled in assets. |
| **"How do you swap between real and mock engines?"** | Change one line in `main.dart` — `engine: TFLiteDetectionEngine()` → `MockDetectionEngine()`. Strategy pattern. |
| **"What design pattern is used for the detection engine?"** | **Strategy Pattern** — `IDetectionEngine` interface with 3 implementations. See [Section 10](#10-key-design-patterns--decisions). |
| **"How is state managed?"** | **Provider** (ChangeNotifier). Four providers in `MultiProvider`: Detection, FarmProfile, Locale, Settings. |
| **"How does the bounding box display work?"** | `MultiBoxPainter` (CustomPainter) draws normalized boxes as overlay. [`bounding_box_painter.dart`](file:///d:/tilapiavision_app/lib/presentation/widgets/bounding_box_painter.dart). |
| **"What happens to old photos?"** | Auto-deleted after 30 days by `StorageService.clearExpiredImages()`, called fire-and-forget at app launch. CSV records survive. |
| **"How does the gallery save work?"** | `_renderImageWithBox()` composites photo + boxes + caption strip into PNG → `Gal.putImage()` into "TilapiaVision" album. |
| **"What languages are supported?"** | English, Tagalog, Cebuano. See [`app_localizations.dart`](file:///d:/tilapiavision_app/lib/core/app_localizations.dart). |
| **"How are the threshold sliders exposed?"** | Hidden by default. Tap logo on About screen 7 times → unlocks "Developer Options" in Settings. See [`tap_sequence.dart`](file:///d:/tilapiavision_app/lib/core/tap_sequence.dart) and [`about_screen.dart`](file:///d:/tilapiavision_app/lib/presentation/screens/settings/about_screen.dart). |
| **"What are your dependencies?"** | See [`pubspec.yaml`](file:///d:/tilapiavision_app/pubspec.yaml): `tflite_flutter` (inference), `camera` (capture), `provider` (state), `csv` (storage), `gal` (gallery save), `share_plus` (export), `image` (compression), `lucide_icons_flutter` (icons). |
| **"Where is the dataset from?"** | Online datasets, **not from BFAR**. Stated in the About screen and Terms & Conditions. |
| **"What does the app NOT do?"** | Not a veterinary diagnosis. Only external hemorrhagic ulcer lesions. Only matured Nile Tilapia (not fingerlings). Other diseases/parasites/species not covered. |

---

> **Study tip:** The most critical files to deeply understand are marked with ★ throughout this guide. In order of importance:
> 1. `tflite_detection_engine.dart` — the real inference + NMS pipeline
> 2. `tflite_tilapia_verifier.dart` — the species gate
> 3. `detection_provider.dart` — the orchestrator connecting everything
> 4. `main.dart` — the wiring and startup flow
> 5. `constants.dart` — the thresholds and their meanings
