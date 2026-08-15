import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/entities/inspection_media.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';

void main() {
  test('requiredSlots lists the four MVP photos in order', () {
    expect(
      InspectionPhotoSlot.requiredSlots.map((s) => s.storageValue).toList(),
      [
        'front_left_overview',
        'rear_right_overview',
        'serial_data_plate',
        'hour_meter_dashboard',
      ],
    );
  });

  test('serial and hour slots feed OCR reuse', () {
    expect(InspectionPhotoSlot.serialDataPlate.feedsSerialOcr, isTrue);
    expect(InspectionPhotoSlot.hourMeterDashboard.feedsHourMeterOcr, isTrue);
    expect(InspectionPhotoSlot.frontLeftOverview.feedsSerialOcr, isFalse);
  });

  test('InspectionMedia round-trips through toMap/fromMap', () {
    final media = InspectionMedia(
      id: 'm1',
      companyId: 'c1',
      inspectionId: 'i1',
      slot: InspectionPhotoSlot.rearRightOverview,
      localRelativePath: 'inspection_media/c1/i1/rear_right_overview/m1.jpg',
      mimeType: 'image/jpeg',
      byteSize: 12,
      capturedAt: DateTime.utc(2026, 8, 4, 1),
      updatedAt: DateTime.utc(2026, 8, 4, 2),
      localUpdatedAt: DateTime.utc(2026, 8, 4, 3),
    );
    final restored = InspectionMedia.fromMap(media.toMap());
    expect(restored.id, media.id);
    expect(restored.slot, InspectionPhotoSlot.rearRightOverview);
    expect(restored.byteSize, 12);
    expect(restored.localRelativePath, media.localRelativePath);
  });
}
