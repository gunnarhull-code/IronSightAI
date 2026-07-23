# Pre-Development Review — CTO Assessment

**Purpose**: A critical, pre-implementation audit of `docs/01`–`docs/13` before Week 1 begins. This is not a rubber stamp — it identifies real gaps, contradictions, and risks found on a careful re-read of the full documentation set, and proposes concrete resolutions. No application code has been written; nothing in this document requires code changes to act on, only documentation decisions.

**Verdict: Conditionally ready to begin implementation.** The architecture is sound and appropriately scoped for a solo founder. However, there are **two genuine documentation contradictions** and **one significant data-model gap with long-term consequences** that should be resolved before Week 1, plus several smaller items that are safe to fix in parallel with early development. None of these invalidate the overall approach (Flutter + Supabase + local-first) — they are refinements, not a redesign.

---

## 1. Conflicting Requirements

### 1.1 [BLOCKING] PDF report generation: server-only vs. "client-side fallback renderer"
- **Where**: [`10-tech-stack.md`](./10-tech-stack.md) (Decision Summary table) lists the PDF choice as *"Supabase Edge Function... **with a client-side fallback renderer**"*.
- **Conflict**: Every other document that touches report generation — [`03-technical-architecture.md`](./03-technical-architecture.md) §4.4, [`05-api-design.md`](./05-api-design.md) `generate-report`, [`07-inspection-workflow.md`](./07-inspection-workflow.md) Step 9, and PRD FR-23 — describes report generation as **exclusively server-side**, with connectivity as the one acknowledged exception to "works fully offline." No client-side PDF fallback is designed, specified, or reflected in the mobile app spec.
- **Why it matters**: If left unresolved, a developer (or an AI coding assistant working from a single doc in isolation) could reasonably build a second, undocumented PDF rendering path, doubling report-template maintenance and creating two possible sources of report formatting drift — a real problem for a "consistent, professional report" requirement (US-3).
- **Resolution**: Drop the "client-side fallback renderer" line from `10-tech-stack.md`. Server-side-only generation is the correct call for V1 (consistency across devices, one template to maintain, matches every other doc). If the real concern was "what if the rep needs the report before connectivity returns," the correct mitigation is already documented elsewhere: cache the generated PDF locally once produced, and be explicit in the UI that report generation itself requires connectivity (already true per FR-23/FR-27).

### 1.2 [BLOCKING] "Finalize" is used to mean two different things
- **Where**: [`07-inspection-workflow.md`](./07-inspection-workflow.md) Step 8 describes "Finalize Inspection" as an instant, fully-offline local action ("Rep is free to immediately start a new inspection — finalize never blocks on network activity"). Separately, [`05-api-design.md`](./05-api-design.md) defines a `POST /functions/v1/finalize-inspection` **Edge Function** that performs server-side validation (serial number present, required checklist items answered, etc.) and is the actual gate before a report can be generated.
- **Conflict**: An Edge Function cannot run offline. So "Finalize," as used in the UX doc, cannot be the same operation as "finalize-inspection," as used in the API doc — but nothing currently distinguishes them by name, and the data model's `inspections.status` enum (`draft` → `pending_sync` → `synced` → `report_generated`) has no state representing "rep has finished, but device is still offline, and server-side validation hasn't run yet."
- **Why it matters**: Without an explicit intermediate state, it's ambiguous what a rep sees on the Review screen while offline after tapping Finalize — is the inspection "done"? Can they still be told about a missing required field before they leave the job site (when correcting it is easy) versus finding out days later when connectivity finally returns (when correcting it may require a second site visit)?
- **Resolution**: Treat these explicitly as two distinct steps and document both:
  1. **Client-side "Complete"** (offline-capable): runs the *same validation rules* locally (duplicate the simple presence checks — required fields, required checklist items — in Dart, not just in the Edge Function) and flips a local completion flag. This gives the rep immediate, offline feedback on missing data while they can still act on it.
  2. **Server-side `finalize-inspection`** (requires connectivity): re-runs validation as the authoritative gate (client-side checks are a UX convenience, not a trust boundary — see §4.4 below) and is what actually unlocks `generate-report`.
  This requires adding an explicit status value (see §3.1) and duplicating a small, well-defined validation rule set client-side — a cheap fix now, expensive to retrofit after reps have muscle memory around a different behavior.

