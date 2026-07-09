# Spec: github-oauth-redirect-auth

## Goal

Verify that GitSync can authenticate GitHub access by opening the GitHub
authorization page in the browser, receiving the OAuth callback through the app,
exchanging the returned code with PKCE, and securely saving the access token.

## Preconditions

- Run the `dev` flavor for UI acceptance.
- The dev build uses a deterministic redirect-auth fixture. It builds a GitHub
  authorization URL, accepts a fixture callback URL, validates `state`, and
  saves a fixture token without requiring a real GitHub account.
- Real `stg` and `prod` builds require `githubOAuthClientId` and
  `githubOAuthRedirectUri` to be supplied through dart defines.
- The GitHub OAuth App callback URL must exactly match
  `githubOAuthRedirectUri`.
- The native apps must register the same callback scheme so the browser can
  return to GitSync.

## Steps

1. Launch the app.
2. Open the GitHub authorization settings page.
3. Start GitHub browser authorization.
4. Confirm the app opens or records the GitHub OAuth authorization URL.
5. Return to GitSync through the configured OAuth callback URL.
6. Confirm the app validates the callback, exchanges the code, and saves the
   token.
7. Return to the directory sync screen.
8. Confirm the sync screen reports that GitHub authorization is configured.

## Acceptance Criteria

- The settings page uses browser redirect authorization as the only supported
  authorization path.
- Starting authorization creates a GitHub OAuth authorize URL with
  `client_id`, `redirect_uri`, requested scope, CSRF `state`,
  `code_challenge`, and `code_challenge_method=S256`.
- The app opens the authorization URL outside the app or records the URL in the
  dev fixture path used by Maestro.
- The app handles the callback URL only when the returned `state` matches the
  pending authorization session.
- The app exchanges the authorization `code` with `client_id`,
  `redirect_uri`, and the original PKCE `code_verifier`; it does not require a
  client secret in the native app.
- On success, the returned access token is stored through the existing secure
  token repository and the sync screen reports authorization as configured.
- The dev fixture flow remains deterministic and does not contact GitHub.
- If a real build has no GitHub OAuth client ID or redirect URI configured, the
  settings page shows a readable failure state instead of spinning.
- If the callback includes `error` or an invalid `state`, the settings page
  shows a readable failure and does not save a token.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
