import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/condition_rating.dart';

/// Large Good / Fair / Poor controls for one-handed field use.
class ConditionRatingControls extends StatelessWidget {
  const ConditionRatingControls({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.includeNotAssessed = false,
  });

  final ConditionRating value;
  final ValueChanged<ConditionRating> onChanged;
  final bool enabled;
  final bool includeNotAssessed;

  @override
  Widget build(BuildContext context) {
    final ratings = <ConditionRating>[
      ConditionRating.good,
      ConditionRating.fair,
      ConditionRating.poor,
      if (includeNotAssessed) ConditionRating.notAssessed,
    ];

    return Semantics(
      label: 'Condition rating',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final rating in ratings)
            _RatingButton(
              label: _label(rating),
              selected: value == rating,
              enabled: enabled,
              onPressed: () {
                HapticFeedback.selectionClick();
                onChanged(rating);
              },
            ),
        ],
      ),
    );
  }

  static String _label(ConditionRating rating) {
    return switch (rating) {
      ConditionRating.good => 'Good',
      ConditionRating.fair => 'Fair',
      ConditionRating.poor => 'Poor',
      ConditionRating.notAssessed => 'N/A',
    };
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 52,
      child: FilledButton.tonal(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          minimumSize: const Size(96, 52),
          textStyle: theme.textTheme.titleMedium,
        ),
        child: Text(label),
      ),
    );
  }
}
