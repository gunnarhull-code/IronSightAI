# Equipment Identification Capture — Platform Support

This module provides offline capture for equipment serial numbers and
hour-meter readings, and is integrated into Quick Appraisal.

## Supported platforms (camera + on-device OCR)

| Platform | Camera capture | On-device OCR | Notes |
|---|---|---|---|
| Android | Yes | Yes (`google_mlkit_text_recognition`) | Requires `CAMERA` permission |
| iOS | Yes | Yes (`google_mlkit_text_recognition`) | Requires `NSCameraUsageDescription` |

## Unsupported / manual-fallback platforms

| Platform | Behavior |
|---|---|
| Web (including Brave) | Camera/OCR disabled. Manual entry always available. |
| Desktop (Windows / macOS / Linux) | Treated as unsupported for OCR in V1. Manual entry always available. |

## Architecture

- **Domain** (`lib/domain/equipment_id_capture/`): pure Dart normalization,
  field-aware serial/hour extraction, capture controller, and narrow ports
  (`ImageCapturePort`, `TextRecognitionPort`, `CameraPermissionPort`).
- **Data / platform** (`lib/data/equipment_id_capture/`): `camera`,
  `permission_handler`, and ML Kit adapters. Vendor types do not leak into
  domain entities.
- **Presentation** (`lib/features/equipment_id_capture/presentation/`):
  reusable `EquipmentIdCapturePanel` that depends only on the domain
  controller — never on camera/OCR packages directly.
- **Quick Appraisal integration**
  (`lib/features/inspection/presentation/inspection_workspace_screen.dart`):
  embeds serial and hour panels; a candidate tap or completed manual edit
  persists immediately via `LocalInspectionRepository.saveConfirmedEquipmentId`.

## Product rules

- OCR remains on-device and optional. Detected text is never auto-saved.
- One recommended serial/hour is shown when confidence is sufficient.
- Weaker field-valid values sit behind **Other possibilities** (local
  expand/collapse — not `ExpansionTile` PageStorage under the appraisal list).
- Tapping a candidate is explicit human confirmation and saves immediately.
- Manual entry is always visible and saves when editing is completed.
- There is no second Confirm button for candidate selection or manual save.
- Serial OCR never silently substitutes look-alike characters (O/0, I/1, S/5,
  B/8). Ambiguous serials are labelled **Check ambiguous characters.**
- Hour readings stay strictly numeric; letters are never converted to digits.
- Capture services perform no network I/O.
- Saved serial / hours are stored on the **local inspection draft**
  (not rewritten into equipment-master cache by this flow).
- Values survive draft reopen and app restart (Drift schema v3 local columns).
- Rescanning never replaces a saved value unless the user taps or types a
  replacement. Cancelled capture, OCR failure, or persist failure keeps the
  previous saved value.
- Quick Appraisal scroll position is preserved across equipment-ID saves.

## Samsung S22 device findings (Draft PR #25)

### Defect 1 — repeated serial-photo red screen (fixed)

After roughly the third serial capture/retake, Quick Appraisal showed Flutter’s
red error screen:

`type 'double' is not a subtype of type 'bool?' in type cast`

Root cause: “Other possibilities” used `ExpansionTile`/`Expansible`, which
reads PageStorage as `bool?` for expanded state. That widget sits under Quick
Appraisal’s `ListView` with a `PageStorageKey` that stores the scroll offset as
a `double`. After scroll + repeated OCR rebuilds that mount alternatives, the
`as bool?` cast crashed.

Fix: replace `ExpansionTile` with a local expand/collapse section that does not
touch PageStorage.

### Defect 2 — OCR letter O vs digit 0 (fixed)

Device OCR can read a printed zero as the letter `O`. The app must never
silently rewrite O/0, I/1, S/5, or B/8. Serial candidates that contain those
look-alikes show **Check ambiguous characters.** Manual correction remains
available. Hours stay numeric-only.

### Defect 3 — OCR-doubled hyphen (fixed; physical retest passed)

Device OCR sometimes reads one printed hyphen as two consecutive hyphens
(`ABC-123` → `ABC--123`). Consecutive ASCII hyphens are never allowed in a
stored serial: every run of two or more collapses to one (`ABC--123` /
`ABC---123` → `ABC-123`). Legitimate single hyphens (`SN-0099`) stay intact.
Letters and digits are never rewritten. Ambiguous-character warnings are
unchanged. Hour-meter parsing is unchanged. Manual consecutive hyphens also
collapse (founder-accepted).

## Manual Samsung S22 checklist

Device: Samsung S22. Physical-device QA for Draft PR #25 at `b2532ef`:
**complete / passed** (steps 1–15). Ready for Gunnar’s manual merge.

Status:
- [x] Steps 1–14 — passed on physical Samsung S22
- [x] Step 15 hyphen retest — passed on physical Samsung S22 at `b2532ef`
  (OCR-doubled hyphens collapse; saved/reopened value keeps one hyphen;
  manual consecutive hyphens also collapse)

Airplane mode recommended for offline proof.

1. Open Quick Appraisal for an in-progress local draft.
2. Capture the required serial-plate photo of a real data plate resembling
   `25-RC1H S/No 50252M6304 MAST ...`.
3. Scan the required serial photo (must not open the camera a second time).
   Recommended serial is `50252M6304` with the `S/No` label stripped.
4. Confirm `25-RC1H` is **not** recommended. Tire pressure, `HT kg 4140 1070`,
   dimensions, load-centre, capacity, tyre type, and production date must not
   appear as serial alternatives.
5. Tap the recommended serial once — it saves immediately. There is no second
   Confirm button. Reopen the draft; the serial is still present.
6. Rescan the same plate. The saved serial stays until you deliberately tap a
   different candidate or finish a manual replacement.
7. Retake the serial photo **at least three times** in a row (scroll the
   appraisal between retakes). No red error screen. Each successful retake
   remains previewable and usable for OCR. A failed save keeps the previous
   photo and the previously saved serial. OCR must not auto-replace the saved
   serial.
8. If OCR shows a letter where the plate has a digit (or the reverse), the
   candidate must keep the OCR characters as-read and show
   **Check ambiguous characters.** Correct via manual entry / Done — never
   expect an automatic O→0 rewrite.
9. Capture/scan a real hour meter. One recommended numeric reading appears.
   If OCR omitted a leading `1`, the shown value must match the characters
   that were read — never invent the missing digit. Correct it by editing the
   manual field and leaving the field / pressing Done.
10. Misleading plate numbers (weights, dates, capacities) must not be hour
    recommendations. Letter-like OCR in an hour field must not become digits.
11. Cancel a capture, force an OCR miss, and confirm the previous saved value
    remains. A persist/save error must restore the previous value with a
    recoverable banner.
12. Scroll the appraisal, save a serial/hour, and confirm scroll position
    stays usable.
13. Force-stop the app and reopen the draft — saved serial/hours are restored.
14. Repeat a serial tap + hour manual correction with airplane mode enabled.
15. **Hyphen retest (passed at `b2532ef`):** If OCR doubles a printed hyphen
    (`ABC--123`), the UI must show and save `ABC-123`. Saved and reopened
    values retain one hyphen. Manual consecutive hyphens also collapse
    (founder-accepted). Single hyphens such as `SN-0099` must remain. O/0
    ambiguous labeling must still appear when relevant. Hours must stay
    numeric-only.

No video artifacts. Screenshots only if a founder asks for a specific failure.
