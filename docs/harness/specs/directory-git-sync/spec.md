# Spec: directory-git-sync

## Goal

Verify the MVP flow for syncing one user-selected local directory to one Git
remote from the app.

## Preconditions

- Run the `dev` flavor.
- The dev build exposes a deterministic fixture repository and branch after
  GitHub authorization.
- The dev build accepts `test-token` as a non-secret fixture credential and
  reports a successful push without using a real personal account.

## Steps

1. Launch the app.
2. Open the directory sync screen.
3. Confirm the default local sync directory is selected.
4. Open token settings and save the authentication token.
5. Return to the directory sync screen.
6. Select the fixture GitHub repository.
7. Select the fixture branch.
8. Tap Sync.
9. Wait for the sync to finish.

## Acceptance Criteria

- The selected directory name or path is visible before syncing.
- The selected GitHub repository and branch are visible before syncing.
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
