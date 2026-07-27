# Equipment Identification Capture — Platform Support

Sprint 013 delivers a reusable offline capture module for equipment serial
numbers and hour-meter readings.

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

## Product rules

- OCR candidates are selectable, never silently accepted.
- Explicit **Confirm** is required.
- Manual entry is always visible.
- Capture services perform no network I/O.

## Integration note

This module is intentionally **not** wired into Sprint 012 inspection screens.
Future workflows (inspection and equipment) should construct
`EquipmentIdCaptureController` with platform bindings and embed
`EquipmentIdCapturePanel`.
