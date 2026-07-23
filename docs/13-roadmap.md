# Roadmap — V1 Execution Plan & V2-V4 Vision

**Synced with `docs/15-final-product-specification.md` following the founder approval review** (see `docs/16-founder-approval-checklist.md`). The Week 1–12 plan below reflects the approved progressive depth model (Quick Appraisal as the default experience, with expandable Detailed Inspection on the same inspection engine — not two separate systems) and the schema/security additions approved during the founder review (SQLCipher encryption from Week 1, `equipment_transactions`, company-level `region`). Where this document's framing differs from `docs/15`, `docs/15` remains the authority.

## V1 — 8–12 Week MVP Execution Plan

Scoped for one founder using AI-assisted development. Weeks are sequential blocks of effort, not calendar guarantees — treat this as a dependency-ordered plan, compress or extend blocks based on actual velocity, but do not reorder the dependencies without a reason.

### Weeks 1–2: Foundation
- Set up Supabase project (dev + production), Flutter project scaffold, repo, CI (Codemagic) skeleton.
- Implement schema + RLS policies from [`04-data-model.md`](./04-data-model.md) and [`08-security-compliance.md`](./08-security-compliance.md) as versioned migrations, explicitly including:
  - The `inspections.completion_status` / `sync_status` / `report_status` split (not a single flat status field).
  - The `checklist_template_items` self-referencing `parent_item_id` hierarchy (top-level Quick Condition Scorecard categories with optional Detailed Inspection sub-items — one inspection engine, not two).
  - `equipment_transactions` (schema only — no V1 UI; outcome data entered via a controlled admin/database process during the pilot, per Founder Decision #4).
  - `companies.region` (company-level location only; per-inspection GPS remains explicitly deferred, per Founder Decision #5).
  - Explicit Storage-level RLS policies (`storage.objects`), not just Postgres table policies.
- Configure the local `drift` database with **SQLCipher encryption from the first migration** (Founder Decision #2 — not deferred).
- Auth flow (sign in, session persistence, company/role context).
- Basic inspection list screen (empty state) to validate the whole client-to-Supabase pipeline end to end before building capture features.

**Exit criterion**: a signed-in user can see an (empty) list of their company's inspections, and RLS has been manually verified to block cross-company access.

### Weeks 3–5: Core Capture Workflow
- Equipment selection screen + taxonomy seed data (Section 2/3 of [`12-equipment-taxonomy.md`](./12-equipment-taxonomy.md)), including the non-blocking duplicate-serial-number check against `equipment`.
- Continuous guided walkaround video capture module: one continuous recording with timestamped angle prompts (`inspection_media.timestamp_markers`) and a single-tap "Restart Walkaround" action — not seven separate stop/start clips.
- Serial number scan (camera + on-device OCR, candidate chips for confirmation + manual fallback).
- Hour meter capture (camera + OCR + manual fallback).
- Local `drift` schema + repository layer + outbox scaffolding (build this alongside capture screens, not after — retrofitting offline-first onto an online-first app is far more expensive than building it in from the start).

**Exit criterion**: a full inspection's identification data (equipment, serial, hour meter) can be captured entirely in airplane mode and persists across an app restart.

### Weeks 5–7: Quick Condition Scorecard, Detailed Inspection & Sync Engine
- Data-driven rendering from `checklist_templates`/`checklist_template_items`, respecting the `parent_item_id` hierarchy: top-level items render as the **Quick Condition Scorecard** (6-8 categories, one-tap Good/Fair/Poor); each category carries an expand affordance that reveals its **Detailed Inspection** sub-items (condition rating, optional photo, optional note) — the same underlying template and response table for both, per the progressive depth model (`docs/15-final-product-specification.md` §5, §9).
- Quick Condition Scorecard UI as the default screen; Detailed Inspection as an optional per-category expansion, never a separate screen flow or a separate data model.
- Snapshot-on-write: `inspection_checklist_responses.section_snapshot` / `label_snapshot` populated at answer time, for both Quick and Detailed responses.
- Sync engine: outbox processor, media upload queue, connectivity-aware triggers, honest sync-status UI.

**Exit criterion**: an inspection fully captured offline syncs completely and correctly to Supabase within a minute of connectivity returning, verified against a real device with airplane mode toggled mid-inspection.

### Weeks 8–9: Report Generation & Review Flow
- Review/summary screen (Step 8 of [`07-inspection-workflow.md`](./07-inspection-workflow.md)), including any expanded Detailed Inspection results nested beneath their category.
- `generate-report` Edge Function + PDF template (company branding: logo, footer) — renders exactly as much depth as was actually captured per category (Quick rating only, or Quick + nested Detailed sub-items).
- "Complete" flow (Step 9) sets `completion_status = 'completed'` locally and offline; sync completion then advances `sync_status`/`report_status` and triggers report generation automatically — the client-side check is a UX convenience, the server-side `generate-report` re-validation is the sole authoritative gate (`docs/15-final-product-specification.md` §8).
- Native share sheet integration (Step 10) — PDF attached, pre-filled subject/body (`docs/15-final-product-specification.md` §13; note the `reports` table's share-metadata columns described there are not yet reflected in `04-data-model.md` — flagged for a future data-model sync, not fixed in this pass).

**Exit criterion**: a completed inspection reliably produces a complete, professional PDF, shareable directly from the phone.

### Weeks 10–12: Admin Basics, Polish, Pilot Prep
- Minimal company admin: invite-user Edge Function + basic roster view.
- Inspection list filters/search (FR-26).
- Real-device field testing pass (mid-range Android + iPhone, outdoors, gloved-hand tap targets, bright-sunlight screen legibility).
- Bug fixing, performance tuning against the targets in [`11-non-functional-requirements.md`](./11-non-functional-requirements.md).
- Onboard first pilot dealership; hand-create their company/admin account.

**Exit criterion**: a real dealership rep completes a real trade-in inspection on WIW, unassisted, and a usable report reaches the used equipment manager.

### Explicitly Not in the 8–12 Week Window
Anything listed under Non-Goals in [`02-product-requirements.md`](./02-product-requirements.md), plus: self-serve sign-up, billing, SSO, web admin console, and any V2/V3/V4 item below.

## V2 — AI Inspection Assistance

**Depends on**: V1's structured, labeled media and Quick Condition Scorecard / Detailed Inspection response corpus ([`03-technical-architecture.md`](./03-technical-architecture.md) Section 5).

Candidate capabilities (to be re-scoped based on real V1 pilot data and feedback, not committed in detail now):
- Automated visual damage/wear flagging on walkaround video/photos (e.g., surfacing likely damage regions for rep confirmation — always human-confirmed, never autonomous, consistent with the OCR "confirm, don't assume" principle).
- Smart Quick Condition Scorecard / Detailed Inspection suggestions (e.g., pre-filling a likely condition rating from photo analysis, rep confirms/overrides).
- Voice-to-text for inspection notes (reduces typing in the field).
- True push notifications (FCM/APNs + server-triggered webhook) for report-ready status, replacing V1's in-app/foregrounded-only status.
- Branded, delivery/open-tracked transactional email delivery ("Send via IronSight AI"), replacing V1's native-share-sheet-only sharing.
- DMS/CRM integration for equipment record lookup (reduce redundant data entry with existing dealership systems).

## V3 — Equipment Valuation Engine

**Depends on**: A meaningful V1/V2 data corpus (Quick Condition Scorecard / Detailed Inspection data correlated with real transaction outcomes captured in `equipment_transactions` since V1 — schema-only in V1, per Founder Decision #4) plus external market comp data (auction results, industry pricing guides/APIs).

Candidate capabilities:
- Condition-adjusted value estimates per inspection, using Quick Condition Scorecard / Detailed Inspection data + category/make/model/year/hour-meter + `equipment_transactions` outcomes as inputs.
- Comparable-sale lookups.
- This is the point at which "What's It Worth" starts literally answering its namesake question — deliberately sequenced after V1/V2 because a valuation is only as trustworthy as the inspection data underneath it, and that data quality/consistency is exactly what V1 is built to establish.

## V4 — Market Intelligence Platform

**Depends on**: V3's valuation engine + a sufficient multi-tenant data set to aggregate responsibly (see [`09-multi-tenant-saas-strategy.md`](./09-multi-tenant-saas-strategy.md) Section 5).

Candidate capabilities:
- Cross-dealer market trend dashboards (regional pricing trends, category demand trends — enabled by `companies.region`, captured since V1 per Founder Decision #5).
- Benchmarking (a dealership's inspection/turnaround metrics vs. anonymized network averages).
- A likely new subscription tier / product line distinct from the core per-dealership WIW subscription, sold to a different buyer (e.g., OEM finance arms, industry analysts) — a business-model decision to revisit with real V1-V3 traction data, not decided now.

## Guiding Rule Across All Versions

Every version above is scoped so that **the version before it fully justifies its own existence independent of what comes next.** V1 must be valuable purely as an inspection/documentation tool, with zero AI or valuation capability, before a single hour is spent on V2. This is both a product-discipline principle (validate before building) and a direct instruction from the product owner for this build.
