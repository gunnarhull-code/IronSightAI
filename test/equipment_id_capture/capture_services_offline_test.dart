import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/equipment_id_capture/create_platform_bindings.dart';
import 'package:ironsight_ai/data/equipment_id_capture/unsupported_and_callback_capture.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_controller.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/recognized_text_block.dart';

import '../support/fake_equipment_id_capture.dart';

void main() {
  test('capture controller + fakes complete without network I/O', () async {
    final imageCapture = FakeImageCapture();
    final recognition = FakeTextRecognition(
      blocks: const [RecognizedTextBlock(rawText: 'OFFLINE-1')],
    );
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: imageCapture,
      textRecognition: recognition,
      cameraPermission: FakeCameraPermission(),
    );

    await controller.captureAndRecognize();
    controller.selectCandidate(controller.state.candidates.single.id);
    expect(controller.confirm(), isTrue);

    expect(recognition.usedNetwork, isFalse);
    expect(imageCapture.captureCallCount, 1);
    expect(recognition.recognizeCallCount, 1);
  });

  test('unsupported bindings expose manual-only capture ports', () {
    final bindings = createPlatformEquipmentIdCaptureBindings(
      forceUnsupported: true,
    );
    expect(bindings.imageCapture.isSupported, isFalse);
    expect(bindings.textRecognition.isSupported, isFalse);
  });

  test('callback image capture stays local', () async {
    final capture = CallbackImageCapture(
      capture: () async =>
          const CapturedImage(bytes: [9, 9, 9], path: '/tmp/local.jpg'),
    );
    final image = await capture.captureStill();
    expect(image.path, '/tmp/local.jpg');
    expect(image.bytes, isNotEmpty);
  });

  test('data-layer capture files do not import network clients', () async {
    const roots = [
      'lib/data/equipment_id_capture',
      'lib/domain/equipment_id_capture',
      'lib/features/equipment_id_capture',
    ];
    final forbidden = RegExp(
      r"import\s+'package:(http|dio|supabase_flutter|supabase)/",
    );
    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = await entity.readAsString();
        expect(
          forbidden.hasMatch(source),
          isFalse,
          reason: '${entity.path} must not import network clients',
        );
      }
    }
  });
}
