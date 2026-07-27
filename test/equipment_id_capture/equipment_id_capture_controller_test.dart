import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_controller.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_failure.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_method.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/image_capture_port.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/recognized_text_block.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/camera_permission_port.dart';

import '../support/fake_equipment_id_capture.dart';

void main() {
  EquipmentIdCaptureController buildSerial({
    FakeImageCapture? imageCapture,
    FakeTextRecognition? textRecognition,
    FakeCameraPermission? permission,
    String initialDraftValue = '',
  }) {
    return EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: imageCapture ?? FakeImageCapture(),
      textRecognition:
          textRecognition ??
          FakeTextRecognition(
            blocks: const [RecognizedTextBlock(rawText: 'CAT-001')],
          ),
      cameraPermission: permission ?? FakeCameraPermission(),
      initialDraftValue: initialDraftValue,
    );
  }

  test('selecting a candidate does not confirm', () async {
    final controller = buildSerial(
      textRecognition: FakeTextRecognition(
        blocks: const [
          RecognizedTextBlock(rawText: 'AAA111'),
          RecognizedTextBlock(rawText: 'BBB222'),
        ],
      ),
    );
    await controller.captureAndRecognize();
    expect(controller.state.candidates, hasLength(2));
    controller.selectCandidate(controller.state.candidates.first.id);
    expect(
      controller.state.phase,
      EquipmentIdCapturePhase.awaitingConfirmation,
    );
    expect(controller.state.isConfirmed, isFalse);
    expect(controller.state.confirmed, isNull);
    expect(controller.state.draftValue, 'AAA111');
  });

  test('explicit confirmation is required for OCR candidate', () async {
    final controller = buildSerial();
    await controller.captureAndRecognize();
    controller.selectCandidate(controller.state.candidates.single.id);
    expect(controller.confirm(), isTrue);
    expect(controller.state.isConfirmed, isTrue);
    expect(
      controller.state.confirmed!.method,
      EquipmentIdCaptureMethod.ocrConfirmed,
    );
    expect(controller.state.confirmed!.value, 'CAT-001');
  });

  test('manual entry and editing can be confirmed', () {
    final controller = buildSerial();
    controller.updateManualEntry('  SN-0099  ');
    expect(controller.state.isConfirmed, isFalse);
    expect(controller.confirm(), isTrue);
    expect(controller.state.confirmed!.method, EquipmentIdCaptureMethod.manual);
    expect(controller.state.confirmed!.value, 'SN-0099');
  });

  test('permission denied preserves manual draft', () async {
    final controller = buildSerial(
      permission: FakeCameraPermission(
        requestStatus: CameraPermissionStatus.denied,
      ),
      initialDraftValue: 'KEEP-ME',
    );
    await controller.captureAndRecognize();
    expect(
      controller.state.failure!.kind,
      EquipmentIdCaptureFailureKind.permissionDenied,
    );
    expect(controller.state.draftValue, 'KEEP-ME');
    expect(controller.state.isConfirmed, isFalse);
  });

  test('permanently denied permission provides guidance', () async {
    final controller = buildSerial(
      permission: FakeCameraPermission(
        requestStatus: CameraPermissionStatus.permanentlyDenied,
      ),
    );
    await controller.captureAndRecognize();
    expect(
      controller.state.failure!.kind,
      EquipmentIdCaptureFailureKind.permissionPermanentlyDenied,
    );
    expect(controller.state.failure!.guidance, contains('settings'));
  });

  test('no text detected preserves manual draft', () async {
    final controller = buildSerial(
      textRecognition: FakeTextRecognition(blocks: const []),
      initialDraftValue: 'MANUAL-1',
    );
    await controller.captureAndRecognize();
    expect(
      controller.state.failure!.kind,
      EquipmentIdCaptureFailureKind.noTextDetected,
    );
    expect(controller.state.draftValue, 'MANUAL-1');
  });

  test('capture cancellation preserves manual draft', () async {
    final controller = buildSerial(
      imageCapture: FakeImageCapture(
        error: EquipmentIdCaptureException(
          EquipmentIdCaptureFailure.captureCancelled(),
        ),
      ),
      initialDraftValue: 'TYPED',
    );
    await controller.captureAndRecognize();
    expect(
      controller.state.failure!.kind,
      EquipmentIdCaptureFailureKind.captureCancelled,
    );
    expect(controller.state.draftValue, 'TYPED');
  });

  test('OCR failure preserves manual draft', () async {
    final controller = buildSerial(
      textRecognition: FakeTextRecognition(error: Exception('native crash')),
      initialDraftValue: 'STILL-HERE',
    );
    await controller.captureAndRecognize();
    expect(
      controller.state.failure!.kind,
      EquipmentIdCaptureFailureKind.ocrFailure,
    );
    expect(controller.state.draftValue, 'STILL-HERE');
  });

  test('unsupported platform falls back to manual entry', () async {
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: FakeImageCapture(isSupported: false),
      textRecognition: FakeTextRecognition(isSupported: false),
      cameraPermission: FakeCameraPermission(
        requestStatus: CameraPermissionStatus.unavailable,
      ),
      initialDraftValue: 'WEB-VALUE',
    );
    expect(controller.state.cameraOcrSupported, isFalse);
    await controller.captureAndRecognize();
    expect(
      controller.state.failure!.kind,
      EquipmentIdCaptureFailureKind.unsupportedPlatform,
    );
    expect(controller.state.draftValue, 'WEB-VALUE');
    expect(controller.confirm(), isTrue);
    expect(controller.state.confirmed!.method, EquipmentIdCaptureMethod.manual);
  });

  test('hour meter rejects negative manual values', () {
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.hourMeter,
      imageCapture: FakeImageCapture(),
      textRecognition: FakeTextRecognition(),
      cameraPermission: FakeCameraPermission(),
    );
    controller.updateManualEntry('-10');
    expect(controller.state.canConfirm, isFalse);
    expect(controller.confirm(), isFalse);
  });

  test('hour meter confirms parsed positive value', () {
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.hourMeter,
      imageCapture: FakeImageCapture(),
      textRecognition: FakeTextRecognition(),
      cameraPermission: FakeCameraPermission(),
    );
    controller.updateManualEntry('1,234.5');
    expect(controller.confirm(), isTrue);
    expect(controller.state.confirmed!.hours, 1234.5);
    expect(controller.state.confirmed!.value, '1234.5');
  });

  test('multiple hour candidates require selection and confirmation', () async {
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.hourMeter,
      imageCapture: FakeImageCapture(),
      textRecognition: FakeTextRecognition(
        blocks: const [
          RecognizedTextBlock(rawText: 'HOURS 100'),
          RecognizedTextBlock(rawText: 'TOTAL 250'),
        ],
      ),
      cameraPermission: FakeCameraPermission(),
    );
    await controller.captureAndRecognize();
    expect(controller.state.candidates.length, greaterThanOrEqualTo(2));
    expect(controller.state.isConfirmed, isFalse);
    controller.selectCandidate(controller.state.candidates.last.id);
    expect(controller.confirm(), isTrue);
  });
}
