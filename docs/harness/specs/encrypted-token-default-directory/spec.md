# Spec: encrypted-token-default-directory

## Goal

Verify that GitSync stores the Git access token in a dedicated settings page,
uses the saved token during directory sync, starts with a default sync
directory, and still allows the user to choose a different local directory.

## Preconditions

- Run the `dev` flavor.
- The dev build exposes a deterministic fixture repository and branch after
  GitHub authorization.
- The dev build accepts `test-token` as a non-secret fixture credential and
  reports a successful push without using a real personal account.

## Steps

1. Launch the app.
2. Confirm the directory sync screen shows a selected default directory.
3. Open the token settings page.
4. Complete the fixture GitHub authorization.
5. Return to the directory sync screen.
6. Confirm the directory sync screen reports a configured token.
7. Select the fixture GitHub repository and branch.
8. Tap Sync.
9. Wait for the sync to finish.

## Acceptance Criteria

- The sync screen starts with a non-empty default directory.
- The sync screen does not expose a GitSync example notes directory option.
- A dedicated token settings screen saves the token without showing the token in
  clear text after saving.
- The sync screen reports that a token is configured after returning from
  settings.
- A successful completion state is visible after syncing with the saved token.
- Real sync keeps saved credentials out of user-visible repository targets.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
