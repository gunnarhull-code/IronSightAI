/// Fixed V1 list of selectable equipment manufacturers.
///
/// No arbitrary manufacturer names are permitted in V1 (per product
/// decision) — see [manufacturerCatalog] used by both the presentation-layer
/// dropdown and [EquipmentDetails.validated]. Adding a manufacturer here is a
/// deliberate content change, not a per-inspection user choice; a future
/// manufacturer database/API is explicitly out of scope for V1.
const List<String> manufacturerCatalog = [
  'Caterpillar',
  'John Deere',
  'Komatsu',
  'Volvo',
  'Hitachi',
  'Case',
  'Bobcat',
  'Kubota',
  'JCB',
  'Liebherr',
  'Hyundai',
  'Doosan',
  'Takeuchi',
  'New Holland',
  'Wacker Neuson',
  'Terex',
  'SANY',
  'XCMG',
  'LiuGong',
];
