# Legacy Sprint History

**Status:** Archived. Numbered sprints and `management/sprint_registry.json` are retired.

Canonical work tracking is now **Draft PRs** (frozen by the founder-approved Cloud Agent prompt). See [`docs/DEVELOPER_WORKFLOW.md`](../docs/DEVELOPER_WORKFLOW.md). (Historically, numbered sprints were first replaced by GitHub Issue Work Items; that Issue-backed model was later superseded by Draft-PR work records.)

This file preserves verified historical sprint identities so they are not reinvented or renumbered. Do not reuse these numbers as live Work Item IDs.

---

## Immutable historical notes

- **Sprint 003** remains deferred/archived; its number must never be reused as a sprint identity.
- **Sprint 008** is Inspection Local Foundation (merged through PR #9 lineage). Not an inspection list UI sprint.
- **Sprint 009** is Engineering Reliability, CI, and Developer Workflow Baseline (merged through PR #7). Never rename it “Inspection List Foundation.”
- **Sprint 010** is Node.js 24 / actions/checkout compatibility (merged through PR #12).
- Live PR/CI status always belonged to GitHub; this archive does not track open PRs.

---

## Former registry snapshot

Source: final `management/sprint_registry.json` before retirement (`schemaVersion` 1).  
`nextSprintNumber` at retirement was **13** (Sprint 012 was recorded as `active` for agent-rules reorganization WIP that was superseded by the Work Items workflow cleanup).

| # | Title | Status | PRs | Merge commit | Notes |
|---|---|---|---|---|---|
| 1 | Equipment V1 polish (search, sort, filter, save UX) | completed | #2 | `2af9d23820b0e388ad9902d1b3f357a53c681d31` | Verified via merged PR #2 |
| 2 | Equipment delete safeguards and audit details | completed | #3 | `9c46c1368f2daa659a577697cb40f9793f7aa339` | Verified via merged PR #3 |
| 3 | Deferred / archived (number reserved — do not reuse) | deferred | — | — | Historical deferred identity |
| 4 | Company V1 Polish | completed | #4 | `1773a4e52ab57526743998564efc501bb70f6322` | Verified via merged PR #4 |
| 5 | Company Country UX | completed | #11 | `3223246c354d07016c4c2c5a08c996ddd398e9d1` | Consolidation PR #11; original #5/#10 closed without merge |
| 6 | Form keyboard & browser UX | completed | #6 | `574163d0ba0b809739ead25a4cf579d0554f92b3` | Verified via merged PR #6 |
| 7 | PR Supabase migration check (informational CI) | completed | #8 | `55baa414269c1aaf51e5a19d5c113e1e2b873569` | Branch `cursor/sprint-007-pr-migration-check` |
| 8 | Inspection Local Foundation | completed | #9 | `2f9f654347ac864005feaf4058a2f518555f3c9a` | Local-first Drift persistence foundation |
| 9 | Engineering Reliability, CI, and Developer Workflow Baseline | completed | #7 | `ed759143c340afe2cc0eba833b3455ff1e256f38` | Never rename to Inspection List Foundation |
| 10 | Node.js 24 / actions/checkout compatibility | completed | #12 | `784d820324651c99e3a1621c3879c6aab584081b` | `actions/checkout@v6`, `persist-credentials: false` |
| 11 | Sprint Registry and Status-Consistency Guardrails | completed | #13 | — | PR number used as completion evidence; merge commit omitted when unknown at PR time |
| 12 | Agent rules reorganization (AGENTS + selective cursor rules) | active (at retirement) | — | — | Superseded by Work Items workflow cleanup; do not continue as a numbered sprint |

Additional early planning detail for the documentation-era Sprint 1 plan remains in [`management/sprints/SPRINT-1.md`](./sprints/SPRINT-1.md) (historical only).
