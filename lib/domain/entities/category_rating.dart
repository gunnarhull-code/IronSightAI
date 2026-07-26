import 'condition_rating.dart';
import 'scorecard_category.dart';

/// Quick Condition Scorecard rating for one top-level category.
class CategoryRating {
  const CategoryRating({
    required this.category,
    required this.rating,
    required this.updatedAt,
  });

  final ScorecardCategory category;
  final ConditionRating rating;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'category': category.storageValue,
      'rating': rating.storageValue,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory CategoryRating.fromMap(Map<String, dynamic> map) {
    return CategoryRating(
      category: ScorecardCategory.fromStorage(map['category'] as String),
      rating: ConditionRating.fromStorage(map['rating'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryRating &&
        other.category == category &&
        other.rating == rating &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(category, rating, updatedAt);
}
