# IronSight AI — Operational Dashboard

**This file always answers: "What should we be working on today?"**

**Maintenance rule**: update this file at the start and end of every work session — human or AI. If you make progress, change a priority, resolve a blocker, or complete a task, this file must reflect it before the session ends. A stale dashboard is worse than no dashboard.

**Last updated**: 2026-07-26

---

## Current Phase

**Implementation in progress.** Documentation for V1 is complete. The repository contains a Flutter application with Supabase-backed auth, company onboarding/settings, and equipment CRUD on `main`. Engineering verification / CI baseline is the active reliability sprint.

## Strategic Roadmap

**Reference: [`docs/13-roadmap.md`](../docs/13-roadmap.md)**

This is the company's single, permanent strategic roadmap — covering the Week 1–12 V1 execution plan and the V2/V3/V4 long-term vision. It is not duplicated here; this dashboard only reflects current status against it.

## Current Sprint

**Sprint 009 — Engineering Reliability, CI, and Developer Workflow Baseline.** Active AFK sprint file: [`management/AFK_SPRINTS.md`](./AFK_SPRINTS.md). Developer workflow source of truth: [`docs/DEVELOPER_WORKFLOW.md`](../docs/DEVELOPER_WORKFLOW.md).

Sprint history note (immutable numbering): Sprint 003 is postponed; Sprints 004–007 are treated as completed assignments per founder sprint process. Sprint 008 (inspection foundation) is merged on `main`; Sprint 009 must not modify inspection-domain code even though that code is present after merging `main`.

## Current Objective

Establish a dependable engineering-verification baseline: accurate setup docs, GitHub Actions CI for PRs to `main`, PR template completeness, safe test configuration, and documented Windows/Brave + post-merge + production migration safety workflows — without product-feature work and without touching inspection-domain code.

## Current Tasks

- [x] Audit existing Flutter/CI/test/docs workflow gaps
- [x] Correct stale “no application code” documentation claims
- [x] Add `docs/DEVELOPER_WORKFLOW.md` as setup/verification source of truth
- [x] Add GitHub Actions CI (format / analyze / test) for PRs targeting `main`
- [x] Add/improve pull-request template fields
- [x] Document Windows + Brave, post-merge sync, production migration safety gate
- [ ] Merge Sprint 009 Draft PR after founder review (human action)

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

No technical blockers for Sprint 009. Sprint 008 is on `main`; do not change inspection-domain code in this sprint.

## Active Risks

No dedicated risk register file — tracked here directly, kept short and current:

1. **Silent data loss during offline sync** (High impact) — mitigated by design via the outbox pattern, but not yet validated against a real implementation.
2. **Scope creep back into a slower, more granular default experience**, eroding the core promise — mitigated by the Constitution's Final Decision Framework, but requires ongoing discipline during implementation.
3. **Solo-founder bandwidth / bus-factor risk** — mitigated by this management system and emphasis on simple, well-documented architecture.
4. **Stale operational docs vs. living code** — mitigated by Sprint 009’s single developer-workflow source of truth; keep `DASHBOARD.md` current each session.

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

Complete founder review of the Sprint 009 Draft PR (CI + developer workflow baseline), then continue product work from the next assigned immutable sprint — keeping Sprint 008 inspection work on its own branch/PR.
