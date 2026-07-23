# Founder Approval Checklist

**Purpose**: a single, honest, up-to-date list of what's actually been decided, what still needs your explicit sign-off, and what can safely wait. Nothing in this document is new — every item traces back to a decision or open question raised in `docs/00`–`docs/15`. This document exists so that status doesn't have to be reconstructed by re-reading fifteen other documents before Week 1 begins.

**How to use this**: check the "Still Requiring Approval" section before starting any new implementation work that touches it. When you make a decision, tell me and I'll move it to "Approved" and update the source documents accordingly — this list should never fall out of sync with reality.

---

## 1. Approved Decisions

These are settled. Implementation should proceed on these assumptions without re-litigating them.

- [x] **The IronSight Constitution** (`docs/00-ironsight-constitution.md`) is approved as the guiding document for the project — the philosophy every technical and product decision answers to.
- [x] **Core product promise (amended)**: *"IronSight AI enables salespeople to complete a professional trade appraisal in just a few minutes using only their phone, while supporting more detailed inspections when greater documentation is required."* This is the design constraint every V1 feature is measured against.
- [x] **Decision #8 — Documentation sync pass**: `docs/04-data-model.md`, `docs/07-inspection-workflow.md`, and `docs/08-security-compliance.md` have been updated to match every resolution in `docs/15` (completion/sync/report status split, checklist parent/child hierarchy, snapshot columns, continuous-video media model, `equipment_transactions`, `companies.region`, encryption adopted from V1, explicit Storage RLS policy SQL). `docs/13-roadmap.md` subsequently received its own targeted sync pass (Week 1–2/5–7 tasks explicitly naming SQLCipher, `equipment_transactions`, `companies.region`, and the progressive-depth terminology). `docs/01`, `02`, `03`, `05`, `06`, `09`–`12` remain as historical/lower-risk reference and were **not** rewritten — they're vision/roadmap/API framing rather than exact specs an implementer would code directly from, and the README already flags `docs/15` as the authority wherever they'd conflict.
- [x] **Decision #7 — Dealership data-use consent language**: a plain-language draft starting point has been written for you/counsel to refine — `docs/17-dealership-data-use-clause-draft.md`. **Not legal advice; requires attorney review before use in any real agreement.** Must land in (or alongside) the first pilot dealership agreement, not retroactively.
- [x] **Decision #6 — Email sharing scope for V1**: native platform share sheet only (PDF attached, pre-filled subject/body, works offline once the report is cached locally). Branded/tracked transactional email delivery remains a named V2 feature, not built now. Full detail: `docs/15-final-product-specification.md` §13.
- [x] **Decision #5 — Location/region granularity**: `region` captured once per dealership at the company level (zero rep-facing cost). Per-inspection GPS is explicitly deferred, not built in V1 — revisit only if V3 planning or a specific multi-region dealership shows the coarser approximation isn't sufficient. Full detail: `docs/15-final-product-specification.md` §9.
- [x] **Decision #4 — `equipment_transactions` outcome-data table**: added to the V1 schema now (`equipment_id`, `inspection_id` [nullable], `transaction_type`, `trade_offer_amount`, `accepted_trade_value`, `asking_price`, `final_sale_price`, `transaction_date`, `sale_date`, `currency`, `source`, `notes`, `created_by`, `created_at`, plus `company_id` for RLS consistency). All monetary fields nullable. **No in-app UI in V1** — the founder or an authorized manager enters outcomes through a controlled admin/database process during the pilot; a real UI is deferred until pilot usage shows who should enter this data and how. Full schema: `docs/15-final-product-specification.md` §9.
- [x] **Decision #2 — On-device database encryption**: the local `drift`/SQLite database is encrypted with SQLCipher starting in Week 1, not deferred. Full detail: `docs/15-final-product-specification.md` §11, §17 (row 17.8).
- [x] **Decision #1 — Progressive Inspection Workflow (one engine, two depths)**: V1 ships a single inspection engine, not two products. The default **Quick Appraisal** (continuous walkaround video, serial/hour-meter OCR, a 6-8 category Quick Condition Scorecard, optional notes, report generation, email sharing) targets "just a few minutes." Every scorecard category is independently expandable into a **Detailed Inspection** for that category (the original granular, per-item checklist), using the exact same underlying data model — no separate system, no separate report. The granular checklist is **not** deferred to V2; it ships in V1 as an opt-in, per-category path. Continuous walkaround video (replacing 7 discrete clips) is approved. The single-tap **"Restart Walkaround"** action is approved. Full detail and rationale: `docs/15-final-product-specification.md` §5, §9, §17 (row 17.1).
- [x] **V1 is an inspection platform, not a valuation platform.** No pricing, trade-value, or valuation output of any kind ships in V1.
- [x] **Mobile framework: Flutter.** Single codebase for iOS and Android, chosen for camera/video/OCR strength and offline capability.
- [x] **Backend for V1: Supabase** (Postgres + Auth + Storage + Edge Functions), with a documented, deliberate migration path to AWS if/when a specific trigger condition is met (`docs/10-tech-stack.md`).
- [x] **Offline strategy: local-first**, not merely offline-tolerant. The on-device database is the source of truth during an inspection; sync is a background reconciliation, never a blocking dependency for capture.
- [x] **Team model: one founder/product owner, AI-assisted development, no dedicated engineering team.** Every architectural choice optimizes for simplicity and low operating cost over theoretical scale.
- [x] **Timeline: 8–12 week MVP**, scoped tightly to the core inspection workflow.
- [x] **Multi-tenant SaaS architecture from day one** — company-scoped data with Postgres Row Level Security as the actual enforcement boundary — even though V1 launches with a handful of hand-onboarded pilot dealerships.
- [x] **Documentation-first process.** No application code is written until the specification is reviewed and the open items below are resolved.

