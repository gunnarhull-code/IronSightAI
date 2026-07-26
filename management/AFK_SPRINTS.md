# # Active AFK Sprint

This file contains the single approved sprint for Cursor Cloud Agents.

Rules:

- Agents may only work on the active sprint.

- Agents may not invent additional work.

- Agents must follow `AGENTS.md`.

- Agents stop after completing the active sprint.

- GitHub draft PRs represent work in progress.

- A merged PR means the sprint is complete.

- No separate sprint status field is required.

---

# Sprint 002 — Equipment V1 Polish

## Goal

Finish the remaining high-value Equipment polish without changing architecture.

## Tasks

- Add a delete confirmation dialog.

- Warn before leaving an equipment form with unsaved changes.

- Add Created By.

- Add Last Updated By.

- Add Last Updated timestamp.

## Acceptance Criteria

- Delete requires explicit confirmation.

- Canceling delete leaves the equipment unchanged.

- Leaving a modified form triggers an unsaved-changes warning.

- Choosing to stay preserves entered values.

- Audit fields display clearly where appropriate.

- Existing equipment workflows continue to work.

- `flutter analyze` passes.

- `flutter test` passes.

## Deliverables

Before reporting completion:

1. Run `flutter analyze`.

2. Run `flutter test`.

3. Launch the app and manually perform the requested workflow when the environment supports it.

4. If manual verification cannot be performed, explain why.

Return:

- Files changed

- Tests added or updated

- `flutter analyze` results

- `flutter test` results

- Manual verification performed / not performed

- Assumptions made

- Any migration created

- Follow-up recommendations directly related to this sprint

## Safety Rules

- Do not modify unrelated features.

- Do not refactor architecture.

- Do not invent additional backlog items.

- Use local Supabase by default.

- Never connect to production.

- Use hosted `agent-sandbox` only when explicitly required.

- Stop if requirements are ambiguous.

- Do not merge to `main`.