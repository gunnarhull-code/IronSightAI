---
name: ironsight-draft-pr
description: >-
  Prepare and open an IronSight Draft PR targeting main with frozen Work Item
  scope and verification results. Use when the user asks for a Draft PR, pull
  request, or to ship a Work Item branch in IronSightAI.
---

# IronSight Draft PR

Canonical: `docs/DEVELOPER_WORKFLOW.md` → Draft PR preparation. Prefer Draft. Never merge. Never push to `main`. Gunnar merges manually.

The Draft PR is the unique live work record. A GitHub Issue is not required. Do not add `Closes #<number>` unless the founder explicitly requests an Issue link.

1. Feature branch from latest `origin/main`, named `cursor/<work-slug>`.
2. Keep the complete founder-approved assignment / Work Item scope immutable. A slug is never the assignment.
3. Run `ironsight-verify`; paste results into the PR body.
4. Fill `.github/PULL_REQUEST_TEMPLATE.md` (frozen scope, exclusions, acceptance criteria, files, tests, analyze/test, assumptions, migrations).
5. Screenshots only if meaningful for UI. Never create videos.
6. `git push -u origin HEAD` (feature branch only — never `main`).
7. Open one **Draft** PR targeting `main` for this Work Item (`gh pr create --draft --base main --head <branch>` or the environment’s Draft PR tool).
8. If `gh` is unauthenticated, stop and ask for `gh auth login` (or give the compare URL). Never print credentials.
