import 'inspection_photo_slot.dart';

/// Local inspection media metadata. Binary lives in app-private storage.
class InspectionMedia {
  const InspectionMedia({
    required this.id,
    required this.companyId,
    required this.inspectionId,
    required this.slot,
    required this.localRelativePath,
    required this.mimeType,
    required this.byteSize,
    required this.capturedAt,
    required this.updatedAt,
    required this.localUpdatedAt,
  });

  final String id;
  final String companyId;
  final String inspectionId;
  final InspectionPhotoSlot slot;

  /// Path relative to the app documents root (portable across reopen).
  final String localRelativePath;
  final String mimeType;
  final int byteSize;
  final DateTime capturedAt;
  final DateTime updatedAt;
  final DateTime localUpdatedAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'inspection_id': inspectionId,
      'slot': slot.storageValue,
      'local_relative_path': localRelativePath,
      'mime_type': mimeType,
      'byte_size': byteSize,
      'captured_at': capturedAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'local_updated_at': localUpdatedAt.toUtc().toIso8601String(),
    };
  }

  factory InspectionMedia.fromMap(Map<String, dynamic> map) {
    return InspectionMedia(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      inspectionId: map['inspection_id'] as String,
      slot: InspectionPhotoSlot.fromStorage(map['slot'] as String),
      localRelativePath: map['local_relative_path'] as String,
      mimeType: map['mime_type'] as String,
      byteSize: map['byte_size'] as int,
      capturedAt: DateTime.parse(map['captured_at'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
      localUpdatedAt: DateTime.parse(map['local_updated_at'] as String).toUtc(),
    );
  }

  InspectionMedia copyWith({
    String? localRelativePath,
    String? mimeType,
    int? byteSize,
    DateTime? capturedAt,
    DateTime? updatedAt,
    DateTime? localUpdatedAt,
  }) {
    return InspectionMedia(
      id: id,
      companyId: companyId,
      inspectionId: inspectionId,
      slot: slot,
      localRelativePath: localRelativePath ?? this.localRelativePath,
      mimeType: mimeType ?? this.mimeType,
      byteSize: byteSize ?? this.byteSize,
      capturedAt: capturedAt ?? this.capturedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    );
  }
}
