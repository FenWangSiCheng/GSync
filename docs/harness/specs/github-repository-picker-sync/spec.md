# Spec: github-repository-picker-sync

## Goal

Verify that GitSync lets an authorized user choose a GitHub repository and
branch before syncing, without typing a repository URL.

## Preconditions

- Run the `dev` flavor for UI acceptance.
- Dev authorization uses the deterministic GitHub Device Flow fixture.
- Dev repository loading uses deterministic repository and branch fixtures.
- Real `stg` and `prod` builds use the saved GitHub token to read repositories
  from GitHub REST API.

## Steps

1. Launch the app.
2. Complete GitHub authorization from the settings screen.
3. Return to the directory sync screen.
4. Wait for the repository list to appear.
5. Select a repository.
6. Select a branch.
7. Tap Sync.
8. Wait for the sync to finish.

## Acceptance Criteria

- The sync screen no longer requires a typed GitHub repository URL.
- Repositories visible to the authorized user are listed on the sync screen.
- Selecting a repository loads its branches.
- Selecting a branch updates the sync target.
- Sync uses the selected repository and branch to download GitHub contents into
  the selected local directory.
- Repository and branch loading failures are shown as readable failure text.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
