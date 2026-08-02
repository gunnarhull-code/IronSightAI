# AFK / Cloud Agent policy

Permanent, stable rules for Cursor Cloud Agents and AFK runs. Do **not** record individual Work Item assignments here.

A **complete founder-approved Cloud Agent assignment** in the current prompt/context freezes Work Item identity and scope. It must include scope, exclusions, acceptance criteria, safety boundaries, and required verification. A descriptive slug or ordinary short task description must never substitute for that assignment. The resulting **Draft PR** is the unique live work record. Live PR and CI status belongs to GitHub. GitHub Issues are not required. This file must never require per-Work-Item updates.

## Rules

- Work only on **assigned Work Items** from a complete founder-approved assignment. Treat that assignment as the complete frozen source.
- An alternative task specification qualifies only when it is founder-approved and contains all required assignment sections. If the assignment is missing, incomplete, contradictory, or ambiguous, stop without creating a branch or modifying files.
- Use a descriptive branch: `cursor/<work-slug>` (slug names the branch/Draft PR only). Open **one separate Draft PR** per Work Item.
- Multiple Work Items may be active when scopes do not overlap.
- Do not invent additional work. Stop after completing the assigned Work Item.
- Follow `AGENTS.md` and [`docs/DEVELOPER_WORKFLOW.md`](../docs/DEVELOPER_WORKFLOW.md).
- Open **Draft** PRs only. Agents **never merge** and **never push** to `main`. Gunnar merges manually.
- Historical numbered sprints: [`LEGACY_SPRINT_HISTORY.md`](./LEGACY_SPRINT_HISTORY.md). Do not revive the sprint registry.
