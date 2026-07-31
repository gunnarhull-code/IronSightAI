# Roadmap — MVP Execution Plan & V2 / Later Vision

**Live authority:** `docs/15-final-product-specification.md` §0 (Work Item #18 capture-and-review MVP, including founder confirmations in §19). Where this document’s older week-by-week V1 framing differs from §0, **§0 wins**. Historical Week 1–12 detail below is retained as engineering sequencing reference from the pre-#18 progressive-depth plan; it must not reintroduce PDF/share into MVP, Detailed Inspection UI into MVP, or ban optional advisory AI from MVP.

## Live Product Sequencing (Work Item #18)

### MVP — Quick Appraisal only

**Primary goal:** a sales rep completes a useful Quick Appraisal in **under two minutes**, even without internet.

**Purpose:** make human trade valuation and pricing easier and faster by producing a trustworthy inspection package. The MVP does **not** calculate or recommend a dollar value.

**MVP contains only Quick Appraisal.** Expandable Detailed Inspection is **Later**. Preserve the shared checklist data model (`parent_item_id` hierarchy) so Detailed Inspection can be added without an architecture rewrite.

**Under-two-minute minimum capture set** (see `docs/15` §0):
- Required photos: front-left overview; rear-right overview; serial/data plate; hour-meter/dashboard
- Also required: one continuous guided walkaround video (evidence; **not** AI-analyzed in MVP); equipment type, make, model; serial or explicit “not found”; hours or explicit “unknown”; Quick Condition ratings
- Optional: year; notes; additional damage/detail photos
- Timing: Start Quick Appraisal → confirm complete; excludes login, first-time company onboarding, sync, sharing; validate on mid-range phone in field conditions; if over two minutes, reduce required work

**AI:**
- On-device OCR for serial and hour meter
- Optional photo recognition/autofill via cloud AI when connected, only through backend provider-agnostic `AIService` (Flutter/domain never call a vendor directly)
- Manual capture always works when AI or connectivity fails
- Vendor selection is a later benchmark Work Item

**Required MVP plumbing:**
- Minimal company setup/context
- Company-scoped inspection list
- Reopen mutable draft
- Discard draft with confirmation

### V2 — Professional PDF share

- First artifact: professional PDF (not a literal screenshot)
- Generate server-side → cache/download locally → attach through a reviewed native email/share draft

### Later

- Expandable Detailed Inspection (on preserved shared checklist model)
- Separate summary-image renderer (unless pilot feedback proves it necessary earlier)
- Company/manager portal
- Live collaboration or chat
- Manager review and approval
- Automated email workflows
- Historical equipment information
- Recon costs and additions
- Actual pricing/valuation recommendations
- Cloud AI vendor selection / benchmarking

## Historical V1 — 8–12 Week Execution Plan (pre-#18 record)

Scoped for one founder using AI-assisted development. Weeks are sequential blocks of effort, not calendar guarantees. **After Work Item #18 founder confirmations:** Weeks 8–9 (report generation & native share) are **V2**; Detailed Inspection UI is **Later**; optional cloud photo assist via backend `AIService` may appear in MVP; on-device OCR for serial/hours is in MVP.

### Weeks 1–2: Foundation
- Set up Supabase project (dev + production), Flutter project scaffold, repo, CI (Codemagic) skeleton.
- Implement schema + RLS policies from [`04-data-model.md`](./04-data-model.md) and [`08-security-compliance.md`](./08-security-compliance.md) as versioned migrations, explicitly including:
  - The `inspections.completion_status` / `sync_status` / `report_status` split (not a single flat status field).
  - The `checklist_template_items` self-referencing `parent_item_id` hierarchy (top-level Quick Condition categories for MVP; child Detailed sub-items may be seeded for Later UI — one inspection engine, not two).
  - `equipment_transactions` (schema only — no MVP UI; outcome data entered via a controlled admin/database process during the pilot, per Founder Decision #4).
  - `companies.region` (company-level location only; per-inspection GPS remains explicitly deferred, per Founder Decision #5).
  - Explicit Storage-level RLS policies (`storage.objects`), not just Postgres table policies.
- Configure the local `drift` database with **SQLCipher encryption from the first migration** (Founder Decision #2 — not deferred).
- Auth flow (sign in, session persistence, company/role context) — minimal company setup/context is MVP plumbing.
- Company-scoped inspection list (empty state) to validate the whole client-to-Supabase pipeline end to end before building capture features.

**Exit criterion**: a signed-in user can see an (empty) company-scoped list of inspections, and RLS has been manually verified to block cross-company access.

### Weeks 3–5: Core Capture Workflow
- Equipment selection (type, make, model required; year optional) + taxonomy seed data, including the non-blocking duplicate-serial-number check against `equipment`.
- Required photo capture: front-left, rear-right, serial/data plate, hour-meter/dashboard (+ optional damage/detail photos).
- Continuous guided walkaround video (evidence only in MVP; timestamp markers retained for Later analysis readiness) + single-tap "Restart Walkaround".
- Serial number and hour meter via on-device OCR with confirmation, or explicit “not found” / “unknown”, plus manual fallback.
- Local `drift` schema + repository layer + outbox scaffolding.

**Exit criterion**: required capture set can be completed entirely in airplane mode and persists across an app restart.

### Weeks 5–7: Quick Condition, Review, Optional Cloud Assist & Sync
- Quick Condition ratings UI (MVP depth only — no expandable Detailed Inspection UI).
- Review/confirm screen; reopen mutable draft; discard draft with confirmation.
- Optional cloud photo recognition/autofill when connected via backend `AIService` (never required; never silent overwrite; no vendor calls from Flutter/domain).
- Sync engine: outbox processor, media upload queue, connectivity-aware triggers, honest sync-status UI.
- Field timing validation against the under-two-minute definition in `docs/15` §0; reduce required work if the path misses the target.

**Exit criterion**: an inspection fully captured offline can be completed offline and syncs correctly when connectivity returns; mid-range device field timing is measured honestly.

### Weeks 8–9: Professional PDF & Share Flow — **V2 (not MVP)**

Per Work Item #18 / `docs/15` §0:
- Server-side professional PDF generation
- Cache/download locally
- Reviewed native email/share draft with PDF attached

**Historical exit criterion (pre-#18):** a completed inspection reliably produces a complete, professional PDF, shareable directly from the phone.

### Weeks 10–12: Polish & Pilot Prep
- Polish MVP plumbing (company context, list, draft reopen/discard) and capture UX.
- Real-device field testing pass against the under-two-minute timing definition.
- Bug fixing, performance tuning against the targets in [`11-non-functional-requirements.md`](./11-non-functional-requirements.md).
- Onboard first pilot dealership; hand-create their company/admin account.

**Exit criterion**: a real dealership rep completes a real trade-in Quick Appraisal on WIW offline, unassisted, producing a trustworthy inspection package (no dollar valuation required).

### Explicitly Not in MVP
Anything listed under §0 “V2” or “Later” in [`15-final-product-specification.md`](./15-final-product-specification.md), including Detailed Inspection UI, summary-image renderer, professional PDF share, portal/collaboration, and dollar valuation.

## Historical V2–V4 Labels (pre-#18 record)

Older docs named **V2 = AI inspection assistance**, **V3 = valuation**, **V4 = market intelligence**. Live sequencing after Work Item #18 is **MVP (Quick Appraisal + on-device OCR + optional cloud photo assist) → V2 (professional PDF share) → Later (Detailed Inspection, summary image, portal, collaboration, valuation, vendor benchmarks, etc.)**.

## Guiding Rule Across All Phases

Every phase above is scoped so that **the phase before it fully justifies its own existence independent of what comes next.** The MVP must be valuable purely as a fast, trustworthy Quick Appraisal package — AI optional and never required, no dollar valuation — before V2 PDF sharing is treated as mandatory.
