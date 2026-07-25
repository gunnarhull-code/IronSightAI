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

This is a **Flutter (Dart) mobile-first app** for equipment dealerships ("IronSight AI — WIW") with a **Supabase** backend (Postgres + Auth). It is a thin client that talks directly to Supabase via PostgREST/GoTrue; there is no custom server. The commands below are the standard Flutter/Supabase commands — see `README.md` and `pubspec.yaml` for product/tooling detail.

### Toolchain (pre-installed in the environment snapshot)
- Flutter SDK is installed at `~/flutter` and added to `PATH` via `~/.bashrc` (Flutter 3.44.8 / Dart 3.12.2, matching the revision pinned in `.metadata`). If `flutter` is not on `PATH` in a non-login shell, use `$HOME/flutter/bin/flutter`.
- Docker CE and the Supabase CLI are installed. The startup update script runs `flutter pub get`.

### Required services
The app **crashes on launch and tests fail** without these two things being ready:

1. **`.env` file** (git-ignored, must exist at repo root). If missing, create it from the template: `cp .env.example .env`. It points the app at the local Supabase instance. The default local Supabase keys are deterministic demo values (safe for local dev only).
2. **Local Supabase stack** (Postgres + Auth). Start it as follows — these are NOT run by the update script:
   - Docker daemon is not auto-started. Start it once per VM boot (in a background/tmux session): `sudo dockerd`.
   - Start Supabase from the repo root: `supabase start` (idempotent; applies `supabase/migrations/*.sql` on first start). API at `http://127.0.0.1:54321`, Studio at `http://127.0.0.1:54323`, DB at `:54322`.
   - Reset/reapply migrations: `supabase db reset`. Local auth has `enable_confirmations = false`, so email signup logs in immediately (no confirmation email needed).

### Lint / test / build / run
Run from the repo root:
- Lint / static analysis: `flutter analyze` (expects a clean tree; the only non-code warning is a missing `.env` asset if `.env` was not created).
- Tests: `flutter test` (56 widget/unit tests using in-repo fakes under `test/support/`; they do NOT need Supabase running, but DO need `.env` to exist because it is a declared asset).
- Run in dev mode (web, easiest for browser testing): `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`, then open `http://localhost:8080`. Chrome and a Linux desktop device are also available (`flutter run -d chrome` / `-d linux`).
- Builds: `flutter build web` / `flutter build apk` (Android SDK not installed by default).

### Notes / gotchas
- The Flutter web debug build can show a blank white screen for ~15–30s on first load while the debug service connects; give it time or refresh once.
- `supabase/config.toml` is committed so local dev is reproducible; `project_id = "workspace"`.
- Documentation may lag implementation. If documentation conflicts with working application code, inspect the code first and report the discrepancy rather than assuming the documentation is correct or automatically rewriting it.