## 2. Founder Decisions Still Requiring Approval

**All 8 founder decisions have been resolved** — see Section 1 above for the complete, final list, each with a pointer to the governing section of `docs/15-final-product-specification.md`. This section is retained, currently empty, for structural continuity in case a new decision needs tracking before or during Week 1.

| # | Decision | Status |
|---|---|---|
| — | *(none open)* | — |

## 3. Future Decisions That Can Wait

These are correctly out of scope right now. Listed here so they don't get re-litigated prematurely, and so it's clear *when* each one should come back up.

| Decision | Revisit when... |
|---|---|
| Self-serve sign-up / onboarding flow | The business is ready to sell beyond hand-onboarded pilot dealerships (`docs/09-multi-tenant-saas-strategy.md` §3) |
| Billing / Stripe integration | A pricing model (per-seat, per-inspection, flat) is chosen, post-pilot (`docs/09` §4) |
| SSO / SAML enterprise auth | A larger dealership group with existing IT identity systems is being sold to (`docs/08-security-compliance.md` §1) |
| True push notifications (FCM/APNs + server-triggered webhook) | V2 planning — named explicitly as a V2 feature (`docs/15` §12, §16) |
| Branded transactional email with delivery/open tracking | V2 planning, or sooner only if Decision #6 above is answered differently (`docs/15` §13) |
| AI-assisted damage detection, smart checklist suggestions, voice-to-text notes | V2 kickoff, once V1's data corpus is large and consistent enough to justify it (`docs/15` §16, `docs/00-ironsight-constitution.md` §9) |
| Equipment valuation engine | V3 kickoff, contingent on a mature inspection data corpus *and* accumulated `equipment_transactions` outcome data (`docs/15` §16) |
| Cross-tenant market intelligence aggregation | V4 kickoff — requires its own anonymization design pass and legal review before any engineering starts (`docs/09` §5) |
| Formal compliance certification (SOC 2 Type II, etc.) | Enterprise dealership groups make it a sales requirement (`docs/08` §8) |
| Full WCAG accessibility audit; additional locales beyond English | A specific customer or market requirement makes it necessary (`docs/11-non-functional-requirements.md` §8–9) |
| Checklist template versioning system | A real multi-version content need emerges — unlikely at pilot scale given the snapshot-on-write fix already adopted (`docs/15` §9) |
| Dedicated/siloed deployment for a large enterprise dealership group | A specific enterprise contract requires data residency or isolation beyond the standard multi-tenant model (`docs/09` §1) |
| Media retention/cost optimization strategy beyond "never auto-delete" | Storage cost becomes material at real scale (`docs/14-pre-development-review.md` §5.5) |
| Minimum supported app-version enforcement | Implement opportunistically during Week 1–2 auth/sync work — trivial, not a decision that needs founder input, just an engineering task to remember (`docs/14` §2.7) |

---

## Next Step

All 8 founder decisions are resolved, and the source documents (`docs/04-data-model.md`, `docs/07-inspection-workflow.md`, `docs/08-security-compliance.md`) have been synced to match, per Decision #8. The documentation set is now the final baseline for Week 1 implementation. See `docs/18-implementation-ready-report.md` for the formal sign-off.
