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
- Weaker field-valid values sit behind **Other possibilities**.
- Tapping a candidate is explicit human confirmation and saves immediately.
- Manual entry is always visible and saves when editing is completed.
- There is no second Confirm button for candidate selection or manual save.
- Capture services perform no network I/O.
- Saved serial / hours are stored on the **local inspection draft**
  (not rewritten into equipment-master cache by this flow).
- Values survive draft reopen and app restart (Drift schema v3 local columns).
- Rescanning never replaces a saved value unless the user taps or types a
  replacement. Cancelled capture, OCR failure, or persist failure keeps the
  previous saved value.
- Quick Appraisal scroll position is preserved across equipment-ID saves.

## Manual Samsung S22 checklist

Device: Samsung S22. Keep the PR Draft until this physical-device pass is done.
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
7. Capture/scan a real hour meter. One recommended numeric reading appears.
   If OCR omitted a leading `1`, the shown value must match the characters
   that were read — never invent the missing digit. Correct it by editing the
   manual field and leaving the field / pressing Done.
8. Misleading plate numbers (weights, dates, capacities) must not be hour
   recommendations.
9. Cancel a capture, force an OCR miss, and confirm the previous saved value
   remains. A persist/save error must restore the previous value with a
   recoverable banner.
10. Scroll the appraisal, save a serial/hour, and confirm scroll position
    stays usable.
11. Force-stop the app and reopen the draft — saved serial/hours are restored.
12. Repeat a serial tap + hour manual correction with airplane mode enabled.

No video artifacts. Screenshots only if a founder asks for a specific failure.
