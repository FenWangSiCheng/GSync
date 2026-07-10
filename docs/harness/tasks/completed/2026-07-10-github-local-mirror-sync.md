# GitHub Local Mirror Sync

## Goal

Make a successful GitHub sync leave the selected local directory exactly equal
to the selected remote repository path.

## Acceptance Criteria

- Remote files are downloaded and overwrite matching local paths.
- Local-only files, links, and directories are removed after the full remote
  tree is read successfully.
- Remote download failures leave local-only entries untouched.
- `fvm dart run tool/harness.dart check` passes.
- Dual-platform Maestro acceptance passes and reports are committed.

## Progress

- [x] Draft specification and acceptance checklist.
- [x] Approve specification (Gate A).
- [x] Implement remote-to-local mirror cleanup.
- [x] Add repository regression tests.
- [x] Run checks and dual-platform acceptance.
- [x] Record evidence and mark the feature done.

## Decisions

- 2026-07-10: Treat the selected local directory as a remote-owned mirror. No
  preview or recovery bin is added in this feature; cleanup starts only after
  all remote file bytes have been read successfully.

## Validation

- `fvm dart run tool/harness.dart check` — PASS; 1011/1103 lines (91.66%).
- `fvm dart run tool/harness.dart spec accept github-local-mirror-sync --maestro --platform all` — PASS on iOS and Android.
