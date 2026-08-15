import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/local/drift/open_inspection_database_io.dart';
import 'package:ironsight_ai/data/local/inspection_media_file_store.dart';
import 'package:ironsight_ai/data/repositories/drift_local_inspection_media_repository.dart';
import 'package:ironsight_ai/data/repositories/drift_local_inspection_repository.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';
import 'package:ironsight_ai/domain/exceptions/invalid_inspection_lifecycle_exception.dart';
import 'package:ironsight_ai/domain/repositories/local_inspection_media_repository.dart';
import 'package:ironsight_ai/domain/repositories/local_inspection_repository.dart';

void main() {
  late Directory mediaRoot;
  late LocalInspectionRepository inspections;
  late LocalInspectionMediaRepository media;
  var clockTick = 0;
  var idTick = 0;

  DateTime nextClock() {
    clockTick += 1;
    return DateTime.utc(2026, 8, 4, 12, 0, clockTick);
  }

  String nextId() {
    idTick += 1;
    return 'media-id-$idTick';
  }

  setUp(() {
    clockTick = 0;
    idTick = 0;
    mediaRoot = Directory.systemTemp.createTempSync('ironsight_media_repo_');
    final database = openMemoryAppDatabase();
    inspections = DriftLocalInspectionRepository(
      database,
      clock: nextClock,
      idGenerator: nextId,
    );
    media = DriftLocalInspectionMediaRepository(
      database,
      inspections,
      InspectionMediaFileStore(documentsDirectoryOverride: () => mediaRoot),
      clock: nextClock,
      idGenerator: nextId,
    );
  });

  tearDown(() {
    if (mediaRoot.existsSync()) {
      mediaRoot.deleteSync(recursive: true);
    }
  });

  Future<String> draft({String companyId = 'company-a'}) async {
    final created = await inspections.createDraft(
      companyId: companyId,
      equipmentId: 'equip-1',
      createdByUserId: 'user-1',
    );
    return created.id;
  }

  CapturedImage image(List<int> bytes) =>
      CapturedImage(bytes: bytes, mimeType: 'image/jpeg');

  group('saveRequiredPhoto', () {
    test('persists metadata and app-private file', () async {
      final inspectionId = await draft();
      final saved = await media.saveRequiredPhoto(
        companyId: 'company-a',
        inspectionId: inspectionId,
        slot: InspectionPhotoSlot.frontLeftOverview,
        image: image([1, 2, 3, 4]),
        updatedByUserId: 'user-1',
      );

      expect(saved.slot, InspectionPhotoSlot.frontLeftOverview);
      expect(saved.byteSize, 4);
      expect(saved.localRelativePath, contains('inspection_media'));
      expect(saved.localRelativePath, contains('front_left_overview'));

      final absolute = File('${mediaRoot.path}/${saved.localRelativePath}');
      expect(absolute.existsSync(), isTrue);
      expect(absolute.readAsBytesSync(), [1, 2, 3, 4]);
    });

    test('retake replaces one slot without touching others', () async {
      final inspectionId = await draft();
      final front = await media.saveRequiredPhoto(
        companyId: 'company-a',
        inspectionId: inspectionId,
        slot: InspectionPhotoSlot.frontLeftOverview,
        image: image([10]),
      );
      final rear = await media.saveRequiredPhoto(
        companyId: 'company-a',
        inspectionId: inspectionId,
        slot: InspectionPhotoSlot.rearRightOverview,
        image: image([20]),
      );

      final replaced = await media.saveRequiredPhoto(
        companyId: 'company-a',
        inspectionId: inspectionId,
        slot: InspectionPhotoSlot.frontLeftOverview,
        image: image([11, 12]),
      );

      expect(replaced.id, isNot(front.id));
      expect(
        File('${mediaRoot.path}/${front.localRelativePath}').existsSync(),
        isFalse,
      );
      expect(
        File('${mediaRoot.path}/${replaced.localRelativePath}').existsSync(),
        isTrue,
      );

      final stillRear = await media.getBySlot(
        companyId: 'company-a',
        inspectionId: inspectionId,
        slot: InspectionPhotoSlot.rearRightOverview,
      );
      expect(stillRear!.id, rear.id);
      expect(
        File('${mediaRoot.path}/${rear.localRelativePath}').existsSync(),
        isTrue,
      );
    });

    test('rejects cross-company writes', () async {
      final inspectionId = await draft(companyId: 'company-a');
      await expectLater(
        () => media.saveRequiredPhoto(
          companyId: 'company-b',
          inspectionId: inspectionId,
          slot: InspectionPhotoSlot.serialDataPlate,
          image: image([1]),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects mutations after discard', () async {
      final inspectionId = await draft();
      await inspections.discardIncomplete(
        companyId: 'company-a',
        inspectionId: inspectionId,
      );
      await expectLater(
        () => media.saveRequiredPhoto(
          companyId: 'company-a',
          inspectionId: inspectionId,
          slot: InspectionPhotoSlot.hourMeterDashboard,
          image: image([1]),
        ),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
    });
  });

  group('tenant isolation', () {
    test('getBySlot returns null for wrong company', () async {
      final inspectionId = await draft(companyId: 'company-a');
      await media.saveRequiredPhoto(
        companyId: 'company-a',
        inspectionId: inspectionId,
        slot: InspectionPhotoSlot.serialDataPlate,
        image: image([9, 9]),
      );
      final loaded = await media.getBySlot(
        companyId: 'company-b',
        inspectionId: inspectionId,
        slot: InspectionPhotoSlot.serialDataPlate,
      );
      expect(loaded, isNull);
    });

    test('loadCapturedImage rejects cross-company reads', () async {
      final inspectionId = await draft(companyId: 'company-a');
      final saved = await media.saveRequiredPhoto(
        companyId: 'company-a',
        inspectionId: inspectionId,
        slot: InspectionPhotoSlot.serialDataPlate,
        image: image([5, 6]),
      );
      await expectLater(
        () => media.loadCapturedImage(companyId: 'company-b', media: saved),
        throwsA(isA<StateError>()),
      );
    });

    test('purge rejects cross-company cleanup', () async {
      final inspectionId = await draft(companyId: 'company-a');
      await media.saveRequiredPhoto(
        companyId: 'company-a',
        inspectionId: inspectionId,
        slot: InspectionPhotoSlot.frontLeftOverview,
        image: image([1]),
      );
      await expectLater(
        () => media.purgeForInspection(
          companyId: 'company-b',
          inspectionId: inspectionId,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('discard cleanup', () {
    test('purge removes metadata and files after discard', () async {
      final inspectionId = await draft();
      final saved = await media.saveRequiredPhoto(
        companyId: 'company-a',
        inspectionId: inspectionId,
        slot: InspectionPhotoSlot.rearRightOverview,
        image: image([7, 8, 9]),
      );
      final path = File('${mediaRoot.path}/${saved.localRelativePath}');
      expect(path.existsSync(), isTrue);

      await inspections.discardIncomplete(
        companyId: 'company-a',
        inspectionId: inspectionId,
      );
      await media.purgeForInspection(
        companyId: 'company-a',
        inspectionId: inspectionId,
      );

      expect(
        await media.listForInspection(
          companyId: 'company-a',
          inspectionId: inspectionId,
        ),
        isEmpty,
      );
      expect(path.existsSync(), isFalse);
    });
  });

  group('persistence across reopen', () {
    test('media survives database reopen', () async {
      final dbFile = File('${mediaRoot.path}/reopen_inspections.sqlite');
      final firstDb = openFileAppDatabase(
        dbFile,
        encryptionKey: 'test-key-not-for-production-use!!',
        requireCipher: false,
      );
      final firstInspections = DriftLocalInspectionRepository(firstDb);
      final firstMedia = DriftLocalInspectionMediaRepository(
        firstDb,
        firstInspections,
        InspectionMediaFileStore(documentsDirectoryOverride: () => mediaRoot),
      );
      final draft = await firstInspections.createDraft(
        companyId: 'company-a',
        equipmentId: 'equip-1',
        createdByUserId: 'user-1',
      );
      await firstMedia.saveRequiredPhoto(
        companyId: 'company-a',
        inspectionId: draft.id,
        slot: InspectionPhotoSlot.hourMeterDashboard,
        image: image([42, 43]),
      );
      await firstDb.close();

      final secondDb = openFileAppDatabase(
        dbFile,
        encryptionKey: 'test-key-not-for-production-use!!',
        requireCipher: false,
      );
      final secondInspections = DriftLocalInspectionRepository(secondDb);
      final secondMedia = DriftLocalInspectionMediaRepository(
        secondDb,
        secondInspections,
        InspectionMediaFileStore(documentsDirectoryOverride: () => mediaRoot),
      );
      final loaded = await secondMedia.getBySlot(
        companyId: 'company-a',
        inspectionId: draft.id,
        slot: InspectionPhotoSlot.hourMeterDashboard,
      );
      expect(loaded, isNotNull);
      final bytes = await secondMedia.loadCapturedImage(
        companyId: 'company-a',
        media: loaded!,
      );
      expect(bytes.bytes, [42, 43]);
      await secondDb.close();
    });
  });
}
