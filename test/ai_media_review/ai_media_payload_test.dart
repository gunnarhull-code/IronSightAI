import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/data/ai/ai_media_review_payload_codec.dart';
import 'package:ironsight_ai/domain/ai/ai_media_analysis_request.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';

void main() {
  test('encodes photos and video frames without the original video', () {
    const videoPath = '/tmp/walkaround-local.mp4';
    final request = AiMediaAnalysisRequest(
      companyId: 'company-a',
      inspectionId: 'insp-1',
      includesVideoFrames: true,
      images: [
        AiMediaImage(
          id: 'photo-1',
          role: AiMediaImageRole.inspectionPhoto,
          label: 'Serial / data plate',
          slot: InspectionPhotoSlot.serialDataPlate,
          image: const CapturedImage(
            bytes: [1, 2, 3],
            path: '/tmp/serial.jpg',
            mimeType: 'image/jpeg',
          ),
        ),
        const AiMediaImage(
          id: 'frame-0',
          role: AiMediaImageRole.videoFrame,
          label: 'Walkaround video frame 1',
          frameIndex: 0,
          image: CapturedImage(
            bytes: [9, 9, 9],
            path: '/tmp/frame-0.jpg',
            mimeType: 'image/jpeg',
          ),
        ),
      ],
    );

    expect(request.containsOriginalVideo, isFalse);
    final payload = AiMediaReviewPayloadCodec.encode(request);
    expect(payload.containsKey('video'), isFalse);
    expect(payload.containsKey('video_base64'), isFalse);
    expect(AiMediaReviewPayloadCodec.containsVideoMime(payload), isFalse);
    expect(payload['review_kind'], 'frame_based_video_review');
    expect((payload['images'] as List).length, 2);
    expect(
      payload.toString().contains(videoPath),
      isFalse,
      reason: 'original video path must not appear in the AI payload',
    );

    final redacted = AiMediaReviewPayloadCodec.redact(payload);
    expect(redacted.toString().contains('AQID'), isFalse);
    expect(redacted['images'], isA<List>());
    expect((redacted['images'] as List).first['content_base64'], '[redacted]');
  });

  test('refuses to encode a video mime payload', () {
    final request = AiMediaAnalysisRequest(
      companyId: 'company-a',
      inspectionId: 'insp-1',
      images: const [
        AiMediaImage(
          id: 'video',
          role: AiMediaImageRole.videoFrame,
          label: 'original video',
          image: CapturedImage(bytes: [1], mimeType: 'video/mp4'),
        ),
      ],
    );
    expect(request.containsOriginalVideo, isTrue);
    expect(() => AiMediaReviewPayloadCodec.encode(request), throwsStateError);
  });
}
