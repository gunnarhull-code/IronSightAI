import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/entities/condition_rating.dart';
import 'package:ironsight_ai/domain/entities/detailed_category_response.dart';
import 'package:ironsight_ai/domain/entities/equipment.dart';
import 'package:ironsight_ai/domain/entities/inspection.dart';
import 'package:ironsight_ai/domain/entities/inspection_depth.dart';
import 'package:ironsight_ai/domain/entities/inspection_status.dart';
import 'package:ironsight_ai/domain/entities/scorecard_category.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/confirmed_equipment_id_value.dart';
import 'package:ironsight_ai/domain/repositories/local_equipment_catalog_repository.dart';
import 'package:ironsight_ai/domain/repositories/local_inspection_repository.dart';
import 'package:ironsight_ai/features/inspection/presentation/inspection_equipment_select_screen.dart';

/// The S22 failure surfaced an inspection-read error behind equipment-cache
/// wording. Draft-start failures must name the layer that actually failed.
void main() {
  final equipment = Equipment(
    id: 'eq-1',
    companyId: 'company-a',
    assetName: 'Loader 1',
    manufacturer: 'Caterpillar',
    model: '950',
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
  );

  Future<void> pumpAndSelect(
    WidgetTester tester, {
    required LocalInspectionRepository inspections,
    required LocalEquipmentCatalogRepository equipmentCatalog,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InspectionEquipmentSelectScreen(
          companyId: 'company-a',
          userId: 'user-1',
          inspections: inspections,
          equipmentCatalog: equipmentCatalog,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loader 1'));
    await tester.pumpAndSettle();
  }

  testWidgets('inspection read failure is not blamed on the equipment cache', (
    tester,
  ) async {
    await pumpAndSelect(
      tester,
      inspections: _FakeInspectionRepository(
        listError: StateError('inspection read failed'),
      ),
      equipmentCatalog: _FakeEquipmentCatalog(equipment: equipment),
    );

    expect(
      find.textContaining('Local inspection data could not be read'),
      findsOneWidget,
    );
    expect(find.textContaining('Check equipment cache'), findsNothing);
  });

  testWidgets('missing cached equipment still points at the equipment cache', (
    tester,
  ) async {
    await pumpAndSelect(
      tester,
      inspections: _FakeInspectionRepository(),
      equipmentCatalog: _FakeEquipmentCatalog(
        equipment: equipment,
        dropAfterListing: true,
      ),
    );

    expect(find.textContaining('Check equipment cache'), findsOneWidget);
    expect(
      find.textContaining('Local inspection data could not be read'),
      findsNothing,
    );
  });
}

class _FakeEquipmentCatalog implements LocalEquipmentCatalogRepository {
  _FakeEquipmentCatalog({
    required this.equipment,
    this.dropAfterListing = false,
  });

  final Equipment equipment;

  /// Mimics a catalog row that disappears between listing and selection.
  final bool dropAfterListing;

  @override
  Future<List<Equipment>> listForCompany(String companyId) async => [equipment];

  @override
  Future<Equipment?> getById({
    required String companyId,
    required String equipmentId,
  }) async {
    if (dropAfterListing) return null;
    return equipmentId == equipment.id ? equipment : null;
  }

  @override
  Future<void> replaceCompanyCatalog({
    required String companyId,
    required List<Equipment> equipment,
  }) async => throw UnimplementedError();

  @override
  Future<void> upsertEquipment(Equipment equipment) async =>
      throw UnimplementedError();

  @override
  Future<void> removeEquipment({
    required String companyId,
    required String equipmentId,
  }) async => throw UnimplementedError();

  @override
  Future<void> clearCompany(String companyId) async =>
      throw UnimplementedError();

  @override
  Future<void> clearAllExceptCompany(String companyId) async =>
      throw UnimplementedError();

  @override
  Future<void> clearAll() async => throw UnimplementedError();
}

class _FakeInspectionRepository implements LocalInspectionRepository {
  _FakeInspectionRepository({this.listError});

  final Object? listError;

  @override
  Future<List<Inspection>> listForCompany(
    String companyId, {
    bool includeDiscarded = false,
  }) async {
    final error = listError;
    if (error != null) throw error;
    return const [];
  }

  @override
  Future<Inspection> createDraft({
    required String companyId,
    required String equipmentId,
    required String createdByUserId,
    InspectionDepth depth = InspectionDepth.quickAppraisal,
  }) => throw StateError('createDraft should not run in these cases');

  @override
  Future<Inspection?> getById({
    required String companyId,
    required String inspectionId,
  }) => throw UnimplementedError();

  @override
  Future<Inspection> updateMetadata({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
    InspectionDepth? depth,
    String? overallNotes,
    bool clearOverallNotes = false,
    String? remoteId,
    bool clearRemoteId = false,
    InspectionSyncStatus? syncStatus,
    InspectionReportStatus? reportStatus,
  }) => throw UnimplementedError();

  @override
  Future<Inspection> saveCategoryRating({
    required String companyId,
    required String inspectionId,
    required ScorecardCategory category,
    required ConditionRating rating,
    String? updatedByUserId,
  }) => throw UnimplementedError();

  @override
  Future<Inspection> saveDetailedCategoryResponse({
    required String companyId,
    required String inspectionId,
    required DetailedCategoryResponse response,
    String? updatedByUserId,
  }) => throw UnimplementedError();

  @override
  Future<Inspection> discardIncomplete({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) => throw UnimplementedError();

  @override
  Future<Inspection> complete({
    required String companyId,
    required String inspectionId,
    String? updatedByUserId,
  }) => throw UnimplementedError();

  @override
  Future<Inspection> saveConfirmedEquipmentId({
    required String companyId,
    required String inspectionId,
    required ConfirmedEquipmentIdValue confirmedValue,
    String? updatedByUserId,
  }) => throw UnimplementedError();
}
