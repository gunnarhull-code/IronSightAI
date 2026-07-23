# Architectural Decision Log

**Purpose**: a permanent, append-only record of every major architectural or product decision made for IronSight AI. This is not a place to argue for or against a decision after the fact — it is the historical record of what was decided, when, and why, so that no one (human or AI) ever has to reconstruct "why did we do it this way?" from scratch.

**Maintenance rule**: every new architectural or product decision of consequence gets a new entry, in order, at the bottom of this file. **Never delete or renumber a past decision.** If a decision is later reversed or changed, add a **new** entry that supersedes it and cross-reference the old entry — do not edit history.

**Template for new entries:**

```
## ADR-0XX: <Topic>

- **Date**: YYYY-MM-DD
- **Decision**: <what was decided, stated plainly>
- **Reasoning**: <why>
- **Alternatives Considered**: <what else was on the table, and why it lost>
- **Status**: Proposed / Approved / Superseded by ADR-0YY
- **Related Documents**: <links>
```

---

## ADR-001: Mobile Application Framework — Flutter

- **Date**: 2026-07-22
- **Decision**: Build the WIW mobile app in Flutter (Dart), single codebase for iOS and Android.
- **Reasoning**: The product's core value is entirely in the camera/video/OCR capture pipeline, which must run identically on iOS and Android for a mixed fleet of dealership and personal phones, on a solo-founder budget. Flutter's `camera` plugin and on-device ML Kit OCR both run fully offline, directly enabling the offline-first requirement.
- **Alternatives Considered**: React Native (smaller camera/video maturity for this use case); fully native iOS + Android (roughly doubles cost/time for a team of one).
- **Status**: Approved
- **Related Documents**: `docs/10-tech-stack.md`, `docs/06-mobile-app-spec.md`

## ADR-002: Backend Platform — Supabase, with a Documented AWS Migration Path

