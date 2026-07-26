import 'entities/condition_rating.dart';
import 'entities/scorecard_category.dart';
import 'exceptions/invalid_condition_rating_exception.dart';
import 'exceptions/invalid_scorecard_category_exception.dart';

/// Parses a persisted scorecard category or rejects unknown values.
ScorecardCategory parseScorecardCategory(String value) {
  try {
    return ScorecardCategory.fromStorage(value);
  } on FormatException catch (error) {
    throw InvalidScorecardCategoryException(error.message);
  }
}

/// Parses a persisted condition rating or rejects unknown values.
ConditionRating parseConditionRating(String value) {
  try {
    return ConditionRating.fromStorage(value);
  } on FormatException catch (error) {
    throw InvalidConditionRatingException(error.message);
  }
}
