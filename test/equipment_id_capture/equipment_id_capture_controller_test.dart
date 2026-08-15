import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
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
    ConfirmedEquipmentIdValue? initialConfirmed,
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
      initialConfirmed: initialConfirmed,
    );
  }

  test('tapping a candidate immediately confirms it', () async {
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
    expect(controller.state.candidates.any((c) => c.isRecommended), isFalse);
    expect(
      controller.selectCandidate(controller.state.candidates.first.id),
      isTrue,
    );
    expect(controller.state.isConfirmed, isTrue);
    expect(controller.state.confirmed, isNotNull);
    expect(controller.state.draftValue, 'AAA111');
    expect(
      controller.state.confirmed!.method,
      EquipmentIdCaptureMethod.ocrConfirmed,
    );
  });

  test('OCR does not auto-save or pre-select a value', () async {
    final controller = buildSerial();
    await controller.captureAndRecognize();
    expect(controller.state.isConfirmed, isFalse);
    expect(controller.state.confirmed, isNull);
    expect(controller.state.candidates.single.isRecommended, isTrue);
    expect(controller.state.candidates.single.displayValue, 'CAT-001');
  });

  test('manual entry saves when editing is completed', () {
    final controller = buildSerial();
    controller.updateManualEntry('  SN-0099  ');
    expect(controller.state.isConfirmed, isFalse);
    expect(controller.completeManualEntry(), isTrue);
    expect(controller.state.confirmed!.method, EquipmentIdCaptureMethod.manual);
    expect(controller.state.confirmed!.value, 'SN-0099');
  });

  test('manual entry strips serial labels from the saved value', () {
    final controller = buildSerial();
    controller.updateManualEntry('S/No 50252M6304');
    expect(controller.completeManualEntry(), isTrue);
    expect(controller.state.confirmed!.value, '50252M6304');
  });

  test('OCR doubled hyphens collapse on one-tap persist', () async {
    final controller = buildSerial(
      textRecognition: FakeTextRecognition(
        blocks: const [RecognizedTextBlock(rawText: 'S/No ABC--123')],
      ),
    );
    await controller.captureAndRecognize();
    expect(controller.state.candidates.single.displayValue, 'ABC-123');
    expect(
      controller.selectCandidate(controller.state.candidates.single.id),
      isTrue,
    );
    expect(controller.state.confirmed!.value, 'ABC-123');
  });

  test('manual entry collapses consecutive hyphens on persist', () {
    final controller = buildSerial();
    controller.updateManualEntry('ABC---123');
    expect(controller.completeManualEntry(), isTrue);
    expect(controller.state.confirmed!.value, 'ABC-123');
  });

  test('single hyphen serials stay intact on persist', () {
    final controller = buildSerial();
    controller.updateManualEntry('SN-0099');
    expect(controller.completeManualEntry(), isTrue);
    expect(controller.state.confirmed!.value, 'SN-0099');
  });

  test('draft reopen shows the normalized hyphen serial', () {
    final controller = buildSerial(
      initialConfirmed: const ConfirmedEquipmentIdValue(
        kind: EquipmentIdCaptureKind.serialNumber,
        value: 'ABC-123',
        method: EquipmentIdCaptureMethod.ocrConfirmed,
      ),
    );
    expect(controller.state.isConfirmed, isTrue);
    expect(controller.state.confirmed!.value, 'ABC-123');
    expect(controller.state.draftValue, 'ABC-123');
  });

  test('OCR with doubled hyphens does not replace a saved serial', () async {
    final controller = buildSerial(
      initialConfirmed: const ConfirmedEquipmentIdValue(
        kind: EquipmentIdCaptureKind.serialNumber,
        value: 'KEEP-SERIAL',
        method: EquipmentIdCaptureMethod.manual,
      ),
      textRecognition: FakeTextRecognition(
        blocks: const [RecognizedTextBlock(rawText: 'S/No ABC--123')],
      ),
    );
    await controller.captureAndRecognize();
    expect(controller.state.confirmed!.value, 'KEEP-SERIAL');
    expect(controller.state.candidates.single.displayValue, 'ABC-123');
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
    expect(controller.completeManualEntry(), isTrue);
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
    expect(controller.completeManualEntry(), isFalse);
  });

  test('hour meter saves parsed positive value on completed edit', () {
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.hourMeter,
      imageCapture: FakeImageCapture(),
      textRecognition: FakeTextRecognition(),
      cameraPermission: FakeCameraPermission(),
    );
    controller.updateManualEntry('1,234.5');
    expect(controller.completeManualEntry(), isTrue);
    expect(controller.state.confirmed!.hours, 1234.5);
    expect(controller.state.confirmed!.value, '1234.5');
  });

  test(
    'incomplete hour OCR is not invented and can be corrected manually',
    () async {
      final controller = EquipmentIdCaptureController(
        kind: EquipmentIdCaptureKind.hourMeter,
        imageCapture: FakeImageCapture(),
        textRecognition: FakeTextRecognition(
          blocks: const [RecognizedTextBlock(rawText: 'HOURS 2345')],
        ),
        cameraPermission: FakeCameraPermission(),
      );
      await controller.captureAndRecognize();
      expect(controller.state.candidates.single.displayValue, '2345');
      expect(controller.state.isConfirmed, isFalse);
      controller.updateManualEntry('12345');
      expect(controller.completeManualEntry(), isTrue);
      expect(controller.state.confirmed!.hours, 12345);
    },
  );

  test('multiple hour candidates are not auto-saved', () async {
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
    expect(
      controller.selectCandidate(controller.state.candidates.last.id),
      isTrue,
    );
    expect(controller.state.isConfirmed, isTrue);
  });

  test('initialConfirmed seeds a confirmed state without silent OCR', () {
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: FakeImageCapture(isSupported: false),
      textRecognition: FakeTextRecognition(isSupported: false),
      cameraPermission: FakeCameraPermission(),
      initialConfirmed: const ConfirmedEquipmentIdValue(
        kind: EquipmentIdCaptureKind.serialNumber,
        value: 'SAVED1',
        method: EquipmentIdCaptureMethod.manual,
      ),
    );
    expect(controller.state.isConfirmed, isTrue);
    expect(controller.state.confirmed!.value, 'SAVED1');
    expect(controller.state.draftValue, 'SAVED1');
  });

  test(
    'recognizeExistingImage reuses a required photo without recapture',
    () async {
      final capture = FakeImageCapture();
      final ocr = FakeTextRecognition(
        blocks: const [RecognizedTextBlock(rawText: 'SN-REUSE-99')],
      );
      final controller = EquipmentIdCaptureController(
        kind: EquipmentIdCaptureKind.serialNumber,
        imageCapture: capture,
        textRecognition: ocr,
        cameraPermission: FakeCameraPermission(),
      );

      await controller.recognizeExistingImage(
        const CapturedImage(bytes: [9, 9, 9], path: '/tmp/required.jpg'),
      );

      expect(capture.captureCallCount, 0);
      expect(ocr.recognizeCallCount, 1);
      expect(controller.state.isConfirmed, isFalse);
      expect(controller.state.candidates.first.displayValue, 'SN-REUSE-99');
      expect(
        controller.selectCandidate(controller.state.candidates.first.id),
        isTrue,
      );
      expect(
        controller.state.confirmed!.method,
        EquipmentIdCaptureMethod.ocrConfirmed,
      );
      expect(controller.state.confirmed!.value, 'SN-REUSE-99');
    },
  );

  test('recognizeExistingImage OCR failure keeps prior confirmation', () async {
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: FakeImageCapture(isSupported: false),
      textRecognition: FakeTextRecognition(error: Exception('ocr down')),
      cameraPermission: FakeCameraPermission(),
      initialConfirmed: const ConfirmedEquipmentIdValue(
        kind: EquipmentIdCaptureKind.serialNumber,
        value: 'KEEPME',
        method: EquipmentIdCaptureMethod.manual,
      ),
    );

    await controller.recognizeExistingImage(
      const CapturedImage(bytes: [1], path: '/tmp/x.jpg'),
    );

    expect(controller.state.isConfirmed, isTrue);
    expect(controller.state.confirmed!.value, 'KEEPME');
    expect(
      controller.state.failure!.kind,
      EquipmentIdCaptureFailureKind.ocrFailure,
    );
  });

  test('rescan does not replace a saved value until a new tap', () async {
    final controller = buildSerial(
      initialConfirmed: const ConfirmedEquipmentIdValue(
        kind: EquipmentIdCaptureKind.serialNumber,
        value: 'SAVED-OLD',
        method: EquipmentIdCaptureMethod.manual,
      ),
      textRecognition: FakeTextRecognition(
        blocks: const [RecognizedTextBlock(rawText: 'S/No NEWER1234')],
      ),
    );
    await controller.captureAndRecognize();
    expect(controller.state.confirmed!.value, 'SAVED-OLD');
    expect(controller.state.candidates.first.displayValue, 'NEWER1234');
    expect(
      controller.selectCandidate(controller.state.candidates.first.id),
      isTrue,
    );
    expect(controller.state.confirmed!.value, 'NEWER1234');
  });

  test('persistence failure restores the previous saved value', () async {
    final controller = buildSerial(
      initialConfirmed: const ConfirmedEquipmentIdValue(
        kind: EquipmentIdCaptureKind.serialNumber,
        value: 'OLD-SAVE',
        method: EquipmentIdCaptureMethod.manual,
      ),
    );
    controller.updateManualEntry('NEW-SAVE');
    expect(controller.completeManualEntry(), isTrue);
    expect(controller.state.confirmed!.value, 'NEW-SAVE');
    controller.revertToLastSaved(
      EquipmentIdCaptureFailure.persistenceFailure(),
    );
    expect(controller.state.confirmed!.value, 'OLD-SAVE');
    expect(
      controller.state.failure!.kind,
      EquipmentIdCaptureFailureKind.persistenceFailure,
    );
  });

  test(
    'S22 plate OCR recommends 50252M6304 without model or plate noise',
    () async {
      final controller = buildSerial(
        textRecognition: FakeTextRecognition(
          blocks: const [
            RecognizedTextBlock(rawText: '25-RC1H S/No 50252M6304 MAST'),
            RecognizedTextBlock(rawText: 'HT kg 4140 1070'),
            RecognizedTextBlock(rawText: 'Tyre pressure 900 kPa'),
            RecognizedTextBlock(rawText: 'Load centre 500 mm'),
            RecognizedTextBlock(rawText: 'Capacity 2500 kg'),
            RecognizedTextBlock(rawText: 'Production date 2021'),
          ],
        ),
      );
      await controller.captureAndRecognize();
      final recommended = controller.state.candidates.where(
        (c) => c.isRecommended,
      );
      expect(recommended.single.displayValue, '50252M6304');
      expect(
        controller.state.candidates.map((c) => c.displayValue),
        isNot(contains('25-RC1H')),
      );
      expect(controller.state.isConfirmed, isFalse);
    },
  );
}
