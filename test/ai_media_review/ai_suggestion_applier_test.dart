import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/offline_inspection_workspace.dart';
import 'package:ironsight_ai/domain/ai/ai_media_source.dart';
import 'package:ironsight_ai/domain/ai/ai_suggestion.dart';
import 'package:ironsight_ai/domain/ai/ai_suggestion_applier.dart';
import 'package:ironsight_ai/domain/ai/ai_suggestion_kind.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_kind.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/equipment_id_capture_method.dart';

import '../support/fake_auth_session_reader.dart';
import '../support/fake_equipment_repository.dart';
import '../support/in_memory_inspection_media_file_store.dart';

AiSuggestion _suggestion({
  required String id,
  required AiSuggestionKind kind,
  String? value,
  double? hours,
}) {
  return AiSuggestion(
    id: id,
    kind: kind,
    confidence: AiSuggestionConfidence.medium,
    source: const AiMediaSource(
      type: AiMediaSourceType.photo,
      label: 'Serial / data plate',
    ),
    value: value,
    hourMeterHours: hours,
  );
}

void main() {
  late OfflineInspectionWorkspace workspace;

  setUp(() {
    workspace = OfflineInspectionWorkspace.fromDatabase(
      database: openMemoryAppDatabase(),
      remoteEquipmentRepository: FakeEquipmentRepository(),
      authSession: FakeAuthSessionReader(),
      mediaFiles: InMemoryInspectionMediaFileStore(),
    );
  });

  tearDown(() async {
    await workspace.dispose();
  });

  Future<String> openDraft({String companyId = 'company-a'}) async {
    await workspace.equipmentCatalog.replaceCompanyCatalog(
      companyId: companyId,
      equipment: [
        Equipment(
          id: 'eq-1',
          companyId: companyId,
          assetName: 'Loader',
          manufacturer: 'Cat',
          model: '950',
          createdAt: DateTime.utc(2026, 8, 1),
          updatedAt: DateTime.utc(2026, 8, 1),
        ),
      ],
    );
    final draft = await workspace.inspections.createDraft(
      companyId: companyId,
      equipmentId: 'eq-1',
      createdByUserId: 'user-1',
    );
    return draft.id;
  }

  test('dismissing does not mutate inspection data', () async {
    final id = await openDraft();
    final before = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: id,
    );
    final applier = AiSuggestionApplier(inspections: workspace.inspections);
    final outcome = await applier.dismiss(
      _suggestion(
        id: 's1',
        kind: AiSuggestionKind.manufacturer,
        value: 'Volvo',
      ),
    );
    final after = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: id,
    );
    expect(outcome.status, AiApplyStatus.dismissed);
    expect(after!.serialNumber, before!.serialNumber);
    expect(after.overallNotes, before.overallNotes);
  });

  test(
    'applying serial and hours persists through local inspection storage',
    () async {
      final id = await openDraft();
      final applier = AiSuggestionApplier(inspections: workspace.inspections);
      final inspection = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: id,
      );
      final serial = await applier.apply(
        companyId: 'company-a',
        inspectionId: id,
        userId: 'user-1',
        inspection: inspection!,
        suggestion: _suggestion(
          id: 's-serial',
          kind: AiSuggestionKind.serialNumber,
          value: 'SN-0099',
        ),
      );
      expect(serial.status, AiApplyStatus.applied);
      expect(serial.inspection!.serialNumber, 'SN-0099');

      final hours = await applier.apply(
        companyId: 'company-a',
        inspectionId: id,
        userId: 'user-1',
        inspection: serial.inspection!,
        suggestion: _suggestion(
          id: 's-hours',
          kind: AiSuggestionKind.hourMeter,
          value: '321',
          hours: 321,
        ),
      );
      expect(hours.status, AiApplyStatus.applied);
      expect(hours.inspection!.hourMeterReading, 321);

      final reloaded = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: id,
      );
      expect(reloaded!.serialNumber, 'SN-0099');
      expect(reloaded.hourMeterReading, 321);
    },
  );

  test(
    'existing confirmed serial and hours stay protected until replace',
    () async {
      final id = await openDraft();
      await workspace.inspections.saveConfirmedEquipmentId(
        companyId: 'company-a',
        inspectionId: id,
        confirmedValue: const ConfirmedEquipmentIdValue(
          kind: EquipmentIdCaptureKind.serialNumber,
          value: 'CONFIRMED-1',
          method: EquipmentIdCaptureMethod.manual,
        ),
      );
      await workspace.inspections.saveConfirmedEquipmentId(
        companyId: 'company-a',
        inspectionId: id,
        confirmedValue: const ConfirmedEquipmentIdValue(
          kind: EquipmentIdCaptureKind.hourMeter,
          value: '100',
          method: EquipmentIdCaptureMethod.manual,
          hours: 100,
        ),
      );
      final inspection = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: id,
      );
      final applier = AiSuggestionApplier(inspections: workspace.inspections);

      final blockedSerial = await applier.apply(
        companyId: 'company-a',
        inspectionId: id,
        userId: 'user-1',
        inspection: inspection!,
        suggestion: _suggestion(
          id: 's-serial',
          kind: AiSuggestionKind.serialNumber,
          value: 'AI-NEW',
        ),
      );
      expect(blockedSerial.status, AiApplyStatus.needsReplaceConfirmation);
      expect(
        (await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: id,
        ))!.serialNumber,
        'CONFIRMED-1',
      );

      final replaced = await applier.apply(
        companyId: 'company-a',
        inspectionId: id,
        userId: 'user-1',
        inspection: inspection,
        suggestion: _suggestion(
          id: 's-serial',
          kind: AiSuggestionKind.serialNumber,
          value: 'AI-NEW',
        ),
        replaceExisting: true,
      );
      expect(replaced.status, AiApplyStatus.applied);
      expect(replaced.inspection!.serialNumber, 'AI-NEW');
      expect(replaced.inspection!.hourMeterReading, 100);
    },
  );

  test('missing hour digits are not applied', () async {
    final id = await openDraft();
    final inspection = await workspace.inspections.getById(
      companyId: 'company-a',
      inspectionId: id,
    );
    final applier = AiSuggestionApplier(inspections: workspace.inspections);
    final outcome = await applier.apply(
      companyId: 'company-a',
      inspectionId: id,
      userId: 'user-1',
      inspection: inspection!,
      suggestion: _suggestion(
        id: 's-hours',
        kind: AiSuggestionKind.hourMeter,
        value: '12??',
      ),
    );
    expect(outcome.status, AiApplyStatus.rejected);
    expect(
      (await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: id,
      ))!.hourMeterReading,
      isNull,
    );
  });

  test(
    'condition observations append editable notes without ratings',
    () async {
      final id = await openDraft();
      await workspace.inspections.updateMetadata(
        companyId: 'company-a',
        inspectionId: id,
        overallNotes: 'Human note',
      );
      final inspection = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: id,
      );
      final applier = AiSuggestionApplier(inspections: workspace.inspections);
      final outcome = await applier.apply(
        companyId: 'company-a',
        inspectionId: id,
        userId: 'user-1',
        inspection: inspection!,
        suggestion: _suggestion(
          id: 's-rust',
          kind: AiSuggestionKind.rust,
          value: 'Surface rust on boom',
        ),
        editedValue: 'Light rust on boom, reviewed',
      );
      expect(outcome.status, AiApplyStatus.applied);
      expect(outcome.inspection!.overallNotes, contains('Human note'));
      expect(
        outcome.inspection!.overallNotes,
        contains('Light rust on boom, reviewed'),
      );
      expect(outcome.inspection!.overallNotes, isNot(contains('Good')));
    },
  );

  test(
    'tenant isolation: company B cannot apply onto company A draft',
    () async {
      final id = await openDraft();
      final inspection = await workspace.inspections.getById(
        companyId: 'company-a',
        inspectionId: id,
      );
      final applier = AiSuggestionApplier(inspections: workspace.inspections);
      final outcome = await applier.apply(
        companyId: 'company-b',
        inspectionId: id,
        userId: 'user-b',
        inspection: inspection!,
        suggestion: _suggestion(
          id: 's1',
          kind: AiSuggestionKind.manufacturer,
          value: 'Volvo',
        ),
      );
      expect(outcome.status, AiApplyStatus.rejected);
      expect(
        (await workspace.inspections.getById(
          companyId: 'company-a',
          inspectionId: id,
        ))!.overallNotes,
        isNull,
      );
    },
  );
}
