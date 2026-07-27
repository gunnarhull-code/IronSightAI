## Sprint

- Sprint number:
- Immutable scope summary:
- Registry checklist:
  - [ ] Sprint number matches `management/sprint_registry.json` (`nextSprintNumber` / sprint record)
  - [ ] `dart run tool/verify_sprint_registry.dart` passes
  - [ ] Historical sprint numbers were not reused (including deferred Sprint 003)
  - [ ] Active parallel sprints were checked for overlapping files/scope
  - [ ] Registry reflects intended post-merge state (completed + PR evidence when merge commit unknown), so no immediate follow-up reconciliation PR is required
  - [ ] Founder merges; agents never merge to `main`

## Changes

- Files changed:
- Tests added or updated:

## Verification

- `dart run tool/verify_sprint_registry.dart` result:
- `flutter analyze` result:
- `flutter test` result:
- Manual verification status:
  - [ ] Performed
  - [ ] Not performed (explain why)

## Reviews

- Architecture review:
- UX review:

## Notes

- Assumptions:
- Follow-up recommendations:
- Migration summary:
  - [ ] No migrations in this PR
  - [ ] Migration(s) included — filenames:
- Production dry-run status (when migrations apply):
  - [ ] Not applicable
  - [ ] `npx.cmd supabase db push --dry-run` reviewed (result):
- Screenshots (only when meaningful):
- Videos: none (do not attach videos)
