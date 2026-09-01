# TilapiaVision — Rebuild Notes

This is a full reconstruction of the project with three fixes applied. Read
this before you build, since a couple of things need one-time action on
your end.

## 1. Bounding box now persists to history (the original bug)

Two files changed together — both were required, one alone wouldn't fix it:

- **`lib/data/models/detection_result.dart`** — `csvHeader` now has 11
  columns (`bbox_left`, `bbox_top`, `bbox_width`, `bbox_height` added), and
  `toCsvRow()` actually writes them (previously the header listed them but
  the row-builder didn't include them — that mismatch alone would have
  made every saved detection disappear from history, since `csv_store.dart`
  filters out any row shorter than the header).
- **`lib/presentation/screens/history/detection_detail_screen.dart`** —
  wraps the photo in a `Stack` and draws `BoundingBoxPainter` over it when
  `result.boundingBox != null`, same pattern the Result screen already used.

**Action required:** delete any `detection_log.csv` already on your test
device/emulator (or uninstall/reinstall the app) before testing. A file
written with the old 7-column format will be silently skipped by the new
11-column reader — that's intentional (better than crashing on old data),
but it means old rows won't show boxes retroactively.

## 2. Mock detection now balanced across all four outcomes

**`lib/services/detection/mock_detection_engine.dart`** — two changes:

- Default mode changed from always-`forcePositive` to `random`.
- Fixed a real bug in `random` mode: it used to pick a uniformly random
  *confidence value*, which (a) could never trigger the timeout screen at
  all, since timeout isn't confidence-driven, and (b) skewed heavily
  toward "Clear" since that confidence range is far wider than the others.
  It now picks the *outcome* uniformly among all four (Positive / Low
  Match / Clear / Timeout) first, then generates a representative
  confidence for whichever one got picked.

Run the app repeatedly now and you'll see all four screens, including "No
Lesions Detected" and the hardware-timeout screen. `test/widget_test.dart`
has a new test asserting this (`over many runs, random mode produces all
four outcomes`).

## 3. What's a stub, on purpose

**`lib/services/detection/tflite_detection_engine.dart`** is still the
original placeholder that throws if called — this rebuild didn't touch it.
`main.dart` wires up `MockDetectionEngine()`, matching where your project
actually is (model still training). When `best_int8.tflite` is ready, the
integration checklist is in that file's doc comment.

## Android / build config

I regenerated `android/` from a standard Flutter template rather than
recovering your exact original files, since I don't have those verbatim.
Two things are already baked in from your earlier troubleshooting:

- `kotlin.jvm.target.validation.mode=warning`, `org.gradle.parallel=false`,
  and `kotlin.incremental=false` in `android/gradle.properties`
- An `afterEvaluate` JVM-target-17 fix in `android/build.gradle.kts`

**No launcher icon is included** — I don't have your brand assets to
generate `mipmap-*/ic_launcher.png` from, so the manifest omits
`android:icon` and Android will show a default icon. Run `flutter create .`
once over this project to regenerate the standard icon set, or drop in
your own.

## Verification performed before packaging

Since I can't run `flutter analyze` or `flutter build` in this environment
(no Flutter SDK here), I verified statically instead:
- All 27 Dart files present, matching your original file count.
- Every file's braces/parens/brackets balance.
- Every local `import` resolves to a real file.
- Every `AppColors.*`/`AppTheme.*` reference used anywhere has a matching
  definition.
- No duplicate class/enum declarations in any file.
- The bounding-box fix and mock-engine fix each verified present with the
  exact code patterns described above, not just "file exists."

This catches structural and consistency bugs, but it is **not** a
substitute for `flutter pub get && flutter analyze` on your machine, which
will catch real type errors this can't. Run that first before building to
device.
