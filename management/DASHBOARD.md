# IronSight AI — Operational Dashboard

**This file always answers: "What should we be working on today?"**

**Maintenance rule**: update this file at the start and end of every work session — human or AI. If you make progress, change a priority, resolve a blocker, or complete a task, this file must reflect it before the session ends. A stale dashboard is worse than no dashboard.

**Last updated**: 2026-07-27

---

## Current Phase

**Implementation in progress.** Documentation for V1 is complete. The repository contains a Flutter application with Supabase-backed auth, company onboarding/settings, equipment CRUD, and the Sprint 008 local inspection foundation on `main`. Engineering verification (Sprint 009), Node.js 24 checkout compatibility (Sprint 010), and Sprint 011 sprint-registry guardrails are completed through their merged PRs (see registry).

## Strategic Roadmap

**Reference: [`docs/13-roadmap.md`](../docs/13-roadmap.md)**

This is the company's single, permanent strategic roadmap — covering the Week 1–12 V1 execution plan and the V2/V3/V4 long-term vision. It is not duplicated here; this dashboard only reflects current status against it.

## Current Sprint

No product sprint is assigned yet. Canonical machine-readable registry: [`management/sprint_registry.json`](./sprint_registry.json) (`nextSprintNumber` = **12**, so the next sprint may be **012**). AFK scope notes: [`management/AFK_SPRINTS.md`](./AFK_SPRINTS.md). Developer workflow source of truth: [`docs/DEVELOPER_WORKFLOW.md`](../docs/DEVELOPER_WORKFLOW.md).

**Sprint 011 — Sprint Registry and Status-Consistency Guardrails** is **completed through PR #13**. No immediate follow-up reconciliation PR is required after that merge.

**Live PR and CI status belongs to GitHub** (pull requests and Actions). Do not duplicate open-PR merge checkboxes here as long-lived unchecked repository tasks.

Sprint history note (immutable numbering): Sprint 003 remains deferred/archived and must never be reused. Sprint 008 (Inspection Local Foundation) merged through PR #9. Sprint 009 (Engineering Reliability, CI, and Developer Workflow Baseline) merged through PR #7 — never rename it “Inspection List Foundation.” Sprint 010 (Node.js 24 / actions/checkout compatibility) merged through PR #12. Sprint 011 completed through PR #13. Multiple sprints may be active in parallel when numbers and scopes do not conflict; validate with `dart run tool/verify_sprint_registry.dart`.

## Current Objective

Assign and execute the next founder-approved sprint via the Pre-Sprint Status Gate using `nextSprintNumber` **12**. Do not invent Sprint 012 product scope from dashboard prose.

## Current Tasks

- [x] Reconcile operational docs for merged Sprints 008–010
- [x] Add `management/sprint_registry.json`
- [x] Add Dart registry validator + focused tests
- [x] Wire validator into PR CI
- [x] Document Pre-Sprint Status Gate and post-merge sync
- [x] Prepare Sprint 011 final registry state (`completed` via PR #13) so no immediate reconciliation PR is required after merge

## Completed Milestones

- ✅ Company vision established
- ✅ Product vision completed (`docs/01-executive-summary.md`)
- ✅ IronSight Constitution completed and approved (`docs/00-ironsight-constitution.md`)
- ✅ Technical architecture approved (Flutter + Supabase, local-first, multi-tenant RLS)
- ✅ CTO pre-development review completed (`docs/14-pre-development-review.md`)
- ✅ Final product specification consolidated (`docs/15-final-product-specification.md`)
- ✅ All 8 founder approval decisions resolved (`docs/16-founder-approval-checklist.md`)
- ✅ Documentation sync pass completed (`docs/04`, `07`, `08` synced with `15`)
- ✅ **Documentation frozen — Implementation Ready** (`docs/18-implementation-ready-report.md`)
- ✅ Operational management system established (this folder)
- ✅ Local Flutter + Supabase development environment established
- ✅ Application foundation on `main` (auth, company, equipment)
- ✅ Sprint 008 Inspection Local Foundation on `main` (PR #9)
- ✅ Sprint 009 engineering verification baseline on `main` (PR #7)
- ✅ Sprint 010 Node.js 24 / actions/checkout@v6 compatibility on `main` (PR #12)
- ✅ Sprint 011 sprint registry + status-consistency guardrails completed through PR #13

Full detail: [`WINS.md`](./WINS.md).

## Upcoming Milestones

- ⬜ First working login (validated with a pilot user on a real device)
- ⬜ First completed inspection (Quick Appraisal, end to end, on a real or test device)
- ⬜ First generated report
- ⬜ First pilot dealership onboarded
- ⬜ First paying customer
- ⬜ Version 1 general release
- ⬜ First AI-assisted inspection (V2)
- ⬜ First valuation prediction (V3)

## Current Blockers

No technical blockers. Next sprint number available: **012** (`nextSprintNumber` = 12). Assign only through the Pre-Sprint Status Gate; do not invent product scope here.

## Active Risks

No dedicated risk register file — tracked here directly, kept short and current:

1. **Silent data loss during offline sync** (High impact) — mitigated by design via the outbox pattern, but not yet validated against a real implementation.
2. **Scope creep back into a slower, more granular default experience**, eroding the core promise — mitigated by the Constitution's Final Decision Framework, but requires ongoing discipline during implementation.
3. **Solo-founder bandwidth / bus-factor risk** — mitigated by this management system and emphasis on simple, well-documented architecture.
4. **Stale operational docs vs. living code / sprint identity drift** — mitigated by Sprint 009’s developer-workflow source of truth and Sprint 011’s sprint registry + CI validator; keep `DASHBOARD.md` current each session and treat GitHub as canonical for live PR/CI state.

## MVP Definition

**One inspection engine, two experience depths.** A rep completes a **Quick Appraisal** (continuous walkaround video, OCR-assisted serial/hour-meter capture, a 6-8 category Quick Condition Scorecard, optional notes, report generation, email sharing) in just a few minutes, fully offline-capable, with the option to expand any category into a **Detailed Inspection** using the same underlying data model. V1 is an inspection platform, not a valuation platform — no pricing or AI features ship in V1.

Full definition: [`docs/15-final-product-specification.md`](../docs/15-final-product-specification.md) §3.

## Success Metrics

- Median time to complete a Quick Appraisal: **just a few minutes** (target, to be validated against real devices and real reps).
- Zero data-loss incidents from offline usage during pilot.
- 100% of completed inspections produce a complete, shareable PDF report.
- At least one pilot dealership actively using WIW for real trade-in evaluations.
- Qualitative: pilot reps prefer WIW to their prior manual process.

## Next Recommended Action

After PR #13 is on `main`, sync local `main`, run `dart run tool/verify_sprint_registry.dart`, then assign Sprint **012** only via the Pre-Sprint Status Gate. No immediate Sprint 011 reconciliation PR is required.
