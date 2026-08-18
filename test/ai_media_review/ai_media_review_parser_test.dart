import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_failure.dart';
import 'package:ironsight_ai/domain/ai/ai_media_review_parser.dart';
import 'package:ironsight_ai/domain/ai/ai_suggestion_kind.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';

Map<String, dynamic> _suggestion({
  required String kind,
  required String confidence,
  String? value,
  String type = 'photo',
  String slot = 'serial_data_plate',
  int? frameIndex,
  String? uncertainty,
  num? hours,
}) {
  return {
    'id': 's-$kind',
    'kind': kind,
    'value': value,
    'confidence': confidence,
    'uncertainty': uncertainty,
    'hours': ?hours,
    'source': {
      'type': type,
      if (type == 'photo') 'slot': slot,
      'frame_index': ?frameIndex,
      'label': type == 'photo'
          ? 'Serial / data plate'
          : 'Walkaround video frame',
    },
  };
}

void main() {
  test('parses structured identity and condition suggestions', () {
    final result = AiMediaReviewParser.parse({
      'review_kind': 'frame_based_video_review',
      'disclaimer': 'AI suggestions only — not verified facts.',
      'suggestions': [
        _suggestion(
          kind: 'manufacturer',
          confidence: 'high',
          value: 'Caterpillar',
        ),
        _suggestion(kind: 'model', confidence: 'medium', value: '320'),
        _suggestion(
          kind: 'serial_number',
          confidence: 'medium',
          value: '5O252M63O4',
        ),
        _suggestion(kind: 'hour_meter', confidence: 'high', value: '1234'),
        _suggestion(
          kind: 'visible_damage_or_wear',
          confidence: 'low',
          value: 'Scuffed counterweight',
          slot: 'rear_right_overview',
          uncertainty: 'Angle is oblique',
        ),
        _suggestion(
          kind: 'possible_leak',
          confidence: 'low',
          value: 'Dark staining near boom',
          type: 'video_frame',
          frameIndex: 1,
          uncertainty: 'Could be dirt',
        ),
      ],
    });

    expect(result.isFrameBasedVideoReview, isTrue);
    expect(result.suggestions, hasLength(6));
    expect(result.suggestions[0].kind, AiSuggestionKind.manufacturer);
    expect(result.suggestions[2].hasAmbiguousSerialCharacters, isTrue);
    expect(result.suggestions[2].value, '5O252M63O4');
    expect(result.suggestions[3].hourMeterHours, 1234);
    expect(result.suggestions[5].source.frameIndex, 1);
    expect(
      result.suggestions[5].source.spokenLabel,
      'Walkaround video frame 2',
    );
  });

  test(
    'preserves ambiguous serial characters and does not invent missing ones',
    () {
      final result = AiMediaReviewParser.parse({
        'suggestions': [
          _suggestion(
            kind: 'serial_number',
            confidence: 'low',
            value: 'CAT-O0I1',
          ),
          _suggestion(
            kind: 'serial_number',
            confidence: 'low',
            value: 'ABC??12',
            uncertainty: 'Two characters unreadable',
          ),
        ],
      });
      expect(result.suggestions[0].value, 'CAT-O0I1');
      expect(result.suggestions[0].hasAmbiguousSerialCharacters, isTrue);
      expect(result.suggestions[1].value, isNot(contains('?')));
      expect(result.suggestions[1].value, isNot('ABC0012'));
    },
  );

  test('never invents missing hour digits', () {
    final result = AiMediaReviewParser.parse({
      'suggestions': [
        _suggestion(
          kind: 'hour_meter',
          confidence: 'low',
          value: '12??',
          uncertainty: 'Last digits unreadable',
        ),
        _suggestion(kind: 'hour_meter', confidence: 'low', value: '12X4'),
        _suggestion(
          kind: 'hour_meter',
          confidence: 'low',
          value: '1250',
          uncertainty: 'Guessed the last two digits',
        ),
        _suggestion(kind: 'hour_meter', confidence: 'high', value: '321'),
      ],
    });
    expect(result.suggestions[0].hourMeterHours, isNull);
    expect(result.suggestions[1].hourMeterHours, isNull);
    expect(result.suggestions[2].hourMeterHours, isNull);
    expect(result.suggestions[3].hourMeterHours, 321);
  });

  test('rejects malformed payloads', () {
    expect(
      () => AiMediaReviewParser.parse('not-json-object'),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.malformedResponse,
        ),
      ),
    );
    expect(
      () => AiMediaReviewParser.parse({
        'suggestions': [
          {'kind': 'nope', 'confidence': 'high', 'source': {}},
        ],
      }),
      throwsA(isA<AiMediaReviewException>()),
    );
    expect(
      () => AiMediaReviewParser.parse({
        'suggestions': [
          _suggestion(kind: 'manufacturer', confidence: 'extreme', value: 'X'),
        ],
      }),
      throwsA(isA<AiMediaReviewException>()),
    );
  });

  test('parses a valid video-frame structured response', () {
    final result = AiMediaReviewParser.parse({
      'review_kind': 'frame_based_video_review',
      'disclaimer': 'AI suggestions only — not verified facts.',
      'suggestions': [
        _suggestion(
          kind: 'visible_damage_or_wear',
          confidence: 'low',
          value: 'Scuff on counterweight',
          type: 'video_frame',
          frameIndex: 1,
          uncertainty: 'Angle is oblique',
        ),
      ],
    });
    expect(result.suggestions, hasLength(1));
    expect(result.suggestions.single.source.type.name, 'videoFrame');
    expect(result.suggestions.single.source.frameIndex, 1);
    expect(result.suggestions.single.source.slot, isNull);
    expect(
      result.suggestions.single.source.spokenLabel,
      'Walkaround video frame 2',
    );
  });

  test('empty suggestions are valid and invent nothing', () {
    final result = AiMediaReviewParser.parse({
      'review_kind': 'frame_based_video_review',
      'disclaimer': 'AI suggestions only — not verified facts.',
      'suggestions': <Map<String, dynamic>>[],
    });
    expect(result.suggestions, isEmpty);
  });

  test('rejects an invalid source type', () {
    expect(
      () => AiMediaReviewParser.parse({
        'suggestions': [
          _suggestion(
            kind: 'rust',
            confidence: 'low',
            value: 'Surface rust',
            type: 'walkaround',
          ),
        ],
      }),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.malformedResponse,
        ),
      ),
    );
  });

  test('rejects an invalid photo slot', () {
    expect(
      () => AiMediaReviewParser.parse({
        'suggestions': [
          _suggestion(
            kind: 'manufacturer',
            confidence: 'high',
            value: 'Cat',
            slot: 'left_side',
          ),
        ],
      }),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.malformedResponse,
        ),
      ),
    );
  });

  test('rejects unknown suggestion kind and confidence', () {
    expect(
      () => AiMediaReviewParser.parse({
        'suggestions': [
          _suggestion(
            kind: 'price_estimate',
            confidence: 'high',
            value: '12000',
          ),
        ],
      }),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.malformedResponse,
        ),
      ),
    );
    expect(
      () => AiMediaReviewParser.parse({
        'suggestions': [
          _suggestion(kind: 'manufacturer', confidence: 'certain', value: 'X'),
        ],
      }),
      throwsA(
        isA<AiMediaReviewException>().having(
          (e) => e.failure.kind,
          'kind',
          AiMediaReviewFailureKind.malformedResponse,
        ),
      ),
    );
  });

  test('requires a source photo or video frame', () {
    expect(
      () => AiMediaReviewParser.parse({
        'suggestions': [
          {'kind': 'rust', 'confidence': 'low', 'value': 'Surface rust'},
        ],
      }),
      throwsA(isA<AiMediaReviewException>()),
    );
    final parsed = AiMediaReviewParser.parse({
      'suggestions': [
        _suggestion(
          kind: 'rust',
          confidence: 'medium',
          value: 'Surface rust',
          slot: InspectionPhotoSlot.frontLeftOverview.storageValue,
        ),
      ],
    });
    expect(
      parsed.suggestions.single.source.slot,
      InspectionPhotoSlot.frontLeftOverview,
    );
  });
}
