# IronSight AI — WIW ("What's It Worth")

A mobile-first, AI-ready heavy equipment inspection platform for equipment dealerships, used equipment managers, and sales representatives.

**Status: ✅ Implementation Ready.** This repository currently contains product documentation and a technical blueprint only — no application code has been written yet, by design (documentation-first per project process). **All founder decisions are resolved.** See [`docs/18-implementation-ready-report.md`](./docs/18-implementation-ready-report.md) for the formal sign-off.

## Read in This Order

1. **[`docs/00-ironsight-constitution.md`](./docs/00-ironsight-constitution.md)** — **Document Zero.** The company's founding mission, vision, philosophy, and non-negotiable principles. Read this before anything else, and before making any product or architectural decision, human or AI. This is not a technical document — it is what every technical document answers to. **Approved as the guiding document for the project.**
2. **[`docs/15-final-product-specification.md`](./docs/15-final-product-specification.md)** — The single source of truth for the *product*. Consolidates and resolves every contradiction found across the supporting documents (`01`–`14`) and is built around the core product promise: *"IronSight AI enables salespeople to complete a professional trade appraisal in just a few minutes using only their phone — while supporting more detailed inspections when greater documentation is required."*
3. **[`docs/16-founder-approval-checklist.md`](./docs/16-founder-approval-checklist.md)** — All 8 founder decisions and their final rulings; retained as the live tracker for any future decision.
4. **[`docs/18-implementation-ready-report.md`](./docs/18-implementation-ready-report.md)** — Formal confirmation that documentation is complete and development may begin.

Docs `01`–`14` remain as detailed supporting reference (rationale, full SQL, diagrams) but defer to `15` wherever they conflict, and everything defers to `00` on questions of philosophy, priority, or principle. `docs/04`, `07`, and `08` have been fully synced with `15`; see `docs/18` §5 for the complete consistency status.

## Daily Development Workflow

The [`management/`](./management/) folder is the operational system of IronSight AI — it answers "what should we be working on today?" and preserves company context independently of any one person's memory. **Every development session, human or AI, should begin by:**

1. Read [`management/DASHBOARD.md`](./management/DASHBOARD.md)
2. Read [`docs/00-ironsight-constitution.md`](./docs/00-ironsight-constitution.md)
3. Read [`docs/15-final-product-specification.md`](./docs/15-final-product-specification.md)
4. Read [`docs/13-roadmap.md`](./docs/13-roadmap.md)
5. Read [`management/DECISIONS.md`](./management/DECISIONS.md)
6. Summarize the current project state.
7. Begin implementation.

**Operating principle**: these management documents are maintained throughout the life of the company, not just during the initial documentation phase. Before every future coding session ends, update [`DASHBOARD.md`](./management/DASHBOARD.md), [`DECISIONS.md`](./management/DECISIONS.md) (if a new decision was made), and [`CHANGELOG.md`](./management/CHANGELOG.md) to reflect the current state of the project. The goal: if development stops for six months, any developer or AI assistant can immediately understand where the project stands and continue without losing context.

## Documentation Philosophy: `docs/` vs `management/`

There must never be duplicate sources of truth. Each of the following lives in exactly one place:

