# GitHub Repository Picker Sync

## Goal

After GitHub authorization, users can see their accessible GitHub repositories,
select a repository and branch, and sync without typing a repository URL.

## Acceptance Criteria

- The sync screen loads repositories from the saved GitHub authorization.
- The user can select a repository and one of its branches.
- The sync request is built from the selected repository and branch; no visible
  remote URL text field is required.
- Dev flavor uses deterministic repository and branch fixtures for Maestro.
- GitHub API repository and branch parsing is covered by Flutter tests.
- `fvm dart run tool/harness.dart check` passes before handoff.

## Progress

- [x] Create feature/spec/task artifacts.
- [x] Implement repository and branch catalog data flow.
- [x] Replace remote URL input with repository and branch selectors.
- [x] Update tests, Maestro flows, feature state, and progress logs.
- [x] Run validation.

## Decisions

- 2026-07-09: Keep the existing GitHub download repository as the sync engine.
  The picker builds a repository URL plus selected branch for the existing
  request path instead of adding a second sync pipeline.

## Validation

- PASS: `fvm dart run tool/harness.dart check` (format, structure, analyzer,
  coverage-gated tests; coverage 935/1027 lines = 91.04%).
- PASS: `fvm dart run tool/harness.dart spec accept
  github-repository-picker-sync --maestro --platform all` (iOS and Android).
