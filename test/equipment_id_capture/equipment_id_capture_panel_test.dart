import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_controller.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/recognized_text_block.dart';
import 'package:ironsight_ai/features/equipment_id_capture/presentation/equipment_id_capture_labels.dart';
import 'package:ironsight_ai/features/equipment_id_capture/presentation/equipment_id_capture_panel.dart';

import '../support/fake_equipment_id_capture.dart';

void main() {
  Future<EquipmentIdCaptureController> pumpPanel(
    WidgetTester tester, {
    required EquipmentIdCaptureController controller,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: EquipmentIdCapturePanel(controller: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('shows accessible labels and unsupported fallback', (
    tester,
  ) async {
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: FakeImageCapture(isSupported: false),
      textRecognition: FakeTextRecognition(isSupported: false),
      cameraPermission: FakeCameraPermission(),
    );
    await pumpPanel(tester, controller: controller);

    expect(
      find.bySemanticsLabel(EquipmentIdCaptureLabels.serialManualField),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(EquipmentIdCaptureLabels.serialScanButton),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(EquipmentIdCaptureLabels.confirmButton),
      findsOneWidget,
    );
    expect(
      find.text(EquipmentIdCaptureLabels.unsupportedPlatformBanner),
      findsOneWidget,
    );
    expect(find.textContaining('Manual entry is always available'), findsOneWidget);
  });

  testWidgets('manual entry, candidate selection, and confirmation UX', (
    tester,
  ) async {
    final recognition = FakeTextRecognition(
      blocks: const [
        RecognizedTextBlock(rawText: 'SN-100'),
        RecognizedTextBlock(rawText: 'SN-200'),
      ],
    );
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: FakeImageCapture(),
      textRecognition: recognition,
      cameraPermission: FakeCameraPermission(),
    );
    await pumpPanel(tester, controller: controller);

    await tester.enterText(
      find.byType(TextFormField),
      'TYPED-BEFORE-SCAN',
    );
    await tester.pump();
    expect(controller.state.draftValue, 'TYPED-BEFORE-SCAN');

    await tester.tap(find.text('Scan with camera'));
    await tester.pumpAndSettle();

    expect(find.text('SN-100'), findsWidgets);
    expect(find.text('SN-200'), findsWidgets);
    expect(controller.state.isConfirmed, isFalse);

    await tester.tap(
      find.bySemanticsLabel(
        '${EquipmentIdCaptureLabels.candidatePrefix} SN-200',
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.state.selectedCandidateId, isNotNull);
    expect(controller.state.isConfirmed, isFalse);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Confirmed: SN-200'), findsOneWidget);
    expect(controller.state.isConfirmed, isTrue);
  });

  testWidgets('keyboard focus order reaches manual field then confirm', (
    tester,
  ) async {
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.hourMeter,
      imageCapture: FakeImageCapture(isSupported: false),
      textRecognition: FakeTextRecognition(isSupported: false),
      cameraPermission: FakeCameraPermission(),
    );
    await pumpPanel(tester, controller: controller);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), '42');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.state.isConfirmed, isTrue);
    expect(controller.state.confirmed!.value, '42');
  });

  testWidgets('failure recovery keeps manual text editable', (tester) async {
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: FakeImageCapture(isSupported: false),
      textRecognition: FakeTextRecognition(isSupported: false),
      cameraPermission: FakeCameraPermission(),
      initialDraftValue: 'RECOVER-ME',
    );
    await pumpPanel(tester, controller: controller);
    await tester.tap(find.text('Scan unavailable'));
    // Button disabled on unsupported — trigger via controller directly.
    await controller.captureAndRecognize();
    await tester.pumpAndSettle();

    expect(find.textContaining('not supported'), findsWidgets);
    expect(find.text('RECOVER-ME'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'RECOVER-ME-EDITED');
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Confirmed: RECOVER-ME-EDITED'), findsOneWidget);
  });
}
