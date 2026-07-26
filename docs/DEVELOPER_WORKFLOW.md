# Developer Workflow

**This is the source of truth for local setup, verification, Draft PR preparation, and production migration safety.**

Other files (`README.md`, `AGENTS.md`) may point here. Prefer updating this document over copying long instructions elsewhere.

---

## Toolchain

| Tool | Expected version | Where pinned |
|---|---|---|
| Flutter | `3.44.8` (stable) | `.metadata` revision `058e0af2c2…`; GitHub Actions CI |
| Dart | `3.12.2` (ships with that Flutter) | `pubspec.yaml` `environment.sdk: ^3.12.2` |
| Supabase CLI | current CLI used with committed `supabase/config.toml` | local install / `npx supabase` |

Install Flutter from the official stable channel and confirm:

```bash
flutter --version
```

---

## First-time local setup

1. Clone the repository and open the repo root.
2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Create local env configuration (required — `.env` is a declared Flutter asset):

   ```bash
   cp .env.example .env
   ```

   `.env.example` contains **deterministic local Supabase demo values only**. Never put production credentials in `.env` or commit `.env`.

4. Start local Supabase when you need a running backend (app launch / manual QA):

   - Ensure Docker is running.
   - From the repo root: `supabase start`
   - API: `http://127.0.0.1:54321`
   - Studio: `http://127.0.0.1:54323`
   - DB: `127.0.0.1:54322`
   - Reset/reapply local migrations: `supabase db reset` (**local only**)

Local auth has `enable_confirmations = false`, so email signup signs in immediately.

**Unit/widget tests do not require Supabase to be running.** They do require `.env` to exist because `pubspec.yaml` declares it as an asset.

---

## Standard verification (every Draft PR)

From the repo root:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Or run the lightweight helper (same checks):

```bash
./scripts/verify.sh
```

Expected outcomes:

- Formatting: no files need changes (command exits 0).
- Analyze: no issues (or only an explicitly understood missing-`.env` asset warning if `.env` was not created).
- Tests: all tests pass.

GitHub Actions runs these same checks on pull requests targeting `main`. CI creates `.env` from `.env.example` only — it never uses production secrets, never deploys, and never applies migrations.

---

## Windows development + Brave browser launch

On Windows, after checking out the branch you want to run:

```powershell
git checkout <branch-name>
git pull
flutter clean
flutter pub get
$env:CHROME_EXECUTABLE="C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe"
flutter run -d chrome
```

Notes:

- Flutter’s Chrome device uses `CHROME_EXECUTABLE` when set; pointing it at Brave launches Brave instead of Google Chrome.
- Adjust the Brave path if your install location differs.
- On macOS/Linux Cloud Agent environments, prefer `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080` or the available Chrome/Linux devices. Brave path above is Windows-specific.

---

## Draft PR preparation

1. Create a feature branch from latest `main`.
2. Keep the sprint scope immutable — do not expand into unrelated work.
3. Run the standard verification commands and paste results into the PR.
4. Use the repository pull-request template (requires sprint number, immutable scope, files changed, tests, analyze/test results, manual verification, architecture/UX review, assumptions, follow-ups, migration summary, production dry-run when applicable).
5. Attach screenshots only when they clarify UI behavior. Do not attach videos.
6. Open as a **Draft** PR targeting `main`. Do not merge your own sprint PR unless explicitly instructed.

---

## Post-merge synchronization

After a PR is merged, sync your local machine:

```bash
git checkout main
git pull origin main
git status
```

Expected result:

```text
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean
```

If your working tree is dirty, stash or discard local changes before continuing.

---

## Production migration safety gate

- Production migrations are **never automatic**.
- CI must not apply migrations and must not connect to production Supabase.
- Before applying any production schema change:

  1. Ensure the PR containing the migration is approved and manual testing is complete.
  2. Review the SQL under `supabase/migrations/`.
  3. Dry-run against the intended project:

     ```bash
     npx.cmd supabase db push --dry-run
     ```

     (On macOS/Linux shells the equivalent is typically `npx supabase db push --dry-run` after linking the correct project. Prefer the Windows `npx.cmd` form on Windows.)
  4. Apply only after dry-run review — never casually.
  5. **Never** run `supabase db reset` against production.

---

## Platform differences (keep these in mind)

| Topic | Local / Windows founder machine | Cloud Agent / Linux CI |
|---|---|---|
| Browser launch | Brave via `CHROME_EXECUTABLE` + `flutter run -d chrome` | `web-server`, Chrome, or Linux desktop as available |
| Supabase | Local Docker stack | Optional for manual QA; unit/widget tests use fakes |
| Secrets | Local `.env` (git-ignored) | CI copies `.env.example` only |
| Migrations | Review + dry-run before production | Never auto-applied |

---

## Related documents

- Product / architecture authority: `docs/00-ironsight-constitution.md`, `docs/15-final-product-specification.md`
- Day-to-day operational status: `management/DASHBOARD.md`
- Active AFK sprint rules: `management/AFK_SPRINTS.md`
- Agent safety rules: `AGENTS.md`
