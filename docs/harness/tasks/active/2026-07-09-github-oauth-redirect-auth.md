# GitHub OAuth Redirect Auth

## Goal

Add a new harness feature that supports GitHub browser-based OAuth redirect
authorization with PKCE and a native app callback URL.

## Acceptance Criteria

- `feature_list.json` tracks `feat-github-oauth-redirect-auth` as the active
  feature with scope, dependencies, evidence, and next step.
- `docs/harness/specs/github-oauth-redirect-auth/` contains a reviewable spec,
  UI target delta, and machine-checkable acceptance checklist.
- The implementation, once approved, opens GitHub authorization in a browser,
  handles the callback URL, validates `state`, exchanges code with PKCE, and
  saves the token through the existing secure token repository.
- Final done path runs
  `fvm dart run tool/harness.dart spec accept github-oauth-redirect-auth --maestro --platform all`.

## Progress

- [x] Created the harness spec scaffold.
- [x] Filled the reviewable spec, acceptance checklist, UI target delta, and
  Maestro flow drafts.
- [x] Run Gate A review and get approval.
- [x] Implement app code after Gate A approval.
- [x] Run targeted tests, harness checks, and dual-platform acceptance.

## Decisions

- 2026-07-09: Use OAuth Authorization Code with PKCE for native redirect auth
  so the Flutter app does not need a GitHub client secret.
- 2026-07-09: Use a custom URL scheme for the first implementation because it
  is locally testable in Maestro without hosting iOS AASA or Android
  assetlinks files. HTTPS universal/app links can be a later hardening feature.
- 2026-07-09: Keep the dev flavor deterministic by accepting a fixture callback
  and saving a fixture token without contacting GitHub.
- 2026-07-09: Removed the Device Flow authorization path entirely; browser
  redirect is now the only authorization method. Deleted the device flow API,
  repositories, use cases, entities, BLoC handling, settings UI section, tests,
  spec, evidence, and dedicated maestro flow, and migrated every other feature
  maestro flow to the OAuth redirect button plus fixture callback.
- 2026-07-09: Store the pending OAuth redirect session in the repository
  singleton so deep-link routing can rebuild the token settings page without
  losing the PKCE verifier/state.
- 2026-07-09: Add a router callback path and a fallback home navigation path so
  callback cold starts and route replacement behave consistently on Android.

## Validation

- PASS: `fvm dart run tool/harness.dart spec review github-oauth-redirect-auth`.
- PASS: `fvm dart run tool/harness.dart structure`.
- PASS: `fvm dart run tool/harness.dart spec review github-oauth-redirect-auth --approve`.
- PASS: `fvm flutter test test/features/token_settings/data/repositories/github_oauth_redirect_repository_test.dart test/features/token_settings/data/repositories/fixture_github_oauth_redirect_repository_test.dart test/features/token_settings/presentation/bloc/token_settings_bloc_test.dart test/features/token_settings/domain/token_settings_entities_test.dart test/core/router/app_router_test.dart`.
- PASS: `fvm dart analyze lib/features/token_settings lib/core/router test/features/token_settings test/core/router`.
- PASS: `fvm dart run tool/harness.dart check`.
- PASS: `fvm dart run tool/harness.dart spec accept github-oauth-redirect-auth --maestro --platform all`.
- Note: An initial parallel `spec review` run failed because two concurrent
  `fvm dart run` invocations raced while signing `.dart_tool` native assets.
  The same review command passed when rerun by itself.
