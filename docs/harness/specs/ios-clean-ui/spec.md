# Spec: ios-clean-ui

## Goal

Verify that the directory sync screen is restyled to a clean iOS aesthetic
(Cupertino large-title navigation, inset-grouped form sections, system colors,
and an action-sheet directory picker) and that all user-visible copy is
Simplified Chinese, without breaking the existing sync happy path.

## Preconditions

- Run the `dev` flavor.
- The dev default sync directory, fixture repository, branch, and credential
  from the `directory-git-sync` spec remain available.
- The app shell renders a `CupertinoApp` with a Simplified Chinese locale.

## Steps

1. Launch the app.
2. The directory sync screen is visible with a large-title navigation bar.
3. The default sync directory path is visible.
4. Open token settings and save the authentication token.
5. Return to the directory sync screen.
6. Select the fixture GitHub repository and branch.
7. The configured token status is visible.
8. Tap Sync.
9. Wait for the sync success state to appear.

## Acceptance Criteria

Mirrored as machine-checkable items in `acceptance.yaml`.

- The restyled screen is reachable and the default directory is selected.
- The selected directory is visible before syncing.
- The Sync action completes with a visible success state.
- All user-visible copy on the screen is Simplified Chinese.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
