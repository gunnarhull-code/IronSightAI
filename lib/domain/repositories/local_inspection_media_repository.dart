import '../entities/inspection_media.dart';
import '../entities/inspection_photo_slot.dart';
import '../equipment_id_capture/captured_image.dart';

/// Local persistence for required Quick Appraisal photos.
///
/// Company-scoped. Does not upload or sync. Binary files live in app-private
/// storage; this repository owns metadata + safe replace/discard cleanup.
abstract class LocalInspectionMediaRepository {
  /// Lists media for one inspection within [companyId] (empty when none).
  Future<List<InspectionMedia>> listForInspection({
    required String companyId,
    required String inspectionId,
  });

  /// Returns the media for one required slot, or null when missing / wrong tenant.
  Future<InspectionMedia?> getBySlot({
    required String companyId,
    required String inspectionId,
    required InspectionPhotoSlot slot,
  });

  /// Persists a required photo for [slot], replacing any previous one safely.
  ///
  /// Writes the new file first, then updates metadata, then deletes the prior
  /// file. On failure, the previous photo (if any) remains intact.
  Future<InspectionMedia> saveRequiredPhoto({
    required String companyId,
    required String inspectionId,
    required InspectionPhotoSlot slot,
    required CapturedImage image,
    String? updatedByUserId,
  });

  /// Deletes all media rows and files for a discarded (or purged) inspection.
  ///
  /// Cross-company calls are rejected. Missing inspections / empty media are
  /// no-ops after tenant validation.
  Future<void> purgeForInspection({
    required String companyId,
    required String inspectionId,
  });

  /// Loads image bytes for an owned media row (tenant-checked).
  Future<CapturedImage> loadCapturedImage({
    required String companyId,
    required InspectionMedia media,
  });
}
