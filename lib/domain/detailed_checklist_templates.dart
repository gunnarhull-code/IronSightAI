import 'entities/detailed_category_response.dart';
import 'entities/scorecard_category.dart';

/// Optional Detailed Inspection starter items for each scorecard category.
///
/// Quick Appraisal never requires these. Expanding a category may seed empty
/// not-assessed items so field reps can rate them immediately.
List<DetailedChecklistItemResponse> detailedChecklistTemplateFor(
  ScorecardCategory category,
) {
  final specs = switch (category) {
    ScorecardCategory.engine => const [
      ('oil', 'Oil level / condition'),
      ('coolant', 'Coolant level'),
      ('belts_hoses', 'Belts / hoses'),
      ('leaks', 'Visible leaks'),
    ],
    ScorecardCategory.hydraulics => const [
      ('cylinders', 'Cylinders'),
      ('hoses', 'Hoses / fittings'),
      ('pump', 'Pump noise / performance'),
      ('leaks', 'Visible leaks'),
    ],
    ScorecardCategory.undercarriage => const [
      ('tracks_tires', 'Tracks / tires'),
      ('rollers', 'Rollers / idlers'),
      ('sprockets', 'Sprockets'),
      ('wear', 'Overall wear'),
    ],
    ScorecardCategory.cab => const [
      ('controls', 'Controls'),
      ('seat', 'Seat / restraints'),
      ('glass', 'Glass / mirrors'),
      ('electronics', 'Displays / electronics'),
    ],
    ScorecardCategory.structure => const [
      ('frame', 'Frame / boom'),
      ('welds', 'Welds / cracks'),
      ('pins', 'Pins / bushings'),
      ('damage', 'Impact damage'),
    ],
    ScorecardCategory.attachments => const [
      ('bucket', 'Bucket / tool'),
      ('coupler', 'Coupler'),
      ('hydraulics', 'Attachment hydraulics'),
      ('wear', 'Wear items'),
    ],
    ScorecardCategory.cosmetic => const [
      ('paint', 'Paint / panels'),
      ('decals', 'Decals / branding'),
      ('rust', 'Rust / corrosion'),
      ('cleanliness', 'Overall cleanliness'),
    ],
  };

  return [
    for (var index = 0; index < specs.length; index++)
      DetailedChecklistItemResponse(
        itemKey: specs[index].$1,
        labelSnapshot: specs[index].$2,
        sortOrder: index,
      ),
  ];
}
