import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/entities/category_rating.dart';
import 'package:ironsight_ai/domain/entities/condition_rating.dart';
import 'package:ironsight_ai/domain/entities/detailed_category_response.dart';
import 'package:ironsight_ai/domain/entities/inspection.dart';
import 'package:ironsight_ai/domain/entities/inspection_depth.dart';
import 'package:ironsight_ai/domain/entities/inspection_status.dart';
import 'package:ironsight_ai/domain/entities/scorecard_category.dart';
import 'package:ironsight_ai/domain/exceptions/invalid_condition_rating_exception.dart';
import 'package:ironsight_ai/domain/exceptions/invalid_inspection_lifecycle_exception.dart';
import 'package:ironsight_ai/domain/exceptions/invalid_scorecard_category_exception.dart';
import 'package:ironsight_ai/domain/inspection_lifecycle.dart';
import 'package:ironsight_ai/domain/inspection_value_parsing.dart';

void main() {
  final now = DateTime.utc(2026, 7, 26, 12);

  Inspection sampleInspection({
    InspectionCompletionStatus completionStatus =
        InspectionCompletionStatus.inProgress,
    InspectionLocalLifecycle localLifecycle = InspectionLocalLifecycle.active,
  }) {
    return Inspection(
      id: 'insp-1',
      companyId: 'company-1',
      equipmentId: 'equip-1',
      createdByUserId: 'user-1',
      completionStatus: completionStatus,
      localLifecycle: localLifecycle,
      depth: InspectionDepth.quickAppraisal,
      syncStatus: InspectionSyncStatus.localOnly,
      reportStatus: InspectionReportStatus.notGenerated,
      categoryRatings: [
        for (final category in ScorecardCategory.scorecardOrder)
          CategoryRating(
            category: category,
            rating: ConditionRating.notAssessed,
            updatedAt: now,
          ),
      ],
      createdAt: now,
      updatedAt: now,
      localUpdatedAt: now,
    );
  }

  group('ScorecardCategory', () {
    test('exposes the seven Quick Condition Scorecard categories in order', () {
      expect(
        ScorecardCategory.scorecardOrder.map((c) => c.storageValue).toList(),
        [
          'engine',
          'hydraulics',
          'undercarriage',
          'cab',
          'structure',
          'attachments',
          'cosmetic',
        ],
      );
    });

    test('rejects invalid category values', () {
      expect(
        () => parseScorecardCategory('transmission'),
        throwsA(isA<InvalidScorecardCategoryException>()),
      );
    });
  });

  group('ConditionRating', () {
    test('serializes the four allowed ratings', () {
      expect(ConditionRating.good.storageValue, 'good');
      expect(ConditionRating.fair.storageValue, 'fair');
      expect(ConditionRating.poor.storageValue, 'poor');
      expect(ConditionRating.notAssessed.storageValue, 'not_assessed');
    });

    test('rejects invalid rating values', () {
      expect(
        () => parseConditionRating('excellent'),
        throwsA(isA<InvalidConditionRatingException>()),
      );
    });
  });

  group('Inspection serialization', () {
    test('round-trips through toMap/fromMap', () {
      final original = sampleInspection().copyWith(
        overallNotes: 'Lot unit',
        depth: InspectionDepth.detailed,
        categoryRatings: [
          CategoryRating(
            category: ScorecardCategory.engine,
            rating: ConditionRating.good,
            updatedAt: now,
          ),
          ...ScorecardCategory.scorecardOrder
              .skip(1)
              .map(
                (category) => CategoryRating(
                  category: category,
                  rating: ConditionRating.notAssessed,
                  updatedAt: now,
                ),
              ),
        ],
        detailedResponses: {
          ScorecardCategory.engine: const DetailedCategoryResponse(
            category: ScorecardCategory.engine,
            items: [
              DetailedChecklistItemResponse(
                itemKey: 'engine_oil',
                labelSnapshot: 'Engine oil level/condition',
                sortOrder: 0,
                rating: ConditionRating.fair,
                notes: 'Dark oil',
              ),
            ],
          ),
        },
      );

      final restored = Inspection.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.companyId, original.companyId);
      expect(restored.depth, InspectionDepth.detailed);
      expect(restored.overallNotes, 'Lot unit');
      expect(
        restored.ratingFor(ScorecardCategory.engine),
        ConditionRating.good,
      );
      expect(
        restored.detailedFor(ScorecardCategory.engine).items.single.itemKey,
        'engine_oil',
      );
    });
  });

  group('InspectionLifecycle', () {
    test('allows discard only for active incomplete inspections', () {
      expect(
        () => InspectionLifecycle.ensureCanDiscard(sampleInspection()),
        returnsNormally,
      );
      expect(
        () => InspectionLifecycle.ensureCanDiscard(
          sampleInspection(
            completionStatus: InspectionCompletionStatus.completed,
          ),
        ),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
      expect(
        () => InspectionLifecycle.ensureCanDiscard(
          sampleInspection(localLifecycle: InspectionLocalLifecycle.discarded),
        ),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
    });

    test('blocks mutations after discard or completion', () {
      expect(
        () => InspectionLifecycle.ensureCanMutate(
          sampleInspection(localLifecycle: InspectionLocalLifecycle.discarded),
        ),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
      expect(
        () => InspectionLifecycle.ensureCanMutate(
          sampleInspection(
            completionStatus: InspectionCompletionStatus.completed,
          ),
        ),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
    });

    test('blocks completing a discarded inspection', () {
      expect(
        () => InspectionLifecycle.ensureCanComplete(
          sampleInspection(localLifecycle: InspectionLocalLifecycle.discarded),
        ),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
    });

    test('reopen is always rejected in this foundation sprint', () {
      expect(
        () => InspectionLifecycle.ensureCanReopen(sampleInspection()),
        throwsA(isA<InvalidInspectionLifecycleException>()),
      );
    });
  });

  group('DetailedCategoryResponse', () {
    test(
      'supports empty detailed structure for future checklist expansion',
      () {
        const response = DetailedCategoryResponse(
          category: ScorecardCategory.hydraulics,
        );
        expect(response.items, isEmpty);
        expect(DetailedCategoryResponse.fromMap(response.toMap()), response);
      },
    );
  });
}
