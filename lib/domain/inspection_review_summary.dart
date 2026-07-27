import 'entities/condition_rating.dart';
import 'entities/inspection.dart';
import 'entities/scorecard_category.dart';

/// Review projection for an inspection — no lifecycle rules duplicated.
class InspectionReviewSummary {
  const InspectionReviewSummary({
    required this.inspection,
    required this.incompleteCategories,
  });

  final Inspection inspection;
  final List<ScorecardCategory> incompleteCategories;

  bool get hasIncompleteCategories => incompleteCategories.isNotEmpty;
}

InspectionReviewSummary buildInspectionReviewSummary(Inspection inspection) {
  final incomplete = ScorecardCategory.scorecardOrder
      .where(
        (category) =>
            inspection.ratingFor(category) == ConditionRating.notAssessed,
      )
      .toList(growable: false);
  return InspectionReviewSummary(
    inspection: inspection,
    incompleteCategories: incomplete,
  );
}
