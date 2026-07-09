# Spec: github-device-flow-auth

## Goal

Verify that GitSync authenticates GitHub access through OAuth Device Flow
instead of asking the user to paste a personal access token.

## Preconditions

- Run the `dev` flavor for UI acceptance.
- The dev build uses a deterministic GitHub Device Flow fixture. It displays
  the fixture user code `ABCD-1234`, points the user to
  `https://github.com/login/device`, and saves the fixture token without
  requiring a real browser or GitHub account.
- Real `stg` and `prod` builds require `githubOAuthClientId` to be supplied
  through dart defines. The GitHub OAuth app must have Device Flow enabled.

## Steps

1. Launch the app.
2. Open the GitHub authorization settings page.
3. Start GitHub Device Flow authorization.
4. Confirm the page displays a user code and GitHub device verification URL.
5. Wait for the app to poll and save the authorized token.
6. Return to the directory sync screen.
7. Confirm the sync screen reports that GitHub authorization is configured.

## Acceptance Criteria

- The settings page no longer requires users to type or paste an access token.
- The app requests a GitHub device code with only a configured client ID and
  requested scope; it does not use a client secret or callback URL.
- The settings page displays the GitHub verification URL and user code while
  polling for authorization.
- Polling respects GitHub pending, slow-down, expired, denied, and success
  responses.
- On success, the returned access token is stored through the existing secure
  token repository and the sync screen reports authorization as configured.
- The dev fixture flow remains deterministic and does not contact GitHub.
- If a real build has no GitHub OAuth client ID configured, the settings page
  shows a readable failure state instead of spinning.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