- **`docs/`** — long-lived, mostly static documentation: the Constitution, technical architecture, the product specification, and the **strategic roadmap** (`docs/13-roadmap.md`, the company's single, permanent roadmap).
- **`management/`** — living operational documents that change throughout development: the Dashboard, Decisions, Changelog, Backlog, Founder Log, and Wins.

The strategic roadmap exists **only** in `docs/13-roadmap.md`. The management folder references it; it never duplicates it.

## Management Folder

| File | Purpose |
|---|---|
| [`management/DASHBOARD.md`](./management/DASHBOARD.md) | Operational command center — what to work on today; references `docs/13-roadmap.md` for the strategic roadmap |
| [`management/DECISIONS.md`](./management/DECISIONS.md) | Permanent architectural decision log (ADRs) |
| [`management/CHANGELOG.md`](./management/CHANGELOG.md) | Chronological project history |
| [`management/BACKLOG.md`](./management/BACKLOG.md) | Ideas intentionally deferred from the MVP, by priority |
| [`management/FOUNDER_LOG.md`](./management/FOUNDER_LOG.md) | Founder journal — customer conversations, ideas, lessons learned |
| [`management/WINS.md`](./management/WINS.md) | Milestone journal |

## Key Decisions (Locked for V1)

- **Core promise**: a rep completes a professional trade appraisal in just a few minutes, using only their phone — with the option to go deeper on any category when a machine warrants more documentation.
- **One inspection engine, two depths**: a fast default Quick Appraisal and an optional, per-category expandable Detailed Inspection, built on the same data model — never two separate systems.
- **Mobile app**: Flutter — single codebase, strong camera/video/OCR capability, works fully offline.
- **Backend**: Supabase (Postgres + Auth + Storage + Edge Functions) — minimal ops for a solo founder, with a documented migration path to AWS if/when needed.
- **Offline strategy**: Local-first. The device's local SQLite database is the source of truth during an inspection; a background sync engine reconciles with Supabase whenever connectivity is available. No step in the inspection workflow may require a network connection.
- **Team model**: One founder/product owner, AI-assisted development, no dedicated engineering team — every architectural choice optimizes for simplicity, maintainability, and low operating cost over theoretical scale.
- **Timeline**: 8–12 week MVP scoped tightly to the core inspection workflow.
- **Multi-tenant from day one**: even though V1 serves a handful of pilot dealerships, tenancy (company-scoped data + Postgres Row Level Security) is built in now rather than retrofitted later.
- **V1 is an inspection platform, not a valuation platform.** No pricing, valuation, or AI damage detection ships in V1.

## Documentation Index

| # | Document | Covers |
|---|---|---|
| 00 | [`docs/00-ironsight-constitution.md`](./docs/00-ironsight-constitution.md) | **Read first.** Company mission, vision, philosophy, and non-negotiable principles |
| 01 | [`docs/01-executive-summary.md`](./docs/01-executive-summary.md) | Product vision, problem/solution, guiding principles, roadmap at a glance |
| 02 | [`docs/02-product-requirements.md`](./docs/02-product-requirements.md) | V1 PRD — personas, functional requirements, scope boundaries, success metrics |
| 03 | [`docs/03-technical-architecture.md`](./docs/03-technical-architecture.md) | System architecture, offline-first sync design, AI-ready data pipeline |
| 04 | [`docs/04-data-model.md`](./docs/04-data-model.md) | Postgres schema, ER diagram, multi-tenant design — **synced with `15`** |
| 05 | [`docs/05-api-design.md`](./docs/05-api-design.md) | Client/backend contract (Supabase tables + Edge Functions) |
| 06 | [`docs/06-mobile-app-spec.md`](./docs/06-mobile-app-spec.md) | Flutter app structure, camera/video/OCR modules, sync engine |
| 07 | [`docs/07-inspection-workflow.md`](./docs/07-inspection-workflow.md) | Screen-by-screen guided inspection UX — **rewritten to match `15` §5** (progressive Quick Appraisal / Detailed Inspection model) |
| 08 | [`docs/08-security-compliance.md`](./docs/08-security-compliance.md) | Auth, RLS tenant isolation, encryption, data ownership — **synced with `15`** (encryption adopted from V1, explicit Storage policy SQL) |
| 09 | [`docs/09-multi-tenant-saas-strategy.md`](./docs/09-multi-tenant-saas-strategy.md) | Tenancy model, roles, billing-readiness |
| 10 | [`docs/10-tech-stack.md`](./docs/10-tech-stack.md) | Concrete stack decisions + justification + migration triggers |
| 11 | [`docs/11-non-functional-requirements.md`](./docs/11-non-functional-requirements.md) | Performance, reliability, cost, device support targets |
| 12 | [`docs/12-equipment-taxonomy.md`](./docs/12-equipment-taxonomy.md) | Make/model/category data model, extensibility rules |
| 13 | [`docs/13-roadmap.md`](./docs/13-roadmap.md) | Week-by-week V1 plan + V2-V4 vision (superseded in part by `15` §16) |
| 14 | [`docs/14-pre-development-review.md`](./docs/14-pre-development-review.md) | CTO pre-development review — conflicts, gaps, risks, and required fixes before Week 1 |
| 15 | [`docs/15-final-product-specification.md`](./docs/15-final-product-specification.md) | **Single source of truth.** Consolidated, contradiction-resolved final spec |
| 16 | [`docs/16-founder-approval-checklist.md`](./docs/16-founder-approval-checklist.md) | Approved decisions, open founder decisions, and deferred future decisions |
| 17 | [`docs/17-dealership-data-use-clause-draft.md`](./docs/17-dealership-data-use-clause-draft.md) | Draft dealership data-use consent language for future AI training — **not legal advice**, requires attorney review |
| 18 | [`docs/18-implementation-ready-report.md`](./docs/18-implementation-ready-report.md) | **Formal sign-off** — documentation complete, all founder decisions resolved, development may begin |

> **Numbering note**: `docs/00-ironsight-constitution.md` is "Document Zero" — the company's foundational document, read before the numbered product/technical sequence begins. Documents `01`–`18` are numbered sequentially in intended reading order. If a new document is added later, it should be appended at the end of the sequence rather than inserted mid-sequence, to avoid another renumbering pass.

## Non-Goals for V1 (Read Before Proposing Features)

No pricing/valuation output, no AI damage detection, no customer-facing portal, no billing/payments, no web inspection experience, no DMS/CRM integration, no true push notifications. (Note: the granular, per-item Detailed Inspection is **in scope for V1** as an optional, per-category expansion of the Quick Appraisal — see Founder Decision #1 in `docs/16`.) See [`docs/15-final-product-specification.md`](./docs/15-final-product-specification.md#4-explicitly-excluded-features) Section 4 for the authoritative, current list — it supersedes the non-goals list in `docs/02-product-requirements.md` where the two documents differ.

## Next Step

Documentation is complete and all founder decisions are resolved — see [`docs/18-implementation-ready-report.md`](./docs/18-implementation-ready-report.md) for the formal sign-off. The next phase is Week 1 implementation per [`docs/13-roadmap.md`](./docs/13-roadmap.md) and [`docs/15-final-product-specification.md`](./docs/15-final-product-specification.md) Section 16 — Supabase project setup, Flutter scaffold, schema migrations (including the `completion_status`/`sync_status`/`report_status` split, the checklist parent/child hierarchy, and the new schema stubs), and the auth flow. No code has been written yet; beginning implementation requires the founder's explicit go-ahead.
