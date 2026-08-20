import 'dart:convert';

import '../../domain/ai/ai_media_analysis_request.dart';

/// Encodes still-image analysis payloads. Never includes original video bytes.
abstract final class AiMediaReviewPayloadCodec {
  static const String reviewKind = 'frame_based_video_review';

  static Map<String, dynamic> encode(AiMediaAnalysisRequest request) {
    if (request.containsOriginalVideo) {
      throw StateError('Original walkaround video must never be encoded.');
    }
    return {
      'company_id': request.companyId,
      'inspection_id': request.inspectionId,
      'review_kind': reviewKind,
      'includes_video_frames': request.includesVideoFrames,
      'images': [for (final image in request.images) _encodeImage(image)],
    };
  }

  /// Log-safe view: image bytes and paths removed.
  static Map<String, dynamic> redact(Map<String, dynamic> payload) {
    final images = payload['images'];
    return {
      'company_id': payload['company_id'],
      'inspection_id': payload['inspection_id'],
      'review_kind': payload['review_kind'],
      'includes_video_frames': payload['includes_video_frames'],
      'image_count': images is List ? images.length : 0,
      'images': [
        if (images is List)
          for (final item in images)
            if (item is Map)
              {
                'id': item['id'],
                'role': item['role'],
                'label': item['label'],
                'slot': item['slot'],
                'frame_index': item['frame_index'],
                'mime_type': item['mime_type'],
                'byte_length': item['byte_length'],
                'content_base64': '[redacted]',
              },
      ],
    };
  }

  static bool containsVideoMime(Map<String, dynamic> payload) {
    final images = payload['images'];
    if (images is! List) return false;
    for (final item in images) {
      if (item is! Map) continue;
      final mime = (item['mime_type'] as String? ?? '').toLowerCase();
      if (mime.startsWith('video/')) return true;
    }
    return payload.containsKey('video') ||
        payload.containsKey('video_base64') ||
        payload.containsKey('video_bytes');
  }

  static Map<String, dynamic> _encodeImage(AiMediaImage image) {
    final bytes = image.image.bytes;
    return {
      'id': image.id,
      'role': image.isVideoFrame ? 'video_frame' : 'photo',
      'label': image.label,
      if (image.slot != null) 'slot': image.slot!.storageValue,
      if (image.frameIndex != null) 'frame_index': image.frameIndex,
      'mime_type': image.image.mimeType,
      'byte_length': bytes.length,
      'content_base64': base64Encode(bytes),
    };
  }
}
