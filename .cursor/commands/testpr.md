---
description: Detached PR test against origin/main — format, analyze, test, migration detect, Brave/web launch. Never modify or merge.
---

# testpr

Argument: GitHub PR number (`$ARGUMENTS`).

Follow `AGENTS.md` and `docs/DEVELOPER_WORKFLOW.md`. Read-only toward git history beyond detached checkout.

1. Confirm repo root is this IronSightAI project.
2. If the working tree is dirty, **stop** and report status. Do not stash, discard, reset, commit, push, or merge.
3. `git fetch origin` and `git fetch origin pull/<PR>/head`.
4. Enter **detached** HEAD on that PR tip (e.g. `git checkout --detach FETCH_HEAD` after fetching the PR head). Do not create/switch a local branch for edits.
5. Diff against `origin/main`:
   - List changed files
   - Detect `supabase/migrations/**` changes — **report only; never apply** migrations
6. Run:
   - `dart format --output=none --set-exit-if-changed .`
   - `flutter analyze`
   - `flutter test`
7. Launch for manual QA (never production):
   - Windows: set `CHROME_EXECUTABLE` to Brave, then `flutter run -d chrome`
   - Cloud/Linux: `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`
8. Return a **PR-specific manual checklist** (auth/company/equipment/inspection paths touched by the diff, migration review if any, CI status via `gh` if available).
9. Never modify tracked files, commit, push, or merge. Leave the user on detached HEAD and report how to return (`git switch <branch>`).
