import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_controller.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_failure.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_method.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/recognized_text_block.dart';
import 'package:ironsight_ai/features/equipment_id_capture/presentation/equipment_id_capture_labels.dart';
import 'package:ironsight_ai/features/equipment_id_capture/presentation/equipment_id_capture_panel.dart';

import '../support/fake_equipment_id_capture.dart';

String _candidateSemantics(String value, {required bool recommended}) {
  final prefix = recommended
      ? EquipmentIdCaptureLabels.recommendedPrefix
      : EquipmentIdCaptureLabels.alternativePrefix;
  final ambiguous = RegExp(r'[O0I1lLS5B8]').hasMatch(value)
      ? ' ${EquipmentIdCaptureLabels.ambiguousCharactersHint}'
      : '';
  return '$prefix $value$ambiguous';
}

void main() {
  Future<EquipmentIdCaptureController> pumpPanel(
    WidgetTester tester, {
    required EquipmentIdCaptureController controller,
    Future<void> Function(ConfirmedEquipmentIdValue value)? onPersist,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: EquipmentIdCapturePanel(
                controller: controller,
                onPersist: onPersist,
              ),
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
    expect(find.text('Confirm'), findsNothing);
    expect(
      find.text(EquipmentIdCaptureLabels.unsupportedPlatformBanner),
      findsOneWidget,
    );
    expect(
      find.textContaining('Manual entry is always available'),
      findsOneWidget,
    );
  });

  testWidgets('candidate tap saves immediately without a Confirm button', (
    tester,
  ) async {
    final persisted = <ConfirmedEquipmentIdValue>[];
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
    await pumpPanel(
      tester,
      controller: controller,
      onPersist: (value) async => persisted.add(value),
    );

    await tester.tap(find.text('Scan with camera'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm'), findsNothing);
    expect(
      find.text(EquipmentIdCaptureLabels.otherPossibilities),
      findsOneWidget,
    );
    await tester.tap(
      find.bySemanticsLabel(EquipmentIdCaptureLabels.expandOtherPossibilities),
    );
    await tester.pumpAndSettle();

    expect(find.text('SN-100'), findsWidgets);
    expect(find.text('SN-200'), findsWidgets);

    await tester.tap(
      find.bySemanticsLabel(
        '${EquipmentIdCaptureLabels.alternativePrefix} SN-200 '
        '${EquipmentIdCaptureLabels.ambiguousCharactersHint}',
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.state.isConfirmed, isTrue);
    expect(find.textContaining('Saved: SN-200'), findsOneWidget);
    expect(persisted.single.value, 'SN-200');
    expect(persisted.single.method, EquipmentIdCaptureMethod.ocrConfirmed);
  });

  testWidgets('keyboard done saves manual entry without Confirm', (
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
    expect(find.textContaining('Saved: 42'), findsOneWidget);
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
    await controller.captureAndRecognize();
    await tester.pumpAndSettle();

    expect(find.textContaining('not supported'), findsWidgets);
    expect(find.text('RECOVER-ME'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'RECOVER-ME-EDITED');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved: RECOVER-ME-EDITED'), findsOneWidget);
  });

  testWidgets(
    'accessibility labels distinguish recommendation and saved state',
    (tester) async {
      final controller = EquipmentIdCaptureController(
        kind: EquipmentIdCaptureKind.serialNumber,
        imageCapture: FakeImageCapture(),
        textRecognition: FakeTextRecognition(
          blocks: const [RecognizedTextBlock(rawText: 'S/No 50252M6304')],
        ),
        cameraPermission: FakeCameraPermission(),
      );
      await pumpPanel(tester, controller: controller);
      await tester.tap(find.text('Scan with camera'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          _candidateSemantics('50252M6304', recommended: true),
        ),
        findsOneWidget,
      );
      expect(
        find.text(EquipmentIdCaptureLabels.ambiguousCharactersHint),
        findsWidgets,
      );
      await tester.tap(
        find.bySemanticsLabel(
          _candidateSemantics('50252M6304', recommended: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          '${EquipmentIdCaptureLabels.savedStatePrefix} 50252M6304',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('ambiguous OCR letter O is not silently changed to zero', (
    tester,
  ) async {
    final persisted = <ConfirmedEquipmentIdValue>[];
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: FakeImageCapture(),
      textRecognition: FakeTextRecognition(
        blocks: const [RecognizedTextBlock(rawText: 'S/No 5O252M63O4')],
      ),
      cameraPermission: FakeCameraPermission(),
    );
    await pumpPanel(
      tester,
      controller: controller,
      onPersist: (value) async => persisted.add(value),
    );
    await tester.tap(find.text('Scan with camera'));
    await tester.pumpAndSettle();

    expect(find.text('5O252M63O4'), findsWidgets);
    expect(find.text('50252M6304'), findsNothing);
    expect(
      find.text(EquipmentIdCaptureLabels.ambiguousCharactersHint),
      findsWidgets,
    );

    await tester.tap(
      find.bySemanticsLabel(
        _candidateSemantics('5O252M63O4', recommended: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(persisted.single.value, '5O252M63O4');
  });

  testWidgets('doubled-hyphen OCR displays and persists collapsed serial', (
    tester,
  ) async {
    final persisted = <ConfirmedEquipmentIdValue>[];
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: FakeImageCapture(),
      textRecognition: FakeTextRecognition(
        blocks: const [RecognizedTextBlock(rawText: 'S/No ABC--123')],
      ),
      cameraPermission: FakeCameraPermission(),
    );
    await pumpPanel(
      tester,
      controller: controller,
      onPersist: (value) async => persisted.add(value),
    );
    await tester.tap(find.text('Scan with camera'));
    await tester.pumpAndSettle();

    expect(find.text('ABC-123'), findsWidgets);
    expect(find.text('ABC--123'), findsNothing);

    await tester.tap(
      find.bySemanticsLabel(_candidateSemantics('ABC-123', recommended: true)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved: ABC-123'), findsOneWidget);
    expect(persisted.single.value, 'ABC-123');
  });

  testWidgets('manual doubled hyphens persist collapsed without Confirm', (
    tester,
  ) async {
    final persisted = <ConfirmedEquipmentIdValue>[];
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: FakeImageCapture(isSupported: false),
      textRecognition: FakeTextRecognition(isSupported: false),
      cameraPermission: FakeCameraPermission(),
    );
    await pumpPanel(
      tester,
      controller: controller,
      onPersist: (value) async => persisted.add(value),
    );

    await tester.enterText(find.byType(TextFormField), 'ABC---123');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.state.confirmed!.value, 'ABC-123');
    expect(find.textContaining('Saved: ABC-123'), findsOneWidget);
    expect(persisted.single.value, 'ABC-123');
  });

  testWidgets('persist failure restores previous saved value', (tester) async {
    final controller = EquipmentIdCaptureController(
      kind: EquipmentIdCaptureKind.serialNumber,
      imageCapture: FakeImageCapture(isSupported: false),
      textRecognition: FakeTextRecognition(isSupported: false),
      cameraPermission: FakeCameraPermission(),
      initialConfirmed: const ConfirmedEquipmentIdValue(
        kind: EquipmentIdCaptureKind.serialNumber,
        value: 'KEEP-OLD',
        method: EquipmentIdCaptureMethod.manual,
      ),
    );
    await pumpPanel(
      tester,
      controller: controller,
      onPersist: (value) async {
        throw StateError('disk full');
      },
    );

    await tester.enterText(find.byType(TextFormField), 'NEW-VALUE');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(controller.state.confirmed!.value, 'KEEP-OLD');
    expect(
      controller.state.failure!.kind,
      EquipmentIdCaptureFailureKind.persistenceFailure,
    );
    expect(
      find.bySemanticsLabel(EquipmentIdCaptureLabels.saveError),
      findsOneWidget,
    );
    expect(find.textContaining('Saved: KEEP-OLD'), findsOneWidget);
  });
}