### 1.3 [MINOR] FR-27 undersells the actual sync behavior
- **Where**: PRD FR-27 states *"Only sign-in (first time on a device) and final report cloud-backup require connectivity."* FR-28 and the architecture doc's outbox design describe continuous, incremental sync of **all** pending changes (not just a single "final" backup) as connectivity allows.
- **Resolution**: Reword FR-27 to: *"Only sign-in (first time on a device) and PDF report generation require connectivity. All other data — including in-progress drafts — syncs incrementally in the background whenever connectivity is available, but no step in the workflow ever waits for it."* This also makes the draft-backup behavior a stated requirement rather than an implicit side effect, which is a good thing to be able to sell to dealerships ("your data starts backing up before the inspection is even finished").

---

## 2. Missing Features for V1 MVP

These are gaps that would surface as real pilot-blocking friction, not nice-to-haves. Ranked roughly by how likely they are to bite during the 8–12 week build or the first pilot.

### 2.1 [HIGH] No equipment/serial deduplication at inspection start
Nothing in the workflow ([`07-inspection-workflow.md`](./07-inspection-workflow.md) Step 4) checks whether a scanned serial number already exists in `equipment` for that company before creating a new `equipment` row. In real dealership use, the same machine gets inspected more than once (initial trade-in walk, a later re-inspection before sale, etc.). Without dedup, every re-inspection silently forks into a disconnected `equipment` record — no inspection history, no "last inspected" context for the rep, and (see §5.4) a direct data-quality problem for V3 valuation, which benefits enormously from time-series condition data on the *same* physical asset.
**Recommendation**: After OCR/manual serial entry, query `equipment` for a match on `(company_id, serial_number)`. If found, ask the rep to confirm ("This machine has 1 prior inspection — continue with this record?") rather than silently creating a duplicate. Cheap to build now (a single indexed lookup — the index already exists per `04-data-model.md`), expensive to unwind later once dealerships have months of forked records.

### 2.2 [HIGH] No way to discard/cancel a bad inspection
FR-24 covers viewing inspections; nothing covers abandoning one started by mistake (wrong equipment selected, interrupted by a customer and never resumed, duplicate of another inspection). Reps will start inspections they don't finish — this is normal field behavior, not an edge case. Left unaddressed, inspection lists fill with junk drafts that will eventually be mistaken for real ones by a manager, or worse, get synced and counted in future valuation/market-intelligence datasets as legitimate data points.
**Recommendation**: Add a soft-delete/"discard draft" action, restricted to `draft`-status inspections owned by the rep (or any admin/manager), consistent with the existing no-hard-delete audit principle in [`08-security-compliance.md`](./08-security-compliance.md) §5 — flag as discarded, don't physically delete.

### 2.3 [MEDIUM] No explicit device permission handling
Camera, microphone (if video captures audio), and storage permissions are core to the entire product, but no document addresses the UX for a rep who denies a permission, or the App Store/Play Store requirement to justify each permission with a usage-description string. This is not optional — both platforms will reject a build without it.
**Recommendation**: Add a short section to [`06-mobile-app-spec.md`](./06-mobile-app-spec.md) covering permission request timing (ask at first use of each capability, not all upfront at launch) and a graceful degraded state (clear explanation + deep link to system settings) if denied. Small addition, but must exist before the first TestFlight/Play Internal build.

### 2.4 [MEDIUM] No maximum clip duration / video size cap
[`06-mobile-app-spec.md`](./06-mobile-app-spec.md) §3 sets resolution/bitrate targets (720p, capped bitrate) but no per-segment **duration** cap. An unbounded "Front" walkaround clip recorded for 3 minutes instead of 10 seconds has real consequences: local storage pressure on older phones, and — the bigger risk — upload time and cellular data cost when a rep syncs over their own phone's data plan from a rural site with no Wi-Fi, which is the exact scenario this product is designed around.
**Recommendation**: Cap each walkaround segment at a sensible ceiling (e.g., 30–45 seconds), enforced in the capture UI, not just recommended in copy.

