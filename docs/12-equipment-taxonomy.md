# Equipment Taxonomy

This defines the reference data model behind equipment classification (`equipment_categories`, `equipment_makes` in [`04-data-model.md`](./04-data-model.md)). The taxonomy must be **extensible without an app release** — new makes, categories, or models must never block a rep from completing an inspection.

## 1. Design Principle: Curated Lists, Never a Hard Wall

- **Category** and **Make** are curated, database-backed lists (fast selection UX — tap, don't type) but are stored as normal rows, not hardcoded enums in application code, so adding a new one is a database insert, not an app release.
- **Model** is always free text (with autocomplete suggestions once we accumulate real data) — we will never have a complete list of every equipment model in existence, and blocking a rep from logging a machine because its exact model string isn't in our database would directly undermine the "fastest, easiest inspection" mission.
- **"Other"** is always a valid Make and Category selection, guaranteeing the app never hard-blocks on an unrecognized machine.

## 2. V1 Seed Data — Equipment Makes

Caterpillar, Bobcat, John Deere, Komatsu, Doosan, Kubota, Case, Volvo, Takeuchi, Other.

(This list is expected to grow — e.g., Hitachi, Hyundai, JCB, Liebherr, New Holland — based on real pilot dealership inventory. Adding a make is a one-row insert into `equipment_makes`, immediately available offline on next taxonomy sync.)

## 3. V1 Seed Data — Equipment Categories

A representative starting set covering the majority of dealership trade-in volume:

- Excavator (standard, mini/compact)
- Skid Steer Loader
- Compact Track Loader
- Wheel Loader
- Backhoe Loader
- Dozer
- Motor Grader
- Articulated Dump Truck
- Telehandler
- Compactor/Roller
- Other

Each category will eventually drive category-specific checklist templates (`checklist_templates.category_id` in the data model), since an excavator and a compactor genuinely need different inspection points — this is why category is a structured field, not just descriptive metadata.

## 4. Why This Matters Beyond V1

The category/make/model structure captured consistently in V1 is the same structural backbone that:

- **V2** uses to scope AI damage-detection models per equipment type (a hydraulic hose failure pattern on an excavator isn't the same visual signature as undercarriage wear on a compact track loader).
- **V3** uses to match a given inspection against relevant market comps for valuation (comps must be like-for-like by category/make/model/year).
- **V4** uses to produce meaningful market-trend segmentation (e.g., "Cat excavator values by region," not an undifferentiated blend of all equipment).

Getting this taxonomy right — extensible, never blocking, but structured enough to be genuinely useful downstream — is a deliberate V1 investment specifically because it's expensive to retrofit onto years of accumulated unstructured inspection data later.

## 5. Governance

- New Category additions should be deliberate (they eventually imply a new checklist template) — treated as a light internal review step, not fully self-serve, even for admins, in V1.
- New Make additions are low-risk and can be added freely as pilot dealership inventory demands it.
