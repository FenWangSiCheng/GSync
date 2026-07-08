# Spec: directory-git-sync

## Goal

Verify the MVP flow for syncing one user-selected local directory to one Git
remote from the app.

## Preconditions

- Run the `dev` flavor.
- The dev build exposes a deterministic test directory fixture named
  `GitSync Fixture Notes`.
- The dev build exposes a deterministic test remote named
  `https://example.invalid/gitsync-fixture.git`.
- The dev build accepts `test-token` as a non-secret fixture credential and
  reports a successful push without using a real personal account.

## Steps

1. Launch the app.
2. Open the directory sync screen.
3. Choose the local directory fixture.
4. Enter the remote Git repository URL.
5. Enter the authentication token.
6. Tap Sync.
7. Wait for the sync to finish.

## Acceptance Criteria

- The selected directory name or path is visible before syncing.
- The configured remote URL is visible before syncing.
- The Sync action starts an in-progress state.
- A successful completion state is visible after the app stages, commits, and
  pushes the selected directory.
- The sync logic does not create an empty commit when the selected directory has
  no changes.
- Authentication or transport failures are surfaced as a visible failed state.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