- **Date**: 2026-07-22
- **Decision**: Build V1's backend on Supabase (managed Postgres + Auth + Storage + Edge Functions), not a custom backend or a full AWS build-out.
- **Reasoning**: One founder, AI-assisted development, no dedicated ops team — Supabase minimizes infrastructure surface area while remaining "just Postgres + S3-compatible storage" underneath, preserving a clean, deliberate migration path to AWS if a specific trigger condition (cost at scale, infrastructure control needs, multi-region requirements) is ever met.
- **Alternatives Considered**: Firebase (less relational, weaker fit for future valuation/BI queries); custom AWS stack (too much infrastructure for a solo founder at this stage); custom Node/NestJS backend (unnecessary given Supabase's auto-generated APIs and Edge Functions).
- **Status**: Approved
- **Related Documents**: `docs/10-tech-stack.md`, `docs/03-technical-architecture.md`

## ADR-003: Offline-First (Local-First) Architecture

- **Date**: 2026-07-22
- **Decision**: The on-device SQLite database (`drift`) is the source of truth during an inspection. No step of the inspection workflow may require network connectivity, except first-time sign-in and PDF report generation.
- **Reasoning**: Equipment yards, rural dealership lots, and auction sites routinely have poor or no cell signal. A field inspection tool that breaks without signal is a non-starter for the target user.
- **Alternatives Considered**: Online-first with offline queuing as a secondary fallback (rejected — treats the common case as the exception); assuming connectivity is always available (rejected outright by the founder in the earliest product discussion).
- **Status**: Approved
- **Related Documents**: `docs/03-technical-architecture.md` §4, `docs/15-final-product-specification.md` §7-§8

## ADR-004: Team & Development Model — Solo Founder, AI-Assisted, No Dedicated Ops Team

- **Date**: 2026-07-22
- **Decision**: All architecture optimizes for one founder building with AI coding tools, favoring managed services, convention over configuration, and minimal custom infrastructure.
- **Reasoning**: Matches actual team capacity. Prevents building infrastructure that requires a team to safely operate.
- **Alternatives Considered**: N/A — stated directly by the founder as a constraint, not a choice among options.
- **Status**: Approved
- **Related Documents**: `docs/10-tech-stack.md`, `docs/00-ironsight-constitution.md` §10

## ADR-005: V1 Timeline — 8-12 Week MVP

- **Date**: 2026-07-22
- **Decision**: Target an 8-12 week build for V1, scoped tightly to the core inspection workflow.
- **Reasoning**: Prioritizes speed to real dealership validation over comprehensiveness. Directly shapes what is and isn't in scope for V1 (see ADR-007).
- **Alternatives Considered**: Longer, more comprehensive initial build (rejected — delays validation with real dealerships and real data, which the whole business model depends on).
- **Status**: Approved
- **Related Documents**: `docs/13-roadmap.md`, `docs/15-final-product-specification.md` §16

## ADR-006: Multi-Tenant SaaS Architecture From Day One

- **Date**: 2026-07-22
- **Decision**: Every tenant-scoped table carries `company_id`, enforced by Postgres Row Level Security — built in from the first schema migration, even though V1 launches with a handful of hand-onboarded pilot dealerships.
- **Reasoning**: Retrofitting real tenant isolation into a system built without it is expensive and risky. Designing for it now costs almost nothing extra.
- **Alternatives Considered**: Single-tenant V1 schema with multi-tenancy added later (rejected — directly violates the Constitution's "build for the company we intend to become" principle).
- **Status**: Approved
- **Related Documents**: `docs/04-data-model.md`, `docs/08-security-compliance.md` §2, `docs/09-multi-tenant-saas-strategy.md`

## ADR-007: V1 Scope — Inspection Platform, Not Valuation Platform

- **Date**: 2026-07-22
- **Decision**: V1 contains zero pricing, valuation, or AI features. Its entire scope is a fast, structured, professional equipment inspection and report.
- **Reasoning**: A valuation is only as trustworthy as the inspection data underneath it. V1's job is to build that data foundation and prove the workflow with real dealerships before any AI/valuation investment.
- **Alternatives Considered**: Building a lightweight valuation estimate into V1 (explicitly rejected by the founder from the original product brief).
- **Status**: Approved
- **Related Documents**: `docs/02-product-requirements.md` §5, `docs/00-ironsight-constitution.md` §14

## ADR-008: The IronSight Constitution — Approved as Guiding Document

- **Date**: 2026-07-23
- **Decision**: `docs/00-ironsight-constitution.md` is approved as the company's founding philosophy document — the first document any developer or AI assistant reads, and the authority every technical document answers to.
- **Reasoning**: Establishes durable, non-negotiable principles (field-first design, simplicity over complexity, AI assists but never silently replaces judgment, the Data Flywheel strategy) that outlive any individual technical specification.
- **Alternatives Considered**: N/A — a foundational document created and approved by explicit founder request.
- **Status**: Approved
- **Related Documents**: `docs/00-ironsight-constitution.md`

## ADR-009: Progressive Inspection Model — One Engine, Two Depths (Quick Appraisal + Detailed Inspection)

- **Date**: 2026-07-23
- **Decision**: V1 ships a single inspection engine with two experience depths: a default **Quick Appraisal** (6-8 category Quick Condition Scorecard, one tap per category) and an optional, per-category expandable **Detailed Inspection** (the original granular, per-part checklist), built on the same underlying data model (`checklist_template_items` with a self-referencing `parent_item_id`). The core product promise was reworded from a literal "under two minutes" to *"just a few minutes, with more detailed inspections when greater documentation is required."*
- **Reasoning**: The founder rejected the initial recommendation to remove checklist depth from V1 entirely (deferring it to V2). The progressive model achieves the speed goal for the default path without sacrificing documentation depth when a machine warrants it, and does so as one system rather than two, avoiding duplicated data models and future rework.
- **Alternatives Considered**: (a) Remove the granular checklist from V1 entirely, defer to V2 as originally recommended — rejected by founder. (b) Keep the original fully-granular checklist as the only V1 option — rejected, incompatible with a fast default experience. (c) Two separate systems/data models for Quick vs. Detailed — rejected by the founder explicitly ("I do not want two separate systems or two separate data models").
- **Status**: Approved (Founder Decision #1)
- **Related Documents**: `docs/15-final-product-specification.md` §3, §5, §9, §17 (row 17.1); `docs/16-founder-approval-checklist.md`; `docs/04-data-model.md`; `docs/07-inspection-workflow.md`

## ADR-010: Continuous Walkaround Video + Single-Tap "Restart Walkaround"

- **Date**: 2026-07-23
- **Decision**: The walkaround is captured as one continuous video recording (with structured timestamp markers for each angle prompt), replacing the original design of seven discrete stop/start clips. A single-tap "Restart Walkaround" action discards and re-records the entire take when needed.
- **Reasoning**: Seven manual stop/start actions cost real time and cognitive overhead, working against the core speed promise. Timestamp markers preserve the same AI-readiness property (isolating "the undercarriage portion" of the video later) without the capture-time cost.
- **Alternatives Considered**: Keep seven discrete clips (rejected — too slow); continuous video with per-segment retake (rejected — not technically coherent for a single continuous recording; replaced with whole-take restart instead).
- **Status**: Approved (part of Founder Decision #1)
- **Related Documents**: `docs/15-final-product-specification.md` §5, `docs/04-data-model.md` (`inspection_media.timestamp_markers`), `docs/07-inspection-workflow.md`

## ADR-011: On-Device Database Encryption (SQLCipher) Adopted From Week 1

- **Date**: 2026-07-23
- **Decision**: The local `drift`/SQLite database is encrypted with SQLCipher starting with the first Week 1 migration, reversing the original "defer until required" posture.
- **Reasoning**: Retrofitting encryption onto an app already holding real pilot data in the field would require a live migration of populated databases across devices already deployed — meaningfully harder and riskier than configuring it once at the start. The cost of adopting it now is small and one-time.
- **Alternatives Considered**: Defer encryption until a dealership/compliance requirement forces it — rejected as a "cheap now, expensive later" trade-off with an unusually clear-cut answer.
- **Status**: Approved (Founder Decision #2)
- **Related Documents**: `docs/15-final-product-specification.md` §11, §17 (row 17.8); `docs/08-security-compliance.md` §3

## ADR-012: `equipment_transactions` Outcome-Data Table — Schema-Only in V1

- **Date**: 2026-07-23
- **Decision**: Add an `equipment_transactions` table to the V1 schema (fields: `equipment_id`, `inspection_id` [nullable], `transaction_type`, `trade_offer_amount`, `accepted_trade_value`, `asking_price`, `final_sale_price`, `transaction_date`, `sale_date`, `currency`, `source`, `notes`, `created_by`, `created_at`, plus `company_id` for RLS), with no in-app UI in V1. The founder or an authorized manager enters transaction outcomes through a controlled admin/database process during the pilot.
- **Reasoning**: A future valuation model (V3) needs real-world trade/sale outcomes as ground truth, correlated with inspection condition data. This cannot be captured retroactively — every deal that closes before this table exists is permanently unusable as training data. The cost of adding the table now (schema-only) is negligible; the cost of not having it later is a lost year (or more) of outcome data.
- **Alternatives Considered**: Build a minimal in-app UI for this now (rejected — outside the core Quick Appraisal flow, premature before pilot usage shows who should enter this data and how); skip entirely until V3 planning (rejected — the entire point is that it can't be added retroactively).
- **Status**: Approved (Founder Decision #4)
- **Related Documents**: `docs/15-final-product-specification.md` §9; `docs/04-data-model.md`

## ADR-013: Location/Region Granularity — Company-Level Only for V1

- **Date**: 2026-07-23
- **Decision**: Capture `region` once per dealership at the `companies` level. Per-inspection GPS is explicitly deferred, not built in V1.
- **Reasoning**: Most inspections happen on or near the dealership's own lot; company-level region captures nearly all the future value (V3 regional valuation, V4 regional market trends) at zero rep-facing cost or permission-prompt friction.
- **Alternatives Considered**: Per-inspection GPS capture (rejected for V1 — adds a permission prompt and privacy consideration without a validated need); skip location entirely (rejected — impossible to backfill onto historical inspections later).
- **Status**: Approved (Founder Decision #5)
- **Related Documents**: `docs/15-final-product-specification.md` §9; `docs/04-data-model.md` (`companies.region`)

## ADR-014: Email Sharing — Native Share Sheet Only for V1

- **Date**: 2026-07-23
- **Decision**: V1 report sharing uses the phone's native platform share sheet (PDF attached, pre-filled subject/body), not a custom branded/tracked email delivery system.
- **Reasoning**: Fully satisfies the actual job (get the report to the right person) with zero new infrastructure, works offline once the report is cached locally, and costs nothing to build or operate. Branded/tracked delivery is a legitimate future feature but should be justified by validated pilot demand, not built speculatively.
- **Alternatives Considered**: Branded transactional email with delivery/open tracking now (rejected for V1 — real recurring infrastructure cost and operational surface for a solo founder, deferred to V2).
- **Status**: Approved (Founder Decision #6)
- **Related Documents**: `docs/15-final-product-specification.md` §13

## ADR-015: Dealership Data-Use Consent Language — Draft Produced, Pending Legal Review

- **Date**: 2026-07-23
- **Decision**: A plain-language draft data-use clause was produced to give the founder/counsel a starting point for the first pilot dealership agreement, explicitly marked as not legal advice.
- **Reasoning**: Trade-in equipment inspected under V1 often belongs to a third-party customer at inspection time. Consent for future AI training/aggregation use cannot be obtained retroactively — it must be addressed in the first pilot agreement, not after.
- **Alternatives Considered**: Founder handles this entirely independently with outside counsel (available but not selected); defer the decision until closer to the first agreement (rejected — the whole risk is that it's easy to forget until it's too late).
- **Status**: Approved — drafted; **pending attorney review before use in any real agreement** (Founder Decision #7)
- **Related Documents**: `docs/17-dealership-data-use-clause-draft.md`

## ADR-016: Documentation Sync Pass — Targeted, Not Full

- **Date**: 2026-07-23
- **Decision**: `docs/04-data-model.md`, `docs/07-inspection-workflow.md`, and `docs/08-security-compliance.md` were rewritten to match every resolution in `docs/15-final-product-specification.md` in full. Other supporting documents (`01`, `02`, `03`, `05`, `06`, `09`-`13`) were intentionally left as historical/lower-risk reference, not rewritten.
- **Reasoning**: The three synced documents are the ones an implementer would code directly from (schema, workflow, security policy). The others are vision/roadmap/API framing documents where a stale detail is lower-risk, and `docs/15` is already flagged repo-wide as the authority wherever a conflict would arise.
- **Alternatives Considered**: Full sync of all documents `01`-`14` (rejected — significant additional effort for lower-risk documents); no sync at all, `docs/15` as sole authority (rejected — leaves the highest-risk documents, which an implementer is most likely to read directly, actively contradicting the approved design).
- **Status**: Approved (Founder Decision #8)
- **Related Documents**: `docs/16-founder-approval-checklist.md`, `docs/18-implementation-ready-report.md`