### 2.5 [MEDIUM] "Report Ready" notification depends on infrastructure that isn't decided
[`07-inspection-workflow.md`](./07-inspection-workflow.md) Step 9 promises a "push/local notification" once a report finishes generating. [`10-tech-stack.md`](./10-tech-stack.md) does not include a push notification service (FCM/APNs), and report generation as designed is a **client-invoked** Edge Function call — meaning if the app is backgrounded or killed before the ~20-second generation call returns, there is no server-initiated channel to notify the rep afterward.
**Recommendation for V1**: Explicitly scope this down — report generation happens while the app is foregrounded (the rep waits on a progress screen, or it completes silently while they're still using the app), with an in-app status indicator, not a true push notification. Document real push notifications (requiring FCM setup + a Supabase Database Webhook to trigger it server-side) as a named V2 item rather than an ambiguous V1 promise.

### 2.6 [LOW] No forgot-password / account recovery flow stated
Implied to exist via Supabase Auth but never listed as a functional requirement. Add one line to PRD §6.1 for completeness — it's a five-minute Supabase Auth feature, not a design problem, just an omission.

### 2.7 [LOW] No minimum-app-version enforcement
Since local schema migrations ship with app updates and reps' phones won't all update simultaneously, an old app version could sync against a changed backend schema in an unexpected way after a mid-pilot schema change. Recommend a simple app-version check (e.g., a `min_supported_version` value fetched at launch, blocking sync — not app usage — below it) called out in `03-technical-architecture.md` as a Week 1-adjacent task, not a full doc rewrite.

---

## 3. Over-Engineering to Delay

Nothing in the documentation is dramatically over-built — the tech stack review in `10-tech-stack.md` already does a good job saying no to Kubernetes, custom backends, and multi-region deployment. The following are smaller-scale trims worth making explicitly, given the 8–12 week budget for one founder.

### 3.1 Checklist template versioning is more machinery than V1 needs — but the underlying concern is real (see §4.1)
`checklist_templates.version` implies a full historical-versioning system. For a handful of pilot dealerships sharing one evolving template, this is premature — **but don't just delete it**: the actual risk it's gesturing at (an admin edits a checklist item's wording and a *previously generated* report's data becomes ambiguous) is real and is better solved by denormalizing at the response level (§4.1) than by a full template-versioning system. **Recommendation**: drop the `version`/`is_active` versioning columns for V1 (one always-current template per category is sufficient at pilot scale), and instead fix the actual data-integrity issue directly in `inspection_checklist_responses` per §4.1.

### 3.2 Four external SaaS tool integrations in Week 1–2 is more setup than the exit criterion needs
[`13-roadmap.md`](./13-roadmap.md) Weeks 1–2 implicitly front-loads Supabase + Codemagic + Sentry + PostHog + GitHub, per `10-tech-stack.md`. The Week 1–2 exit criterion only requires Supabase + a working build pipeline.
**Recommendation**: Sequence tool onboarding — Supabase and GitHub in Week 1 (required for anything to exist); Sentry can be added the moment there's a build to crash-report on (still early, low cost, high value); defer Codemagic CI automation and PostHog analytics to Weeks 8–10, once there's an app worth automating and users worth measuring. This doesn't remove anything from the stack decision, it just avoids spending Week 1 configuring five dashboards before writing the auth flow.

### 3.3 Separate `finalize-inspection` Edge Function vs. folding validation into `generate-report`
Per §1.2's resolution, `finalize-inspection` needs to exist as a distinct *concept*, but it doesn't necessarily need to be a separate network round-trip in V1. **Recommendation**: it's acceptable (and simpler to build first) to have `generate-report` perform the validation check itself and fail with a structured error if invalid, rather than requiring two sequential Edge Function calls. Split them into two functions later only if a real need for "validate without generating" emerges (e.g., a manager wants to review a completed inspection status before a report is generated). This is a implementation-order suggestion, not a scope change.

### 3.4 Full WCAG-level accessibility audit, localization infrastructure
Already correctly deferred in [`11-non-functional-requirements.md`](./11-non-functional-requirements.md) §8–9 ("baseline support," "hook, not full investment") — flagged here only to confirm this framing should hold: do not let either expand into a real audit or a second locale during the V1 window. No action needed, just discipline during implementation.

---

## 4. Technical Decisions That Should Change

### 4.1 [HIGH] Denormalize checklist item text onto the response row
**Current**: `inspection_checklist_responses` stores only `template_item_id`, a foreign key to `checklist_template_items`. If an admin later edits an item's `label` or `section` wording (a normal, expected content-maintenance action), every historical response silently inherits the new wording when displayed or reported — meaning a report generated in Month 8 for an inspection from Month 1 could show text the rep never actually saw or answered against. For a report that may be shown to a customer or lender, this is a real integrity problem, not a cosmetic one.
**Fix**: Add `section_snapshot` and `label_snapshot` (plain text) columns to `inspection_checklist_responses`, populated at write time from the template item. Reports and history views always render from the snapshot, never a live join to the mutable template. This is a one-time schema addition, trivial now, painful to backfill onto real pilot data later.

### 4.2 [HIGH] Split `inspections.status` into two independent dimensions
**Current**: A single enum (`draft` / `pending_sync` / `synced` / `report_generated`) conflates two independent concerns: *is the rep done working on this inspection* (completion state) and *has this device's data reached the server* (sync state). This is the root cause of the ambiguity in §1.2.
**Fix**: 
- `completion_status`: `in_progress` | `completed` (set locally by the client the moment the rep taps "Complete," works fully offline).
- `sync_status`: `local_only` | `syncing` | `synced` (mirrors the device-local bookkeeping column already planned in `04-data-model.md` §3, now promoted to a first-class server-side field too).
- `report_status`: `not_generated` | `generating` | `generated` (only meaningful once `completion_status = completed` and `sync_status = synced`).
This is a small schema change with an outsized clarity benefit for both the sync engine logic and the report-generation trigger condition.

### 4.3 [MEDIUM] Storage (bucket) RLS policies deserve the same explicit rigor as Postgres RLS
[`08-security-compliance.md`](./08-security-compliance.md) §2 gives full, concrete SQL for Postgres RLS but only a one-line reference to "equivalent policies" for Supabase Storage. Given that raw inspection video/photos (potentially the most sensitive artifact — a fully identifiable walkaround of a customer's equipment) live in Storage, not just Postgres, this deserves the same level of concrete specification before Week 1's schema/policy implementation, not left as an implied equivalent.
**Fix**: Add explicit Storage policy definitions (using Supabase's `storage.objects` policy pattern, matching on the `company_id` path segment) to `08-security-compliance.md` §2 before implementation — this is a documentation gap, not an architecture gap; the intent was always correct.

### 4.4 [MEDIUM] Don't trust client-side "Complete" validation as a security/business-rule boundary
Following the §1.2 fix, make explicit in `05-api-design.md` that the client-side completion check is a **UX convenience only** — the server-side `generate-report` validation (per §3.3) remains the sole authoritative gate, exactly as RLS (not client logic) is already the authoritative tenant-isolation boundary. Worth stating explicitly so a future contributor doesn't assume the client check is sufficient and skip server-side re-validation "to save a round trip."

### 4.5 [MEDIUM] OCR "auto-pick the best match" heuristic is riskier than presenting candidates
[`06-mobile-app-spec.md`](./06-mobile-app-spec.md) §4 describes picking "the longest alphanumeric string near the tapped region" as the auto-filled OCR guess. Serial plates often have several similar-looking alphanumeric strings (model number, PIN, serial, arrangement number) in close proximity — a wrong confident auto-pick that a rushed rep doesn't carefully double-check is worse for data quality than an honest "here are 3 things I found, tap the right one."
**Fix**: Present all detected text blocks as tappable candidates (with the heuristic's top guess pre-highlighted, not silently pre-filled) rather than auto-filling a single field. Marginally more UI work, meaningfully better data quality — and this data quality directly feeds V2/V3, where "was the serial number correct" determines whether an entire inspection's downstream data is even usable.

### 4.6 [LOW] Reconsider deferring on-device database encryption
[`08-security-compliance.md`](./08-security-compliance.md) §3 accepts unencrypted local SQLite as a V1 risk, deferred until a dealership specifically requires it. Given `drift` supports SQLCipher from the start with comparatively low setup cost, and retrofitting encryption onto an app already running with real pilot data in the field is meaningfully harder (migration of an existing unencrypted DB file, more testing surface, has to happen under time pressure if a device is ever actually lost) — this is a case where "cheap now, expensive later" tips toward doing it in Week 1–2 rather than deferring. Not a blocking issue, but worth a deliberate yes/no decision now rather than a default "later."

---

## 5. Risks to Future AI Inspection & Valuation Features

These don't block V1, but several of them are **data-collection decisions that cannot be retroactively fixed** — if V1 ships without capturing a field, that historical gap is permanent for every inspection recorded before the gap is noticed.

### 5.1 [CRITICAL] Nothing in the schema captures real-world transaction outcomes
The single biggest long-term risk in the current data model: **V3's valuation engine needs a ground-truth dependent variable** — what the dealership actually paid in trade, or what the machine actually sold for — correlated against the inspection's condition data to train or calibrate any valuation logic. No table or field anywhere in `04-data-model.md` captures this. If V1 and V2 ship and accumulate a year of inspection data with zero linked outcome data, that entire corpus is far less useful for V3 when it eventually starts — the project would effectively need to *start* outcome-data collection from V3's kickoff date instead of benefiting from a year of head start.
**Recommendation**: Add a minimal, optional, **not client-facing-in-V1** outcome-capture mechanism now — e.g., an `equipment_transactions` table (`equipment_id`, `transaction_type` [trade-in/sale], `amount`, `transaction_date`, `entered_by`) that a manager can fill in later (even via direct Supabase dashboard entry during pilot, no UI required yet). The cost of adding this now is one small table; the cost of not having it when V3 starts could be a full year of otherwise-unusable historical data.

### 5.2 [HIGH] No location/region field on inspections
Neither `equipment` nor `inspections` captures where the machine was inspected (at minimum, the dealership's region; ideally, on-site GPS for auction/customer-site inspections). Equipment values are meaningfully regional, and V3 (valuation) and V4 (market intelligence, explicitly described as needing "regional pricing trends" in `13-roadmap.md`) both depend on this dimension. It is far cheaper to capture a coarse location now (even just "dealership's registered region," zero extra rep effort) than to have no location signal on a year of historical inspections when V3/V4 need it.
**Recommendation**: Add an optional `region`/location field at the `companies` level at minimum (trivial), and consider optional on-device GPS capture at inspection time (low effort given `geolocator`-type plugins, meaningful upside, and it's genuinely useful for V1 too — e.g., "which lot is this inspection from" for multi-location dealerships).

### 5.3 [HIGH] Coarse 4-point condition scale may limit future model precision
`Good / Fair / Poor / N/A` is easy and fast for reps (correctly prioritized for V1 speed), but it's a low-resolution label for training or calibrating any future ML model that correlates condition against value or damage severity. This isn't necessarily wrong for V1 — but the choice should be made knowingly, not by default, since a historical corpus recorded on a 4-point scale can't be retroactively upgraded to finer granularity.
**Recommendation**: No V1 UI change needed (speed wins for now), but explicitly flag this as a decision to revisit with real pilot data and, ideally, input from whoever eventually owns the V2/V3 modeling work — before too much history accumulates on the coarser scale.

### 5.4 [HIGH] Equipment/serial deduplication gap (cross-referenced from §2.1) directly damages future valuation data quality
Worth restating here in AI/valuation terms specifically: V3's most valuable signal is likely *repeat inspections of the same physical asset over time* (condition trajectory, mileage/hour-meter progression). If duplicate `equipment` rows fragment a single machine's history across multiple disconnected records (per §2.1), that time-series signal is lost before V3 even starts. This elevates §2.1 from a UX nicety to a data-strategy requirement.

### 5.5 [MEDIUM] No stated media retention/archival policy
Raw walkaround video is the raw material V2's damage-detection model will eventually need. Nothing in `11-non-functional-requirements.md` or `09-multi-tenant-saas-strategy.md` states a retention policy — if cost pressure later leads to an ad hoc decision to delete or downgrade old video to save Storage cost, that could quietly delete the exact training data V2 needs.
**Recommendation**: Adopt an explicit "never auto-delete original inspection media" policy now (cheap — video is the cost driver already budgeted for in `11-non-functional-requirements.md` §6, and Supabase Storage supports cheap-tier archival later if cost becomes a real issue), so no future cost-optimization pass accidentally deletes the AI training corpus.

### 5.6 [MEDIUM] Inconsistent capture conditions across devices/reps
Photo/video quality, lighting, and framing will vary significantly across reps, phones, and weather conditions, with only text-prompt guidance (no on-device quality gating) in `07-inspection-workflow.md`. Not a V1 blocker — but a future computer-vision model trained on this corpus will need to be robust to that inconsistency, or V1/V2 will need a data-cleaning pass before training. Flagging now so it's a known, planned-for cost in V2 scoping rather than a surprise.

### 5.7 [MEDIUM] No dealership data-use consent for future AI training or cross-tenant aggregation
Trade-in equipment inspected under V1 often belongs (at time of inspection) to a third-party customer, not the dealership itself. Nothing in `08-security-compliance.md` or dealership onboarding addresses consent/data-use rights for repurposing inspection photos/video in future AI model training (V2) or anonymized cross-tenant aggregation (V4, already flagged as needing its own design pass in `09-multi-tenant-saas-strategy.md` §5). This is a legal/contractual gap, not a technical one.
**Recommendation**: Add a data-use clause to the dealership onboarding agreement (outside the scope of these technical docs, but flagged here so it isn't missed) covering IronSight AI's right to use anonymized/aggregated inspection data for product improvement and future AI features. Far easier to get this right in the first pilot agreement than to retroactively seek consent for a year of already-collected data.

### 5.8 [LOW] Edge Functions have no path to GPU/heavy inference — already acknowledged, restated for completeness
`10-tech-stack.md` already names this as an AWS-migration trigger condition. No new action needed; included here only so this review's "risks to future AI" section is a complete list in one place.

---

## 6. Prioritized Action List

### Must resolve before Week 1 (documentation-only changes, no code impact yet)
1. Remove the "client-side fallback renderer" line from `10-tech-stack.md` (§1.1).
2. Split `inspections.status` into `completion_status` / `sync_status` / `report_status`, and define client-side "Complete" vs. server-side `finalize`/`generate-report` validation explicitly (§1.2, §4.2, §4.4).
3. Add `section_snapshot`/`label_snapshot` to `inspection_checklist_responses` (§4.1).
4. Decide and document the equipment/serial deduplication check at inspection start (§2.1, §5.4).
5. Add the outcome-capture table stub (`equipment_transactions` or equivalent) even if unused by any V1 UI (§5.1).
6. Add a location/region field at minimum at the company level (§5.2).

### Should resolve during V1 build (can happen in parallel with Weeks 1–5, doesn't block starting)
7. Add explicit Storage RLS policy SQL to `08-security-compliance.md` (§4.3).
8. Add discard/cancel-draft capability to the PRD and workflow docs (§2.2).
9. Add permission-handling UX notes to the mobile app spec (§2.3).
10. Add a max clip duration to the capture module spec (§2.4).
11. Rescope "Report Ready" notification to in-app/foregrounded-only for V1; name real push notifications as a V2 item (§2.5).
12. Revisit the OCR candidate-selection UX (present options, don't silently auto-fill) (§4.5).
13. Make an explicit yes/no call on local DB encryption now rather than deferring (§4.6).
14. Sequence tool onboarding (Sentry early; Codemagic/PostHog later in the 8–12 week window) (§3.2).
15. Drop checklist template versioning columns for V1 (§3.1).

### Track for later, no action needed now
16. Coarse condition scale — revisit with real data before V3 scoping (§5.3).
17. Media retention policy — adopt "never auto-delete" as a standing rule (§5.5).
18. Inconsistent capture quality — plan for a V2 data-cleaning pass (§5.6).
19. Dealership data-use consent language — a contracts/legal task, not engineering, but must land before pilot data is reused for V2+ (§5.7).
20. Forgot-password flow, min-app-version enforcement — trivial, fold into normal Week 1–2 auth work (§2.6, §2.7).

---

## 7. What This Review Does Not Change

To be explicit about what remains unchanged and validated by this pass: the core architecture (Flutter + Supabase, local-first sync via outbox pattern, RLS-based multi-tenancy, no custom backend, 8–12 week solo-founder-scoped roadmap) is sound and does not need to be redesigned. Every finding above is a refinement within that architecture, not a reason to reconsider it.

**Recommended next step**: Confirm which items in the "Must resolve before Week 1" list to apply, then I will update the affected documents (`04-data-model.md`, `08-security-compliance.md`, `10-tech-stack.md`, `02-product-requirements.md`, `07-inspection-workflow.md`) accordingly — still documentation only, no application code — before Week 1 of `13-roadmap.md` begins.
