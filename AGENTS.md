# AGENTS.md

# AI SAFETY RULES

IronSight AI — WIW is a Flutter (Dart) mobile-first commercial SaaS app for equipment dealerships, with a Supabase backend (Postgres + Auth). Thin client via PostgREST/GoTrue; no custom server. Future AI and multi-company support are expected.

## Product and engineering standards

- Write production-quality code; no temporary hacks.
- Prefer simple, scalable solutions. Keep security in mind.
- Do not remove existing functionality without permission.
- Explain major decisions and impact before large changes; suggest alternatives when relevant.
- Comment only complex or non-obvious logic. Ask if requirements are unclear.

## Development Mode

- Default development environment is LOCAL SUPABASE.
- Never connect to the production Supabase project.
- Only connect to the hosted `agent-sandbox` project when the task explicitly requires hosted integration testing.

## Git Safety

- Never commit, push, or merge unless the user explicitly instructs you.
- Never create or update a pull request unless the user explicitly instructs you.
- When asked to open a PR: create a **Draft** PR targeting `main` on branch `cursor/<work-slug>`. Agents never merge to `main` and never push to `main`. Gunnar merges manually.
- Never modify GitHub settings or deployment workflows.

## Scope Control

- Complete only the requested task.
- When a Work Item is assigned, treat the **founder-approved Cloud Agent prompt** (or equivalent task description) as the complete frozen assignment. Do not use `management/AFK_AGENTS.md` for assignments. GitHub Issues are not required.
- Do not invent additional backlog items or features.
- Stop if requirements are ambiguous.
- Stop if architecture changes are required.
- Stop and ask before making major refactors or introducing new dependencies.

## Verification

Before reporting a task complete:

- Run `flutter analyze`.
- Run `flutter test`.
- Prefer `./scripts/verify.sh` or the commands in [`docs/DEVELOPER_WORKFLOW.md`](./docs/DEVELOPER_WORKFLOW.md).
- Report any failures honestly.
- Do not claim manual verification unless it was actually performed.
- Clearly list every file changed.

## Database Rules

If a task creates or modifies a Supabase migration:

- Clearly report the migration filename.
- State whether the migration was local Supabase or hosted `agent-sandbox`.
- Never silently modify database schema.
- Never apply migrations to production.
- Always remind the user to review and apply production migrations manually.

## Reporting

Every completed task must end with:

- Files changed
- Tests run
- Analyze results
- Migration name (if any)
- Whether any manual steps are still required
- Any assumptions made during implementation

## Setup and workflow

Procedures live in [`docs/DEVELOPER_WORKFLOW.md`](./docs/DEVELOPER_WORKFLOW.md) (source of truth), project skills under [`.cursor/skills/`](./.cursor/skills/), and slash commands under [`.cursor/commands/`](./.cursor/commands/). Do not invent alternate workflows.

| When | Use |
|---|---|
| Start / continue a Work Item | skill `ironsight-work-item` or command `start-work-item` |
| Verify / finish task / before Draft PR | skill `ironsight-verify` |
| Open Draft PR | skill `ironsight-draft-pr` |
| Migrations / production schema | skill `ironsight-migration-safety` |
| Detached PR QA | command `testpr` |
| Sync local `main` | command `sync-main` |
| Read-only status | command `project-status` |
| Launch local app (Brave / web-server) | command `run-local` |

Always-on reminders:

- Canonical work tracking: **Draft PRs** (one per Work Item). The founder-approved Cloud Agent prompt freezes scope; the Draft PR is the unique live work record. `management/AFK_AGENTS.md` is permanent policy, not an assignment board.
- Historical numbered sprints: [`management/LEGACY_SPRINT_HISTORY.md`](./management/LEGACY_SPRINT_HISTORY.md).
- Pre-Work-Item Status Gate is mandatory before starting a new assigned Work Item (see `ironsight-work-item` + DEVELOPER_WORKFLOW).
- Agents open Draft PRs; agents never merge or push to `main`; Gunnar merges manually; never push documentation commits directly to `main`.
- Cloud summary: Flutter at `~/flutter` (3.44.8); require `.env`; unit tests need `.env` not running Supabase; web-server `0.0.0.0:8080` may be blank 15–30s on first debug load.
