import '../entities/inspection_photo_slot.dart';
import '../equipment_id_capture/captured_image.dart';

enum AiMediaImageRole { inspectionPhoto, videoFrame }

/// A still image eligible for AI analysis (never a complete video).
class AiMediaImage {
  const AiMediaImage({
    required this.id,
    required this.role,
    required this.image,
    required this.label,
    this.slot,
    this.frameIndex,
  });

  final String id;
  final AiMediaImageRole role;
  final CapturedImage image;
  final String label;
  final InspectionPhotoSlot? slot;
  final int? frameIndex;

  bool get isVideoFrame => role == AiMediaImageRole.videoFrame;
}

/// Request sent through [AIService]. Contains stills only.
class AiMediaAnalysisRequest {
  const AiMediaAnalysisRequest({
    required this.companyId,
    required this.inspectionId,
    required this.images,
    this.includesVideoFrames = false,
  });

  final String companyId;
  final String inspectionId;
  final List<AiMediaImage> images;
  final bool includesVideoFrames;

  static const int maxImageCount = 10;
  static const int maxBytesPerImage = 400 * 1024;
  static const Duration timeout = Duration(seconds: 45);

  bool get isEmpty => images.isEmpty;

  /// True when any payload item is a complete video. Always false for valid
  /// requests built by this domain — used as a regression guard.
  bool get containsOriginalVideo {
    for (final image in images) {
      final mime = image.image.mimeType.toLowerCase();
      if (mime.startsWith('video/')) return true;
      if (image.role != AiMediaImageRole.inspectionPhoto &&
          image.role != AiMediaImageRole.videoFrame) {
        return true;
      }
    }
    return false;
  }

  List<AiMediaImage> get photoImages => images
      .where((image) => image.role == AiMediaImageRole.inspectionPhoto)
      .toList(growable: false);

  List<AiMediaImage> get videoFrames => images
      .where((image) => image.role == AiMediaImageRole.videoFrame)
      .toList(growable: false);
}
