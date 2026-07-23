# IronSight AI — Operational Dashboard

**This file always answers: "What should we be working on today?"**

**Maintenance rule**: update this file at the start and end of every work session — human or AI. If you make progress, change a priority, resolve a blocker, or complete a task, this file must reflect it before the session ends. A stale dashboard is worse than no dashboard.

**Last updated**: 2026-07-23

---

## Current Phase

**Documentation — ✅ Complete.** **Week 1 (Foundation) — Not yet started.** Awaiting founder's explicit go-ahead to begin writing application code.

**No application code exists in this repository yet.** Everything to date is documentation and planning, per the founder's explicit "do not write code yet" instruction across every session so far.

## Strategic Roadmap

**Reference: [`docs/13-roadmap.md`](../docs/13-roadmap.md)**

This is the company's single, permanent strategic roadmap — covering the Week 1–12 V1 execution plan and the V2/V3/V4 long-term vision. It is not duplicated here; this dashboard only reflects current status against it.

## Current Sprint

**Sprint 1 — Foundation.** Detailed plan: [`management/sprints/SPRINT-1.md`](./sprints/SPRINT-1.md). Maps to `docs/13-roadmap.md`, "Weeks 1–2: Foundation." Not yet started — awaiting founder go-ahead to begin writing application code.

## Current Objective

Stand up the complete technical foundation so every later sprint builds on a working, secure, correctly-modeled system: scaffold the Flutter app with the approved layered architecture, provision the Supabase projects, implement the full approved schema (including the `completion_status`/`sync_status`/`report_status` split, the checklist parent/child hierarchy, `equipment_transactions`, `companies.region`) with Row Level Security verified end to end, encrypt the local database with SQLCipher from the start, and get a signed-in user to a real (empty) inspection list backed by a genuine Supabase query. Full detail, task-by-task: [`management/sprints/SPRINT-1.md`](./sprints/SPRINT-1.md).

## Current Tasks

Full 20-task breakdown with dependencies, complexity, and expected outcomes: [`management/sprints/SPRINT-1.md`](./sprints/SPRINT-1.md) ("Task Breakdown" and "Recommended Build Order"). First tasks in build order:

- [ ] **Obtain founder go-ahead to begin writing application code.** (This is the single next action — see "Next Recommended Action" below.)
- [ ] Task 1 — Git repository & base project scaffold
- [ ] Task 2 — Flutter project initialization
- [ ] Task 3 — Project architecture & folder structure (layered, import-boundary enforced)
- [ ] Task 4 — Riverpod dependency injection / state management setup
- [ ] Task 5 — Supabase project provisioning (dev + prod, per `docs/03-technical-architecture.md` §7)
- [ ] Task 7 — Full V1 schema migration (per `docs/04-data-model.md`) — the sprint's highest-risk, highest-leverage task
- [ ] Task 8/9/10 — Row Level Security (Postgres + Storage) and mandatory two-tenant manual verification

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

Full detail: [`WINS.md`](./WINS.md).

## Upcoming Milestones

- ⬜ First working login
- ⬜ First completed inspection (Quick Appraisal, end to end, on a real or test device)
- ⬜ First generated report
- ⬜ First pilot dealership onboarded
- ⬜ First paying customer
- ⬜ Version 1 general release
- ⬜ First AI-assisted inspection (V2)
- ⬜ First valuation prediction (V3)

## Current Blockers

- **Founder go-ahead to begin coding.** All prior sessions have operated under an explicit "do not write application code yet" instruction. This is not a technical blocker — the documentation and schema are ready — it is a deliberate process gate, and it is the literal next thing to resolve.

No technical blockers exist at this time.

## Active Risks

No dedicated risk register file — tracked here directly, kept short and current:

1. **Silent data loss during offline sync** (High impact) — mitigated by design via the outbox pattern, but not yet validated against a real implementation.
2. **Scope creep back into a slower, more granular default experience**, eroding the core promise — mitigated by the Constitution's Final Decision Framework, but requires ongoing discipline during implementation.
3. **Solo-founder bandwidth / bus-factor risk** — mitigated by this very management system and the emphasis on simple, well-documented architecture.

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

**Confirm with the founder that application code may now be written**, then begin Sprint 1 exactly per its Recommended Build Order in [`management/sprints/SPRINT-1.md`](./sprints/SPRINT-1.md): Task 1 (Git repository & base project scaffold) through Task 4 (Riverpod setup) first, before touching Supabase or the schema.
