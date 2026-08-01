# IronSight AI — WIW ("What's It Worth")

A mobile-first, AI-ready heavy equipment inspection platform for equipment dealerships, used equipment managers, and sales representatives.

**Status:** Application foundation is in progress. This repository contains product documentation **and** a Flutter + local Supabase codebase on `main` (auth, company, equipment, local inspection foundation, engineering/CI baseline, and informational Supabase migration checks). Canonical work tracking is **GitHub Issues (Work Items)** — see [`docs/DEVELOPER_WORKFLOW.md`](./docs/DEVELOPER_WORKFLOW.md). Historical numbered sprints: [`management/LEGACY_SPRINT_HISTORY.md`](./management/LEGACY_SPRINT_HISTORY.md).

**Live MVP direction (Work Item #18):** **Quick Appraisal only** — under two minutes offline (timing and required capture set in [`docs/15`](./docs/15-final-product-specification.md) §0), trustworthy inspection package, no dollar valuation, no Detailed Inspection UI (Later; shared checklist model preserved). On-device OCR for serial/hours; optional cloud photo assist via backend `AIService`; walkaround video is evidence only. **V2:** professional PDF (server-side → local cache → reviewed native share). See §0 / §19.

## Developer setup and verification

**Source of truth:** [`docs/DEVELOPER_WORKFLOW.md`](./docs/DEVELOPER_WORKFLOW.md)

That document covers Flutter/Dart versions, `.env` setup, local Supabase, analyzer/tests, Windows + Brave launch, Draft PR preparation, post-merge sync, and the production migration safety gate. Do not duplicate those instructions here.

Quick start:

```bash
cp .env.example .env
flutter pub get
./scripts/verify.sh
```

Pull requests targeting `main` run the same format / analyze / test checks via GitHub Actions (see `.github/workflows/ci.yml`). CI never deploys, never uses production Supabase, and never applies migrations.

## Read in This Order

1. **[`docs/00-ironsight-constitution.md`](./docs/00-ironsight-constitution.md)** — **Document Zero.** The company's founding mission, vision, philosophy, and non-negotiable principles. Read this before anything else, and before making any product or architectural decision, human or AI. This is not a technical document — it is what every technical document answers to. **Approved as the guiding document for the project.**
2. **[`docs/15-final-product-specification.md`](./docs/15-final-product-specification.md)** — The single source of truth for the *product*. **§0 is the live MVP scope** (Work Item #18 + founder confirmations). Older sections remain historical/engineering reference where they conflict with §0. §19 records resolved confirmations.
3. **[`docs/16-founder-approval-checklist.md`](./docs/16-founder-approval-checklist.md)** — Historical record of the first 8 founder decisions.
4. **[`docs/18-implementation-ready-report.md`](./docs/18-implementation-ready-report.md)** — Documentation-phase status, including the #18 MVP alignment and founder confirmations.
5. **[`docs/DEVELOPER_WORKFLOW.md`](./docs/DEVELOPER_WORKFLOW.md)** — Local engineering setup, verification, and PR workflow baseline.

Docs `01`–`14` remain as detailed supporting reference (rationale, full SQL, diagrams) but defer to `15` wherever they conflict, and everything defers to `00` on questions of philosophy, priority, or principle. `docs/04`, `07`, and `08` were fully synced with the pre-#18 `docs/15`; see `docs/18` §5 for consistency status after #18.

## Daily Development Workflow

The [`management/`](./management/) folder preserves company context independently of any one person's memory. **GitHub Issues, Pull Requests, and Actions** are the live sources for Work Item, PR, and CI status. `management/DASHBOARD.md` is a founder-maintained occasional summary — agents must not routinely edit it for individual Work Items.

At the start of a development session, read as needed:

1. [`management/DASHBOARD.md`](./management/DASHBOARD.md) (occasional summary)
2. [`docs/00-ironsight-constitution.md`](./docs/00-ironsight-constitution.md)
3. [`docs/15-final-product-specification.md`](./docs/15-final-product-specification.md) (**§0 first**)
4. [`docs/13-roadmap.md`](./docs/13-roadmap.md)
5. [`management/DECISIONS.md`](./management/DECISIONS.md)
6. [`docs/DEVELOPER_WORKFLOW.md`](./docs/DEVELOPER_WORKFLOW.md) when changing setup, CI, or verification steps
7. The assigned **GitHub Issue** (complete Work Item source when one is assigned)
8. Begin implementation.

**Operating principle**: management docs are maintained for the life of the company. The founder occasionally updates `DASHBOARD.md` and related summaries when phase or priorities change. Agents do **not** update shared status files at the end of every session. Record decisions in `DECISIONS.md` and changelog entries only when the founder (or an explicit Work Item) requires it — never as routine per-Work-Item status sync. Live work state stays on GitHub.

## Documentation Philosophy: `docs/` vs `management/`

There must never be duplicate sources of truth. Each of the following lives in exactly one place:

- **`docs/`** — long-lived documentation: the Constitution, technical architecture, the product specification, the **strategic roadmap** (`docs/13-roadmap.md`), and the **developer workflow** (`docs/DEVELOPER_WORKFLOW.md`).
- **`management/`** — living operational documents that change throughout development: the Dashboard, Decisions, Changelog, Backlog, Founder Log, Wins, permanent AFK/Cloud Agent policy, and legacy sprint history.

The strategic roadmap exists **only** in `docs/13-roadmap.md`. Local setup/verification exists **only** in `docs/DEVELOPER_WORKFLOW.md`. Active work tracking exists **only** as GitHub Issues (Work Items). Live PR/CI state belongs to GitHub. Other files reference these sources; they should not restate them at length.

## Management Folder

| File | Purpose |
|---|---|
| [`management/DASHBOARD.md`](./management/DASHBOARD.md) | Founder-maintained occasional operational summary (not a live Work Item board) |
| [`management/DECISIONS.md`](./management/DECISIONS.md) | Permanent architectural decision log (ADRs) |
| [`management/CHANGELOG.md`](./management/CHANGELOG.md) | Chronological project history |
| [`management/BACKLOG.md`](./management/BACKLOG.md) | Ideas intentionally deferred from the MVP, by priority |
| [`management/FOUNDER_LOG.md`](./management/FOUNDER_LOG.md) | Founder journal — customer conversations, ideas, lessons learned |
| [`management/WINS.md`](./management/WINS.md) | Milestone journal |
| [`management/AFK_AGENTS.md`](./management/AFK_AGENTS.md) | Permanent AFK/Cloud Agent policy (GitHub Issues are the only assignment source) |
| [`management/LEGACY_SPRINT_HISTORY.md`](./management/LEGACY_SPRINT_HISTORY.md) | Archived numbered-sprint history (sprint registry retired) |

## Key Decisions (Locked for MVP)

- **Core promise**: Quick Appraisal in **under two minutes** offline (Start → confirm; excludes login/onboarding/sync/share) — trustworthy package, not a dollar valuation.
- **MVP = Quick Appraisal only**: required photos (front-left, rear-right, serial plate, hour meter), walkaround evidence video (not AI-analyzed), type/make/model, serial or “not found”, hours or “unknown”, Quick Condition ratings; optional year/notes/extra photos. Detailed Inspection UI is **Later** (shared checklist model preserved).
- **Plumbing**: minimal company setup/context, company-scoped inspection list, reopen mutable draft, discard draft with confirmation.
- **AI**: on-device OCR for serial/hours; optional cloud photo assist via backend provider-agnostic `AIService` when connected; Flutter/domain never call a vendor directly; humans confirm; manual path always available; vendor selection is a later benchmark Work Item.
- **V2**: professional PDF (server-side → local cache → reviewed native email/share draft). Summary-image renderer is Later.
- **Later**: Detailed Inspection, summary image, portal, collaboration/chat, manager approval, automated email, historical equipment info, recon costs, pricing/valuation, AI vendor benchmarks.
- **Mobile app**: Flutter — single codebase, strong camera/video/OCR capability, works fully offline.
- **Backend**: Supabase (Postgres + Auth + Storage + Edge Functions).
- **Offline strategy**: Local-first; completing the MVP inspection package must not require a network connection.
- **Team model**: One founder/product owner, AI-assisted development, no dedicated engineering team.
- **Multi-tenant from day one** via company-scoped data + Postgres Row Level Security.
- **MVP is an inspection package platform, not a valuation platform.**

## Documentation Index

| # | Document | Covers |
|---|---|---|
| 00 | [`docs/00-ironsight-constitution.md`](./docs/00-ironsight-constitution.md) | **Read first.** Company mission, vision, philosophy, and non-negotiable principles |
| 01 | [`docs/01-executive-summary.md`](./docs/01-executive-summary.md) | Product vision, problem/solution, guiding principles, roadmap at a glance |
| 02 | [`docs/02-product-requirements.md`](./docs/02-product-requirements.md) | V1 PRD — personas, functional requirements, scope boundaries, success metrics |
| 03 | [`docs/03-technical-architecture.md`](./docs/03-technical-architecture.md) | System architecture, offline-first sync design, AI-ready data pipeline |
| 04 | [`docs/04-data-model.md`](./docs/04-data-model.md) | Postgres schema, ER diagram, multi-tenant design — **synced with pre-#18 `15`** |
| 05 | [`docs/05-api-design.md`](./docs/05-api-design.md) | Client/backend contract (Supabase tables + Edge Functions) |
| 06 | [`docs/06-mobile-app-spec.md`](./docs/06-mobile-app-spec.md) | Flutter app structure, camera/video/OCR modules, sync engine |
| 07 | [`docs/07-inspection-workflow.md`](./docs/07-inspection-workflow.md) | Screen-by-screen guided inspection UX — **rewritten to match pre-#18 `15` §5** |
| 08 | [`docs/08-security-compliance.md`](./docs/08-security-compliance.md) | Auth, RLS tenant isolation, encryption, data ownership — **synced with `15`** |
| 09 | [`docs/09-multi-tenant-saas-strategy.md`](./docs/09-multi-tenant-saas-strategy.md) | Tenancy model, roles, billing-readiness |
| 10 | [`docs/10-tech-stack.md`](./docs/10-tech-stack.md) | Concrete stack decisions + justification + migration triggers |
| 11 | [`docs/11-non-functional-requirements.md`](./docs/11-non-functional-requirements.md) | Performance, reliability, cost, device support targets |
| 12 | [`docs/12-equipment-taxonomy.md`](./docs/12-equipment-taxonomy.md) | Make/model/category data model, extensibility rules |
| 13 | [`docs/13-roadmap.md`](./docs/13-roadmap.md) | Live MVP / V2 / Later sequencing + historical week plan |
| 14 | [`docs/14-pre-development-review.md`](./docs/14-pre-development-review.md) | CTO pre-development review — conflicts, gaps, risks, and required fixes before Week 1 |
| 15 | [`docs/15-final-product-specification.md`](./docs/15-final-product-specification.md) | **Single source of truth.** **§0 = live MVP scope** |
| 16 | [`docs/16-founder-approval-checklist.md`](./docs/16-founder-approval-checklist.md) | Historical founder decisions; #18 confirmations recorded in `docs/15` §19 |
| 17 | [`docs/17-dealership-data-use-clause-draft.md`](./docs/17-dealership-data-use-clause-draft.md) | Draft dealership data-use consent language for future AI training — **not legal advice**, requires attorney review |
| 18 | [`docs/18-implementation-ready-report.md`](./docs/18-implementation-ready-report.md) | Documentation-phase status including #18 amendment |
| — | [`docs/DEVELOPER_WORKFLOW.md`](./docs/DEVELOPER_WORKFLOW.md) | **Engineering workflow source of truth** — local setup, verification, Draft PRs, migration safety |

> **Numbering note**: `docs/00-ironsight-constitution.md` is "Document Zero" — the company's foundational document, read before the numbered product/technical sequence begins. Documents `01`–`18` are numbered sequentially in intended reading order. If a new document is added later, it should be appended at the end of the sequence rather than inserted mid-sequence, to avoid another renumbering pass. Unnumbered operational engineering docs (such as `DEVELOPER_WORKFLOW.md`) may sit alongside without renumbering the product set.

## Non-Goals for MVP (Read Before Proposing Features)

No Detailed Inspection UI; no pricing/valuation dollar output; no company/manager portal; no live collaboration/chat; no manager approval workflow; no automated email workflows; no historical equipment information product; no recon costs/additions; no customer-facing portal; no billing/payments; no web inspection experience; no DMS/CRM integration; no true push notifications; no walkaround video AI analysis; no hardcoded cloud AI vendor. **V2** owns professional PDF + reviewed native share. Summary-image renderer is Later. On-device OCR and optional cloud photo assist **are** allowed in MVP under `docs/15` §0. See [`docs/15-final-product-specification.md`](./docs/15-final-product-specification.md) §0 and §4 for the authoritative lists.

## Next Step

Continue implementation from assigned Work Items on **GitHub Issues**. Use [`docs/DEVELOPER_WORKFLOW.md`](./docs/DEVELOPER_WORKFLOW.md) for setup and verification. Product scope remains governed by [`docs/15-final-product-specification.md`](./docs/15-final-product-specification.md) **§0**. Do not expand frozen Draft PR scopes (#14, #15) from this documentation Work Item.
