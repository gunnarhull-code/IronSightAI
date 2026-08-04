import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/inspection_media.dart';
import '../../domain/entities/inspection_photo_slot.dart';
import '../../domain/equipment_id_capture/captured_image.dart';
import '../../domain/exceptions/invalid_inspection_lifecycle_exception.dart';
import '../../domain/inspection_lifecycle.dart';
import '../../domain/repositories/local_inspection_media_repository.dart';
import '../../domain/repositories/local_inspection_repository.dart';
import '../local/drift/app_database.dart';
import '../local/inspection_media_file_store.dart';

/// Drift + app-private file store implementation of [LocalInspectionMediaRepository].
class DriftLocalInspectionMediaRepository
    implements LocalInspectionMediaRepository {
  DriftLocalInspectionMediaRepository(
    this._db,
    this._inspections,
    this._files, {
    DateTime Function()? clock,
    String Function()? idGenerator,
  }) : _clock = clock ?? (() => DateTime.now().toUtc()),
       _idGenerator = idGenerator ?? const Uuid().v4;

  final AppDatabase _db;
  final LocalInspectionRepository _inspections;
  final InspectionMediaFileStore _files;
  final DateTime Function() _clock;
  final String Function() _idGenerator;

  @override
  Future<List<InspectionMedia>> listForInspection({
    required String companyId,
    required String inspectionId,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    _requireNonEmpty(inspectionId, 'inspectionId');

    final rows =
        await (_db.select(_db.inspectionMediaItems)..where(
              (table) =>
                  table.companyId.equals(companyId) &
                  table.inspectionId.equals(inspectionId),
            ))
            .get();

    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<InspectionMedia?> getBySlot({
    required String companyId,
    required String inspectionId,
    required InspectionPhotoSlot slot,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    _requireNonEmpty(inspectionId, 'inspectionId');

    final row =
        await (_db.select(_db.inspectionMediaItems)..where(
              (table) =>
                  table.companyId.equals(companyId) &
                  table.inspectionId.equals(inspectionId) &
                  table.slot.equals(slot.storageValue),
            ))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<InspectionMedia> saveRequiredPhoto({
    required String companyId,
    required String inspectionId,
    required InspectionPhotoSlot slot,
    required CapturedImage image,
    String? updatedByUserId,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    _requireNonEmpty(inspectionId, 'inspectionId');
    if (image.isEmpty) {
      throw ArgumentError('Captured image bytes must not be empty.');
    }

    final inspection = await _inspections.getById(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    if (inspection == null) {
      throw StateError('Inspection not found for this company.');
    }
    InspectionLifecycle.ensureCanMutate(inspection);

    final existing = await getBySlot(
      companyId: companyId,
      inspectionId: inspectionId,
      slot: slot,
    );

    // New file identity on every capture so replace can delete the prior path
    // only after metadata commit succeeds.
    final mediaId = _idGenerator();
    final now = _clock();
    final extension = _extensionForMime(image.mimeType);

    // Write the replacement file first so a failed write leaves the old photo.
    final stored = await _files.writeBytes(
      companyId: companyId,
      inspectionId: inspectionId,
      slot: slot,
      mediaId: mediaId,
      bytes: image.bytes,
      extension: extension,
    );

    try {
      await _db.transaction(() async {
        if (existing != null) {
          await (_db.delete(_db.inspectionMediaItems)..where(
                (table) =>
                    table.id.equals(existing.id) &
                    table.companyId.equals(companyId),
              ))
              .go();
        }
        await _db
            .into(_db.inspectionMediaItems)
            .insert(
              InspectionMediaItemsCompanion.insert(
                id: mediaId,
                companyId: companyId,
                inspectionId: inspectionId,
                slot: slot.storageValue,
                localRelativePath: stored.relativePath,
                mimeType: image.mimeType,
                byteSize: stored.byteSize,
                capturedAt: now,
                updatedAt: now,
                localUpdatedAt: now,
              ),
            );
      });
    } catch (error) {
      // Persistence failed — remove the new file; keep the previous association.
      await _files.deleteIfExists(stored.relativePath);
      rethrow;
    }

    if (existing != null && existing.localRelativePath != stored.relativePath) {
      await _files.deleteIfExists(existing.localRelativePath);
    }

    // Touch inspection localUpdatedAt so draft reopen ordering stays coherent.
    if (updatedByUserId != null) {
      try {
        await _inspections.updateMetadata(
          companyId: companyId,
          inspectionId: inspectionId,
          updatedByUserId: updatedByUserId,
        );
      } on InvalidInspectionLifecycleException {
        // Media already saved; lifecycle race is surfaced on next mutation.
      }
    }

    final saved = await getBySlot(
      companyId: companyId,
      inspectionId: inspectionId,
      slot: slot,
    );
    return saved!;
  }

  @override
  Future<void> purgeForInspection({
    required String companyId,
    required String inspectionId,
  }) async {
    _requireNonEmpty(companyId, 'companyId');
    _requireNonEmpty(inspectionId, 'inspectionId');

    // Tenant check: reject cross-company purge even when rows are absent.
    final ownedInspection = await _inspections.getById(
      companyId: companyId,
      inspectionId: inspectionId,
    );
    if (ownedInspection == null) {
      final foreignRows = await (_db.select(
        _db.inspectionMediaItems,
      )..where((table) => table.inspectionId.equals(inspectionId))).get();
      if (foreignRows.any((row) => row.companyId != companyId)) {
        throw StateError('Cross-company inspection media purge rejected.');
      }
      // Wrong-tenant / unknown inspection with no foreign media: no-op.
      if (foreignRows.isEmpty) return;
    }

    final rows =
        await (_db.select(_db.inspectionMediaItems)..where(
              (table) =>
                  table.companyId.equals(companyId) &
                  table.inspectionId.equals(inspectionId),
            ))
            .get();

    await (_db.delete(_db.inspectionMediaItems)..where(
          (table) =>
              table.companyId.equals(companyId) &
              table.inspectionId.equals(inspectionId),
        ))
        .go();

    for (final row in rows) {
      await _files.deleteIfExists(row.localRelativePath);
    }
  }

  @override
  Future<CapturedImage> loadCapturedImage({
    required String companyId,
    required InspectionMedia media,
  }) async {
    if (media.companyId != companyId) {
      throw StateError('Cross-company inspection media read rejected.');
    }
    final owned = await getBySlot(
      companyId: companyId,
      inspectionId: media.inspectionId,
      slot: media.slot,
    );
    if (owned == null || owned.id != media.id) {
      throw StateError('Inspection media not found for this company.');
    }
    final bytes = await _files.readBytes(media.localRelativePath);
    final absolute = await _files.absolutePathFor(media.localRelativePath);
    return CapturedImage(
      bytes: bytes,
      path: absolute,
      mimeType: media.mimeType,
    );
  }

  InspectionMedia _toDomain(LocalInspectionMediaRow row) {
    return InspectionMedia(
      id: row.id,
      companyId: row.companyId,
      inspectionId: row.inspectionId,
      slot: InspectionPhotoSlot.fromStorage(row.slot),
      localRelativePath: row.localRelativePath,
      mimeType: row.mimeType,
      byteSize: row.byteSize,
      capturedAt: row.capturedAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
      localUpdatedAt: row.localUpdatedAt.toUtc(),
    );
  }

  String _extensionForMime(String mimeType) {
    switch (mimeType.toLowerCase()) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      default:
        return 'jpg';
    }
  }

  void _requireNonEmpty(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, 'must not be empty');
    }
  }
}
