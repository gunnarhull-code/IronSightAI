# Roadmap — MVP Execution Plan & V2 / Later Vision

**Live authority:** `docs/15-final-product-specification.md` §0 (Work Item #18 capture-and-review MVP). Where this document’s older week-by-week V1 framing differs from §0, **§0 wins**. Historical Week 1–12 detail below is retained as engineering sequencing reference from the pre-#18 progressive-depth plan; it must not reintroduce PDF/share into MVP or ban optional advisory AI from MVP.

## Live Product Sequencing (Work Item #18)

### MVP — Capture-and-review Quick Appraisal

**Primary goal:** a sales rep completes a useful Quick Appraisal in **under two minutes**, even without internet.

**Purpose:** make human trade valuation and pricing easier and faster by producing a trustworthy inspection package. The MVP does **not** calculate or recommend a dollar value.

**Workflow:**
- Select or create equipment
- Capture required photos
- Record a guided walkaround video
- Enter serial number, hours, condition, notes, and required details
- AI may suggest equipment/component recognition, visible condition or damage, field values from media, and missing information
- User reviews and corrects every suggestion; explicitly confirms final information
- Save and complete the inspection package offline
- Manual operation remains available when AI or connectivity fails

**AI rules:** optional and advisory; never silently overwrites data; never final authority; humans confirm all information; AI/provider outages never block inspections; preserve provider-agnostic `AIService` architecture.

### V2 — Shareable package

- Generate a clean shareable summary image or PDF, not a literal screenshot
- Generate a prefilled email draft
- Require review before sending
- Use native device sharing

### Later

- Company/manager portal
- Live collaboration or chat
- Manager review and approval
- Automated email workflows
- Historical equipment information
- Recon costs and additions
- Actual pricing/valuation recommendations

## Historical V1 — 8–12 Week Execution Plan (pre-#18 record)

Scoped for one founder using AI-assisted development. Weeks are sequential blocks of effort, not calendar guarantees. **Do not treat Weeks 8–9 (report generation & native share) as MVP-required after Work Item #18** — that work is V2. Optional advisory AI may appear in MVP under §0 AI Rules; it is not deferred solely because older text placed “AI assistance” under V2.

### Weeks 1–2: Foundation
- Set up Supabase project (dev + production), Flutter project scaffold, repo, CI (Codemagic) skeleton.
- Implement schema + RLS policies from [`04-data-model.md`](./04-data-model.md) and [`08-security-compliance.md`](./08-security-compliance.md) as versioned migrations, explicitly including:
  - The `inspections.completion_status` / `sync_status` / `report_status` split (not a single flat status field).
  - The `checklist_template_items` self-referencing `parent_item_id` hierarchy (top-level Quick Condition Scorecard categories with optional Detailed Inspection sub-items — one inspection engine, not two).
  - `equipment_transactions` (schema only — no MVP UI; outcome data entered via a controlled admin/database process during the pilot, per Founder Decision #4).
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
- Required photo capture aligned to the live MVP workflow.
- Local `drift` schema + repository layer + outbox scaffolding (build this alongside capture screens, not after — retrofitting offline-first onto an online-first app is far more expensive than building it in from the start).

**Exit criterion**: a full inspection's identification data (equipment, serial, hour meter) can be captured entirely in airplane mode and persists across an app restart.

### Weeks 5–7: Condition Entry, Review, Optional Advisory AI & Sync Engine
- Condition, notes, and required-details entry for the Quick Appraisal path; keep the default path under two minutes.
- Review/confirm screen: user corrects OCR/AI suggestions and explicitly confirms final information before complete.
- Optional advisory AI suggestions behind a provider-agnostic `AIService` (never required; never silent overwrite; manual path always available).
- Sync engine: outbox processor, media upload queue, connectivity-aware triggers, honest sync-status UI.
- Historical progressive-depth scorecard / Detailed Inspection UI remains documented in `docs/15` §5 as design record; whether it stays in MVP is a founder confirmation item (`docs/15` §19).

**Exit criterion**: an inspection fully captured offline can be completed offline and syncs correctly to Supabase when connectivity returns, verified against a real device with airplane mode toggled mid-inspection.

### Weeks 8–9: Report Generation & Share Flow — **V2 (not MVP)**

Per Work Item #18 / `docs/15` §0, this block is **V2**:
- Clean shareable summary image or PDF (not a literal screenshot)
- Prefilled email draft, review before sending, native device sharing

**Historical exit criterion (pre-#18):** a completed inspection reliably produces a complete, professional PDF, shareable directly from the phone.

### Weeks 10–12: Admin Basics, Polish, Pilot Prep
- Minimal company admin / inspection list polish — confirm vs. §0 / §19 before treating as MVP-required.
- Real-device field testing pass (mid-range Android + iPhone, outdoors, gloved-hand tap targets, bright-sunlight screen legibility), including the under-two-minute Quick Appraisal timing target offline.
- Bug fixing, performance tuning against the targets in [`11-non-functional-requirements.md`](./11-non-functional-requirements.md).
- Onboard first pilot dealership; hand-create their company/admin account.

**Exit criterion**: a real dealership rep completes a real trade-in Quick Appraisal on WIW offline, unassisted, producing a trustworthy inspection package (no dollar valuation required).

### Explicitly Not in MVP
Anything listed under §0 “V2” or “Later” in [`15-final-product-specification.md`](./15-final-product-specification.md), plus: self-serve sign-up, billing, SSO, and dollar valuation/pricing recommendations.

## Historical V2–V4 Labels (pre-#18 record)

Older docs named **V2 = AI inspection assistance**, **V3 = valuation**, **V4 = market intelligence**. Live sequencing after Work Item #18 is **MVP (may include optional advisory AI) → V2 (shareable package) → Later (portal, collaboration, automated email, recon, valuation, etc.)**. Candidate capabilities from the older V2–V4 lists that are not named in §0 remain ideas, not commitments, until the founder promotes them.

## Guiding Rule Across All Phases

Every phase above is scoped so that **the phase before it fully justifies its own existence independent of what comes next.** The MVP must be valuable purely as a fast, trustworthy inspection package — AI optional and never required, no dollar valuation — before V2 sharing work is treated as mandatory.
