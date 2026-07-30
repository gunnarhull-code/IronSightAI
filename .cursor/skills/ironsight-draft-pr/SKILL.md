---
name: ironsight-draft-pr
description: >-
  Prepare and open an IronSight Draft PR targeting main with Work Item checklist
  and verification results. Use when the user asks for a Draft PR, pull request,
  or to ship a Work Item branch in IronSightAI.
---

# IronSight Draft PR

Canonical detail: `docs/DEVELOPER_WORKFLOW.md` → Draft PR preparation. Prefer Draft. Never merge. Never push to `main`.

## Steps

1. Feature branch from latest `origin/main` (not commits left only on local `main`).
2. Keep Work Item / Issue scope immutable — no unrelated work.
3. Run the `ironsight-verify` skill checks; paste results into the PR body.
4. Fill `.github/PULL_REQUEST_TEMPLATE.md` (GitHub Issue link, immutable scope, files, tests, analyze/test, manual verification, architecture/UX, assumptions, follow-ups, migrations, dry-run).
5. Screenshots only if they meaningfully show UI. Never create videos.
6. Push **only** the feature branch: `git push -u origin HEAD`.
7. Open Draft PR targeting `main` with `gh pr create --draft --base main --head <branch>`.
8. Reference the GitHub Issue in the PR body/title. Agents never merge.

If `gh` is not authenticated, stop and tell the user to run `gh auth login` (or open the GitHub compare URL). Do not extract or print credentials.
