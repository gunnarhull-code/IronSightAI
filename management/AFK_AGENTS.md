# AFK / Cloud Agent policy

Permanent, stable rules for Cursor Cloud Agents and AFK runs. Do **not** record individual Work Item assignments here.

The **founder-approved Cloud Agent prompt** freezes Work Item identity and scope. The resulting **Draft PR** is the unique live work record (scope, exclusions, acceptance criteria, verification, assumptions, migration status). Live PR and CI status belongs to GitHub. GitHub Issues are not required. This file must never require per-Work-Item updates.

## Rules

- Work only on **assigned Work Items** from a founder-approved prompt (or equivalent frozen task description). Treat that prompt as the complete assignment source.
- Use a descriptive branch: `cursor/<work-slug>`. Open **one separate Draft PR** per Work Item.
- Multiple Work Items may be active when scopes do not overlap.
- Do not invent additional work. Stop after completing the assigned Work Item.
- Follow `AGENTS.md` and [`docs/DEVELOPER_WORKFLOW.md`](../docs/DEVELOPER_WORKFLOW.md).
- Open **Draft** PRs only. Agents **never merge** and **never push** to `main`. Gunnar merges manually.
- Historical numbered sprints: [`LEGACY_SPRINT_HISTORY.md`](./LEGACY_SPRINT_HISTORY.md). Do not revive the sprint registry.
