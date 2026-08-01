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

On Windows, run this helper through Git Bash or WSL. It is not a native PowerShell script. PowerShell users may run the standard verification commands directly.

Expected outcomes:

- Formatting: no files need changes (command exits 0).
- Analyze: no issues (or only an explicitly understood missing-`.env` asset warning if `.env` was not created).
- Tests: all tests pass.

GitHub Actions runs these same checks on pull requests targeting `main`. CI creates `.env` from `.env.example` only — it never uses production secrets, never deploys, and never applies migrations. The informational Supabase migration review workflow remains separate (see `.github/workflows/pr-migration-check.yml`).

**Live PR and CI status belongs to GitHub.** Repository docs may link to PRs/Actions but must not pretend to be a live unchecked task list for open PR merge state.

---

## Work Items (GitHub Issues)

Canonical work tracking is **GitHub Issues**. Each assignable unit of work is a Work Item backed by one Issue.

| Concept | Source of truth |
|---|---|
| Work Item identity / assignment / frozen scope / status | GitHub Issue (complete assignment source) |
| Live PR / CI state | GitHub Pull Requests and Actions |
| AFK / Cloud Agent permanent policy | [`management/AFK_AGENTS.md`](../management/AFK_AGENTS.md) (never per-Work-Item updates) |
| Historical numbered sprints | [`management/LEGACY_SPRINT_HISTORY.md`](../management/LEGACY_SPRINT_HISTORY.md) |

Rules:

- Do not invent Work Items or expand Issue scope without founder approval.
- Multiple Work Items may be active when scopes do not overlap.
- Draft PRs must reference the GitHub Issue they implement.
- Agents open **Draft** PRs and **never merge** to `main`. The founder merges.
- Numbered sprints and `management/sprint_registry.json` are retired. Do not recreate the registry.
- Do **not** update `management/AFK_AGENTS.md` for individual assignments.

---

## Pre-Work-Item Status Gate (mandatory before starting a new Work Item)

Before a new Work Item is started or assigned to an agent:

1. Local `main` must be clean (`git status` shows nothing to commit).
2. Local `main` must match `origin/main` (`git pull --ff-only origin main` / up to date).
3. A GitHub Issue must exist with clear, immutable scope — read the Issue as the complete assignment source.
4. Existing active Work Item scopes must be checked for file/scope overlap.
5. Land doc updates through a Draft PR; never push documentation commits directly to `main`.
6. If the Issue scope is ambiguous or contradictory, **stop** — do not guess.

Agents never merge to `main`. The founder performs every merge. Never update `management/AFK_AGENTS.md` per Work Item.

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

- On macOS/Linux Cloud Agent environments, **do not** set the Windows Brave `CHROME_EXECUTABLE` path. Prefer:

  ```bash
  flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
  ```

  Open the forwarded/local URL on port **8080**. The project Cursor command `/testpr` follows this Cloud path automatically.
- Flutter’s Chrome device uses `CHROME_EXECUTABLE` when set; pointing it at Brave launches Brave instead of Google Chrome.
- Adjust the Brave path if your install location differs.

---

## Draft PR preparation

1. Create a feature branch from latest `main`.
2. Keep the Work Item / Issue scope immutable — do not expand into unrelated work.
3. Run the standard verification commands and paste results into the PR.
4. Use the repository pull-request template (requires Issue/Work Item link, immutable scope, files changed, tests, analyze/test results, manual verification, architecture/UX review, assumptions, follow-ups, migration summary, production dry-run when applicable).
5. Attach screenshots only when they clarify UI behavior. Do not attach videos.
6. Open as a **Draft** PR targeting `main`. Agents never merge.

---

## Post-merge synchronization

After every successful merge (founder merges on GitHub), sync local `main` before assigning another Work Item:

```bash
git checkout main
git pull --ff-only origin main
git status
```

Expected `git status` result:

```text
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean
```

Never push documentation commits directly to `main`. Open a follow-up Draft PR only when docs still contradict verified history after merge.

If your working tree is dirty, stop and review git status. Preserve all work. Commit intended changes or use git stash when appropriate. Never discard changes unless you have deliberately confirmed they are unnecessary.

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
- Day-to-day founder operational summary: `management/DASHBOARD.md` (occasional; not live Work Item status)
- Permanent AFK / Cloud Agent policy: `management/AFK_AGENTS.md` (not an assignment board)
- Historical numbered sprints: `management/LEGACY_SPRINT_HISTORY.md`
- Agent safety rules: `AGENTS.md`
- Agent playbooks: `.cursor/skills/` — `ironsight-work-item`, `ironsight-draft-pr`, `ironsight-verify`, `ironsight-migration-safety`
- Agent slash commands: `.cursor/commands/` — `testpr`, `sync-main`, `project-status`, `start-work-item`, `run-local`

Prefer updating **this document** when procedures change, then keep matching `.cursor/skills/*/SKILL.md` and `.cursor/commands/*.md` in sync. Skills/commands must not invent alternate workflows.
