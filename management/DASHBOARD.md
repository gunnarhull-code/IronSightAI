# IronSight AI — Operational Dashboard

**This file answers: "What should we be working on today?"** as a founder-maintained, occasional operational summary.

**Maintenance rule**: the **founder** updates this file occasionally when priorities, phase, blockers, or milestones meaningfully change. It is **not** a live Work Item board. **Draft Pull Requests and Actions** are the live sources for Work Item, PR, and CI status. Agents must **not** routinely edit `DASHBOARD.md` for individual Work Items (or every session).

**Last updated**: 2026-08-01

---

## Current Phase

**Implementation in progress.** Documentation for V1 is complete. The repository contains a Flutter application with Supabase-backed auth, company onboarding/settings, equipment CRUD, and the local inspection foundation on `main`. Engineering verification, Node.js 24 checkout compatibility, sprint-registry guardrails (historical), and the Work Items workflow cleanup are tracked via GitHub.

## Strategic Roadmap

**Reference: [`docs/13-roadmap.md`](../docs/13-roadmap.md)**

This is the company's single, permanent strategic roadmap — covering the Week 1–12 V1 execution plan and the V2/V3/V4 long-term vision. It is not duplicated here; this dashboard only reflects current status against it.

## Current Work Item

No product Work Item is assigned yet. Canonical work tracking: **Draft PRs** (founder-approved Cloud Agent prompt freezes scope; the Draft PR is the unique live work record). Permanent AFK/Cloud Agent policy: [`management/AFK_AGENTS.md`](./AFK_AGENTS.md) — do not record assignments there. Developer workflow source of truth: [`docs/DEVELOPER_WORKFLOW.md`](../docs/DEVELOPER_WORKFLOW.md).

**Live PR and CI status belongs to GitHub** (pull requests and Actions). Do not duplicate open-PR merge checkboxes here as long-lived unchecked repository tasks.

Historical numbered sprints are archived in [`LEGACY_SPRINT_HISTORY.md`](./LEGACY_SPRINT_HISTORY.md) (including deferred Sprint 003 and completed Sprints 008–011). Do not revive `sprint_registry.json`.

## Current Objective

Assign the next founder-approved Work Item via a Cloud Agent prompt and Pre-Work-Item Status Gate, then open one Draft PR on `cursor/<work-slug>`. Do not invent product scope from dashboard prose.

## Current Tasks

- [x] Reconcile operational docs for merged historical Sprints 008–011
- [x] Retire sprint registry in favor of GitHub Issue Work Items
- [x] Preserve legacy sprint history
- [x] Update agent skills / workflow docs for Draft-PR-only delivery
- [x] Adopt Draft PRs as unique Work Item records (prompt-frozen scope; Issues optional)

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
- ✅ Inspection Local Foundation on `main` (historical Sprint 008 / PR #9)
- ✅ Engineering verification baseline on `main` (historical Sprint 009 / PR #7)
- ✅ Node.js 24 / actions/checkout@v6 compatibility on `main` (historical Sprint 010 / PR #12)
- ✅ Sprint registry guardrails completed historically (Sprint 011 / PR #13), then retired for Work Items

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

No technical blockers. Assign the next Work Item only through the Pre-Work-Item Status Gate; do not invent product scope here.

## Active Risks

No dedicated risk register file — tracked here directly, kept short and current:

1. **Silent data loss during offline sync** (High impact) — mitigated by design via the outbox pattern, but not yet validated against a real implementation.
2. **Scope creep back into a slower, more granular default experience**, eroding the core promise — mitigated by the Constitution's Final Decision Framework, but requires ongoing discipline during implementation.
3. **Solo-founder bandwidth / bus-factor risk** — mitigated by this management system and emphasis on simple, well-documented architecture.
4. **Stale operational docs vs. living code** — mitigated by `docs/DEVELOPER_WORKFLOW.md`, Draft PRs/Actions as live Work Item and CI sources, and occasional founder updates to this summary; agents must not routinely rewrite shared status files per Work Item.

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

Sync local `main`, then start the next founder-approved Work Item from a Cloud Agent prompt via the Pre-Work-Item Status Gate and open one Draft PR. Do not invent product scope here.
