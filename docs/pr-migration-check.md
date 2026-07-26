# PR Migration Check

When a pull request is opened, updated, or reopened, the **PR Migration Check** GitHub Actions workflow scans the PR for added or modified files under `supabase/migrations/**`.

## Where the warning appears

1. Open the pull request on GitHub.
2. Open the **Checks** tab (or the status checks listed near the merge box).
3. Select the **PR Migration Check** / **Supabase migration review** job.
4. Open the job’s **Summary** panel.

That summary is the workflow step summary (`GITHUB_STEP_SUMMARY`):

- If no migration files changed: `✅ No Supabase migrations detected.`
- If migration files changed: a prominent `🚨 SUPABASE MIGRATION REVIEW REQUIRED` notice, the changed migration filenames, and reminders that production was not modified and migrations must be reviewed and applied manually.

This check is informational only. It does not connect to Supabase, does not use database credentials, and does not apply migrations.
