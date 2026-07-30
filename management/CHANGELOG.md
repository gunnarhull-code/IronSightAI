# IronSight AI — Changelog

**Purpose**: the official, chronological history of the project — every meaningful event, from the first documentation draft through every future release. Unlike [`DECISIONS.md`](./DECISIONS.md) (which records *why* a decision was made), this file records *what happened and when*, in the order it happened.

**Maintenance rule**: add a new dated entry every session in which meaningful progress occurs — a document created, a decision resolved, a feature shipped, a milestone hit. Newest entries at the top, under an `## [Unreleased]` heading for work in progress. Once a version is actually released (e.g., V1 ships to the first pilot dealership), move its entries under a versioned heading (e.g., `## [1.0.0] - 2026-XX-XX`), following the spirit of [Keep a Changelog](https://keepachangelog.com/), adapted for a pre-launch product+documentation history.

---

## [Unreleased]

Application foundation exists on `main` (Flutter + local Supabase: auth, company, equipment, local inspection foundation). Historical Sprints 009–011 are merged. Numbered sprints and `management/sprint_registry.json` are retired in favor of GitHub Issue Work Items.

### Added
- **2026-07-29**: Work Items workflow — GitHub Issues replace numbered sprints; `management/AFK_AGENTS.md` replaces `AFK_SPRINTS.md`; `management/LEGACY_SPRINT_HISTORY.md` archives former registry identities; Cursor skills updated for Draft-PR-only delivery. No feature migrations. No product features.
- **2026-07-27**: Sprint 011 — sprint registry and status-consistency guardrails: `management/sprint_registry.json` (canonical sprint numbers/lifecycle), `tool/sprint_registry_validation.dart` + `tool/verify_sprint_registry.dart` (read-only validator), focused tests, CI step, Pre-Sprint Status Gate documentation, and PR-template registry checklist. No feature migrations. No product features. **Completed through PR #13** (final registry state prepared in that PR; no immediate reconciliation PR required). *(Later retired by the Work Items workflow.)*
- **2026-07-26**: Sprint 009 — engineering reliability baseline: `docs/DEVELOPER_WORKFLOW.md` (setup/verification source of truth), `.github/workflows/ci.yml` (format/analyze/test on PRs to `main`), `.github/PULL_REQUEST_TEMPLATE.md`, `scripts/verify.sh`, and `test/env_example_test.dart` for safe `.env.example` bootstrap coverage. No feature migrations. **Merged through PR #7.**
- **2026-07-23**: `management/sprints/SPRINT-1.md` — detailed Sprint 1 (Foundation) implementation plan: sprint goal, deliverables, in/out of scope, a 20-task dependency-ordered breakdown (purpose, dependencies, complexity, expected outcome per task), recommended build order, git milestones, a per-deliverable testing plan, a measurable Definition of Done, Sprint-1-specific risks with mitigations, and a Sprint 2 preview. Maps directly to `docs/13-roadmap.md`'s "Weeks 1–2: Foundation" section without duplicating it — this is the execution-level detail one layer below the strategic roadmap. Housed in a new `management/sprints/` subfolder so the top-level `management/` structure stays fixed at six files. `management/DASHBOARD.md`'s "Current Sprint," "Current Objective," "Current Tasks," and "Next Recommended Action" populated from this plan.

### Changed
- **2026-07-29**: Retired sprint registry validator, CI step, and Pre-Sprint Status Gate; replaced with Pre-Work-Item Status Gate and Issue-linked Draft PRs. Agents create Draft PRs and never merge.
- **2026-07-27**: Reconciled operational docs with verified GitHub history: Sprint 008 Inspection Local Foundation merged (PR #9); Sprint 009 Engineering Reliability/CI merged (PR #7); Sprint 010 Node.js 24 / actions/checkout compatibility merged (PR #12). Removed obsolete “merge Sprint 009” instructions. Clarified that live PR/CI status belongs to GitHub. Active AFK sprint updated to Sprint 011. Sprint 003 remains deferred/archived.
- **2026-07-27**: Sprint 010 — GitHub Actions Node.js 24 compatibility: `.github/workflows/ci.yml` upgraded `actions/checkout` from v4 to v6 with `persist-credentials: false`. **Merged through PR #12.**
- **2026-07-26**: Corrected stale claims that the repository contained no application code (`README.md`, `management/DASHBOARD.md`, this changelog). Pointed setup/verification docs at `docs/DEVELOPER_WORKFLOW.md` to avoid duplicated long instructions. Active AFK sprint updated to Sprint 009 (later superseded as active by Sprint 011 after 009/010 merged).
- **2026-07-23**: Founder decision — the project maintains a **single strategic roadmap**, `docs/13-roadmap.md`, permanently. `management/ROADMAP.md` (the 7-phase business-stage roadmap created earlier the same day) is **removed** as a duplicate source of truth, along with `management/SPRINTS.md` (its sprint-level content duplicated `docs/13-roadmap.md`'s Week 1-2 tasks) and `management/RISKS.md` (folded inline into `management/DASHBOARD.md`'s "Active Risks" section instead of a separate file). The management folder is now fixed at six files: `DASHBOARD.md`, `DECISIONS.md`, `CHANGELOG.md`, `BACKLOG.md`, `FOUNDER_LOG.md`, `WINS.md`. `DASHBOARD.md`'s "Current Phase"/"Current Sprint" sections replaced with a "Strategic Roadmap" section that references `docs/13-roadmap.md` rather than restating it. `BACKLOG.md` and `FOUNDER_LOG.md` had their references to the removed files corrected to point to `docs/13-roadmap.md` instead. `README.md`'s Daily Development Workflow updated to a 7-step sequence that explicitly includes reading `docs/13-roadmap.md`, and a new "Documentation Philosophy: `docs/` vs `management/`" section added stating the no-duplicate-sources-of-truth rule explicitly.
- **2026-07-23 (earlier)**: `management/ROADMAP.md` restructured from 8 phases to 7 (superseded later the same day by the removal above). The standalone "Version 2 (Kickoff & Planning)" phase was removed and merged into a single "AI Assistance" phase that covers both planning and delivery as one business stage.

### Planned Next
- Assign the next founder-approved GitHub Issue Work Item via the Pre-Work-Item Status Gate. Do not invent product scope in changelog prose. See [`docs/13-roadmap.md`](../docs/13-roadmap.md).

---

## 2026-07-23

### Added
- Operational management system established: `management/DASHBOARD.md`, `DECISIONS.md`, `CHANGELOG.md` (this file), `ROADMAP.md`, `SPRINTS.md`, `BACKLOG.md`, `RISKS.md`, `FOUNDER_LOG.md`, `WINS.md`.
- `docs/18-implementation-ready-report.md` — formal sign-off confirming documentation is complete and all founder decisions are resolved.
- `docs/17-dealership-data-use-clause-draft.md` — draft data-use consent language for future pilot agreements (not legal advice).
- `docs/16-founder-approval-checklist.md` — created, then worked through decision-by-decision to full resolution across this and prior sessions.

### Changed
- **Founder Decision #1 (biggest change of the review)**: core product promise reworded from a literal "under two minutes" to "just a few minutes, with more detailed inspections when greater documentation is required." Inspection workflow redesigned around a single engine with two depths — Quick Appraisal (default) and Detailed Inspection (optional, per-category, expandable) — rather than removing checklist depth from V1 as originally recommended.
- `docs/00-ironsight-constitution.md` — core promise and five other references updated to match the amended promise.
- `docs/15-final-product-specification.md` — Sections 3, 4, 5, 9, 10, 12, 15, 16, 17, 18 revised to reflect all 8 founder decisions.
- `docs/04-data-model.md` — synced: `completion_status`/`sync_status`/`report_status` split on `inspections`; `checklist_template_items.parent_item_id` self-referencing hierarchy; snapshot columns on `inspection_checklist_responses`; continuous-video model on `inspection_media` (`timestamp_markers`); new `equipment_transactions` table; `companies.region` field.
- `docs/07-inspection-workflow.md` — fully rewritten to describe the progressive Quick Appraisal / Detailed Inspection screen flow.
- `docs/08-security-compliance.md` — on-device encryption changed from "deferred" to "adopted from V1"; explicit Storage-level RLS policy SQL added; `equipment_transactions` access policy added.
- Documentation renumbered: `docs/00-ironsight-constitution.md` established as "Document Zero," all other documents shifted from `00`-`14` to `01`-`15` to make room, all cross-references updated across every file.

### Approved
- `docs/00-ironsight-constitution.md` approved as the company's guiding philosophy document.
- All 8 founder decisions from the approval review resolved (full detail: [`DECISIONS.md`](./DECISIONS.md) ADR-009 through ADR-016).

---

## 2026-07-23 (earlier — pre-dawn documentation sprint)

### Added
- `docs/00-ironsight-constitution.md` (first version) — company mission, vision, philosophy, and principles, including the Data Flywheel and "Build for the Company We Intend to Become" framing.
- `docs/14-final-product-specification.md` (first version, later renumbered to `15`) — consolidated single source of truth, resolving 10 contradictions found across the supporting documents.
- `docs/13-pre-development-review.md` (first version, later renumbered to `14`) — CTO-level review identifying conflicting requirements, missing V1 features, over-engineering risks, technical decisions to reconsider, and risks to future AI/valuation work.

---

## 2026-07-22

### Added
- Initial full documentation set created (first versions, later renumbered): executive summary, product requirements (PRD), technical architecture, data model, API design, mobile app specification, inspection workflow, security & compliance, multi-tenant SaaS strategy, tech stack decision record, non-functional requirements, equipment taxonomy, and the V1-V4 roadmap.
- Root `README.md` created as the documentation index and entry point.

### Decided
- Mobile framework: Flutter.
- Backend: Supabase (Postgres + Auth + Storage + Edge Functions), with a documented AWS migration path.
- Offline-first / local-first architecture as a hard V1 requirement.
- Team model: solo founder, AI-assisted development, no dedicated engineering team.
- Timeline: 8-12 week MVP.
- V1 scope: inspection platform only, no pricing/valuation/AI features.
- Multi-tenant SaaS architecture (Postgres Row Level Security) from day one.

Full detail: [`DECISIONS.md`](./DECISIONS.md) ADR-001 through ADR-007.
