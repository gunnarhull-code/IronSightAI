# AFK / Cloud Agent policy

Permanent, stable rules for Cursor Cloud Agents and AFK runs. Do **not** record individual Work Item assignments here.

**GitHub Issues are the only source** for Work Item identity, assignment, frozen scope, and status. Live PR and CI status belongs to GitHub. This file must never require per-Work-Item updates.

## Rules

- Work only on **assigned Work Items** backed by a GitHub Issue. Read the Issue as the complete assignment source.
- Multiple Work Items may be active when Issue scopes do not overlap.
- Do not invent additional work. Stop after completing the assigned Work Item.
- Follow `AGENTS.md` and [`docs/DEVELOPER_WORKFLOW.md`](../docs/DEVELOPER_WORKFLOW.md).
- Open **Draft** PRs only. Agents **never merge** to `main`. The founder merges.
- Historical numbered sprints: [`LEGACY_SPRINT_HISTORY.md`](./LEGACY_SPRINT_HISTORY.md). Do not revive the sprint registry.
