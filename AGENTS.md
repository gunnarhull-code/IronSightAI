# AGENTS.md

# AI SAFETY RULES

## Development Mode

- Default development environment is LOCAL SUPABASE.
- Never connect to the production Supabase project.
- Only connect to the hosted `agent-sandbox` project when the task explicitly requires hosted integration testing.

## Git Safety

- Never commit.
- Never push.
- Never merge.
- Never create or update a pull request unless the user explicitly instructs you.
- Never modify GitHub settings.
- Never modify deployment workflows.

## Scope Control

- Complete only the requested task.
- Do not invent additional backlog items or features.
- Stop if requirements are ambiguous.
- Stop if architecture changes are required.
- Stop and ask before making major refactors or introducing new dependencies.

## Verification

Before reporting a task complete:

- Run `flutter analyze`.
- Run `flutter test`.
- Report any failures honestly.
- Do not claim manual verification unless it was actually performed.
- Clearly list every file changed.

## Database Rules

If a task creates or modifies a Supabase migration:

- Clearly report the migration filename.
- State whether the migration was:
  - Local Supabase
  - Hosted `agent-sandbox`
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

## Cursor Cloud specific instructions

This is a **Flutter (Dart) mobile-first app** for equipment dealerships ("IronSight AI — WIW") with a **Supabase** backend (Postgres + Auth). It is a thin client that talks directly to Supabase via PostgREST/GoTrue; there is no custom server.

**Local setup, verification commands, Windows/Brave launch, Draft PR prep, Pre-Sprint Status Gate, post-merge sync, and production migration safety are documented only in [`docs/DEVELOPER_WORKFLOW.md`](./docs/DEVELOPER_WORKFLOW.md).** Follow that document; do not invent alternate workflows.

### Pre-Sprint Status Gate (mandatory)

Before a new sprint is assigned:

- Local `main` must be clean and match `origin/main`.
- `management/sprint_registry.json` must validate (`dart run tool/verify_sprint_registry.dart`).
- The proposed number must equal `nextSprintNumber`.
- Deferred/blocked numbers cannot be reused (Sprint 003 remains deferred/archived forever).
- Existing active sprint scopes must be checked for overlap (multiple active sprints are allowed only with unique numbers and independent scopes).
- The registry must be updated in the new sprint’s Draft PR (prefer final post-merge registry state in that PR when practical).
- Contradictions or unverifiable history require stopping rather than guessing.

After every successful founder merge: switch to `main`, pull `origin/main`, check `git status`, and run the sprint-registry validator before assigning another sprint. If the merged PR already left the registry in final completed state, no immediate reconciliation PR is required. Never push documentation commits directly to `main`. Agents never merge to `main`.

Canonical sprint numbers/lifecycle: [`management/sprint_registry.json`](./management/sprint_registry.json). Live PR/CI status belongs to GitHub.

### Toolchain (pre-installed in the environment snapshot)

- Flutter SDK is installed at `~/flutter` and added to `PATH` via `~/.bashrc` (Flutter 3.44.8 / Dart 3.12.2, matching the revision pinned in `.metadata` and CI). If `flutter` is not on `PATH` in a non-login shell, use `$HOME/flutter/bin/flutter`.
- Docker CE and the Supabase CLI are installed. The startup update script runs `flutter pub get`.

### Required services (summary)

1. **`.env`** at repo root (git-ignored). Create with `cp .env.example .env` when missing.
2. **Local Supabase** when launching the app or doing backend manual QA: start Docker (`sudo dockerd` once per VM boot if needed), then `supabase start` from the repo root.

Unit/widget tests use in-repo fakes under `test/support/` and do **not** need Supabase running, but they **do** need `.env` because it is a declared asset.

### Lint / test / run (summary)

- Prefer `./scripts/verify.sh`, or the commands listed in `docs/DEVELOPER_WORKFLOW.md` (includes `dart run tool/verify_sprint_registry.dart`).
- Dev web: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`.

### Notes / gotchas

- The Flutter web debug build can show a blank white screen for ~15–30s on first load while the debug service connects; give it time or refresh once.
- `supabase/config.toml` is committed so local dev is reproducible; `project_id = "workspace"`.
- Documentation may lag implementation. If documentation conflicts with working application code, inspect the code first and report the discrepancy rather than assuming the documentation is correct or automatically rewriting it.
