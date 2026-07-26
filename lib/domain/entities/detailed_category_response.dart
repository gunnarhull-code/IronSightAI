import 'condition_rating.dart';
import 'scorecard_category.dart';

/// One detailed-inspection checklist item under a scorecard category.
///
/// [itemKey] is a stable identity for future template mapping. UI concerns
/// (widgets, expand state) intentionally never appear here.
class DetailedChecklistItemResponse {
  const DetailedChecklistItemResponse({
    required this.itemKey,
    required this.labelSnapshot,
    required this.sortOrder,
    this.rating = ConditionRating.notAssessed,
    this.notes,
  });

  final String itemKey;
  final String labelSnapshot;
  final int sortOrder;
  final ConditionRating rating;
  final String? notes;

  Map<String, dynamic> toMap() {
    return {
      'item_key': itemKey,
      'label_snapshot': labelSnapshot,
      'sort_order': sortOrder,
      'rating': rating.storageValue,
      'notes': notes,
    };
  }

  factory DetailedChecklistItemResponse.fromMap(Map<String, dynamic> map) {
    return DetailedChecklistItemResponse(
      itemKey: map['item_key'] as String,
      labelSnapshot: map['label_snapshot'] as String,
      sortOrder: map['sort_order'] as int,
      rating: ConditionRating.fromStorage(map['rating'] as String),
      notes: map['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DetailedChecklistItemResponse &&
        other.itemKey == itemKey &&
        other.labelSnapshot == labelSnapshot &&
        other.sortOrder == sortOrder &&
        other.rating == rating &&
        other.notes == notes;
  }

  @override
  int get hashCode =>
      Object.hash(itemKey, labelSnapshot, sortOrder, rating, notes);
}

/// Category-level detailed inspection structure.
///
/// Starts empty and can grow with checklist items later without changing the
/// Quick Condition Scorecard model or embedding UI state.
class DetailedCategoryResponse {
  const DetailedCategoryResponse({
    required this.category,
    this.items = const [],
  });

  final ScorecardCategory category;
  final List<DetailedChecklistItemResponse> items;

  Map<String, dynamic> toMap() {
    return {
      'category': category.storageValue,
      'items': items.map((item) => item.toMap()).toList(growable: false),
    };
  }

  factory DetailedCategoryResponse.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? const [];
    return DetailedCategoryResponse(
      category: ScorecardCategory.fromStorage(map['category'] as String),
      items: rawItems
          .map(
            (item) => DetailedChecklistItemResponse.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DetailedCategoryResponse &&
        other.category == category &&
        _listEquals(other.items, items);
  }

  @override
  int get hashCode => Object.hash(category, Object.hashAll(items));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
