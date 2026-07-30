---
name: ironsight-draft-pr
description: >-
  Prepare and open an IronSight Draft PR targeting main with Work Item checklist
  and verification results. Use when the user asks for a Draft PR, pull request,
  or to ship a Work Item branch in IronSightAI.
---

# IronSight Draft PR

Canonical: `docs/DEVELOPER_WORKFLOW.md` → Draft PR preparation. Prefer Draft. Never merge. Never push to `main`.

1. Feature branch from latest `origin/main`.
2. Keep Issue / Work Item scope immutable.
3. Run `ironsight-verify`; paste results into the PR body.
4. Fill `.github/PULL_REQUEST_TEMPLATE.md` (Issue link, scope, files, tests, analyze/test, migrations).
5. Screenshots only if meaningful for UI. Never create videos.
6. `git push -u origin HEAD` (feature branch only).
7. `gh pr create --draft --base main --head <branch>`; reference the Issue.
8. If `gh` is unauthenticated, stop and ask for `gh auth login` (or give the compare URL). Never print credentials.
