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
  hour parsing, confirmation controller, and narrow ports
  (`ImageCapturePort`, `TextRecognitionPort`, `CameraPermissionPort`).
- **Data / platform** (`lib/data/equipment_id_capture/`): `camera`,
  `permission_handler`, and ML Kit adapters. Vendor types do not leak into
  domain entities.
- **Presentation** (`lib/features/equipment_id_capture/presentation/`):
  reusable `EquipmentIdCapturePanel` that depends only on the domain
  controller — never on camera/OCR packages directly.
- **Quick Appraisal integration**
  (`lib/features/inspection/presentation/inspection_workspace_screen.dart`):
  embeds serial and hour panels; persists only after explicit Confirm via
  `LocalInspectionRepository.saveConfirmedEquipmentId`.

## Product rules

- OCR candidates are selectable, never silently accepted.
- Explicit **Confirm** is required.
- Manual entry is always visible.
- Capture services perform no network I/O.
- Confirmed serial / hours are stored on the **local inspection draft**
  (not rewritten into equipment-master cache by this flow).
- Values survive draft reopen and app restart (Drift schema v3 local columns).
- Cancelling capture or OCR failure leaves existing draft input intact.
- Quick Appraisal scroll position is preserved across capture confirm saves.

## Manual Samsung S22 checklist (Issue #20)

Device: Samsung S22. Airplane mode recommended for offline proof.

1. Open Quick Appraisal for an in-progress local draft.
2. Deny camera permission once → banner/guidance appears; manual entry still works.
3. Allow camera; scan a serial plate → candidates appear; value is **not** saved until Confirm.
4. Select a candidate and Confirm → serial persists; leave and reopen draft → still present.
5. Cancel mid-capture → previous serial (if any) remains.
6. Scan hour meter; Confirm → hours persist across kill/relaunch of the app.
7. Force an OCR miss / failure path → recoverable message; type hours manually and Confirm.
8. Scroll down the appraisal, confirm a value, return → scroll position remains usable.
9. Complete Review and verify confirmed serial/hours are shown for this inspection.
10. Confirm the whole flow still works with airplane mode enabled.

No video artifacts. Screenshots only if a founder asks for a specific failure.
