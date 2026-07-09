# Session Handoff

## Current Objective

- Goal: Complete `feat-github-oauth-redirect-auth`.
- Current status: Feature implemented, accepted on iOS and Android, and
  evidence saved under `docs/harness/evidence/github-oauth-redirect-auth/`.
  Removed the GitHub Device Flow authorization path; browser redirect is now
  the only authorization method.
- Feature state: `feat-directory-git-sync`, `feat-ios-clean-ui`, and
  `feat-encrypted-token-default-directory` are `done`;
  `feat-github-directory-api-sync` is `done`;
  `feat-github-repository-download-sync` is `done`;
  `feat-github-oauth-redirect-auth` is `done`.

## Completed

- [x] Added a dedicated token settings route and Cupertino page.
- [x] Stored Git access tokens through platform secure storage.
- [x] Removed token input from the sync page and loaded the saved token during
  sync.
- [x] Created a default app documents `GitSync` directory on startup.
- [x] Removed the GitSync example notes directory option from the UI.
- [x] Kept the system directory picker for selecting a custom directory.
- [x] Updated real Git push authentication to avoid embedding tokens in remote
  URLs.
- [x] Updated and regenerated harness specs, UI target map, Maestro flows, and
  acceptance evidence.
- [x] Drafted and approved the `github-directory-api-sync` spec.
- [x] Added GitHub repository/directory URL parsing.
- [x] Added GitHub Contents API create/update sync for real `stg` and `prod`
  runs.
- [x] Kept dev on the deterministic fixture repository for Maestro stability.
- [x] Switched real sync DI away from `ProcessGitSyncRepository`, so mobile
  builds no longer need to launch a system `git` process.
- [x] Ran dual-platform Maestro dev acceptance and copied reports to
  `docs/harness/evidence/github-directory-api-sync/`.
- [x] Drafted and approved `github-repository-download-sync` after clarifying
  that the app should sync a GitHub remote repository down to the selected local
  phone directory, not upload local files to GitHub.
- [x] Changed real `stg` and `prod` GitHub sync to recursively read GitHub
  Contents API directory entries and write downloaded file bytes into the
  selected local directory.
- [x] Updated the directory sync UI copy and selected-directory display so the
  sync direction and target directory are clear.
- [x] Hid iOS Files provider and app documents sandbox paths in the
  selected-directory UI, while preserving the real path for sync writes.
- [x] Added GitHub Contents API datasource tests and repository regression tests
  for recursive download, empty remote directories, readable failures, and token
  redaction.
- [x] Ran dual-platform Maestro dev acceptance and copied reports to
  `docs/harness/evidence/github-repository-download-sync/`.
- [x] Drafted and approved `github-device-flow-auth`.
- [x] Replaced manual token entry with GitHub OAuth Device Flow: the settings
  page now requests a device code, displays `https://github.com/login/device`
  and the user code, polls until GitHub authorization succeeds, and stores the
  returned token through the existing secure storage repository.
- [x] Added a deterministic dev Device Flow fixture for Maestro acceptance and
  real `stg`/`prod` Device Flow wiring through `githubOAuthClientId`.
- [x] Updated all token setup Maestro flows to use Device Flow instead of
  typing `test-token`.
- [x] Ran dual-platform Maestro dev acceptance and copied reports to
  `docs/harness/evidence/github-device-flow-auth/`.
- [x] Registered `feat-github-oauth-redirect-auth` as a new harness feature.
- [x] Drafted the GitHub OAuth redirect auth spec, acceptance checklist, UI
  target delta, and deterministic dev Maestro flow drafts.
- [x] Added an active task plan under
  `docs/harness/tasks/active/2026-07-09-github-oauth-redirect-auth.md`.
- [x] Approved and implemented GitHub browser redirect authorization with PKCE,
  custom URL scheme callbacks, state validation, code exchange, and secure
  token save.
- [x] Added deterministic dev fixture behavior for OAuth redirect callback
  acceptance.
- [x] Added iOS/Android callback URL scheme registration and a GoRouter callback
  route for deep-link launches.
- [x] Kept Device Flow as a backup authorization path in the token settings UI.
- [x] Ran final dual-platform Maestro acceptance and copied reports to
  `docs/harness/evidence/github-oauth-redirect-auth/`.

## Verification Evidence

| Check | Command | Result | Notes |
|---|---|---|---|
| Full harness check | `fvm dart run tool/harness.dart check` | Pass | Format, structure, analyzer, and coverage passed; coverage 423/468 lines (90.38%). |
| New feature Gate A | `fvm dart run tool/harness.dart spec review encrypted-token-default-directory --approve` | Pass | Spec approved. |
| New feature acceptance | `fvm dart run tool/harness.dart spec accept encrypted-token-default-directory --maestro --platform all` | Pass | iOS and Android both PASS. |
| Directory sync regression | `fvm dart run tool/harness.dart spec accept directory-git-sync --maestro --platform all` | Pass | iOS and Android both PASS on the updated token/default-directory flow. |
| iOS clean UI regression | `fvm dart run tool/harness.dart spec accept ios-clean-ui --maestro --platform all` | Pass | iOS and Android both PASS on the updated token/default-directory flow. |
| GitHub API sync Gate A | `fvm dart run tool/harness.dart spec review github-directory-api-sync --approve` | Pass | Spec approved. |
| GitHub API sync unit tests | `fvm flutter test test/features/directory_git_sync/data/models/github_repository_target_test.dart && fvm flutter test test/features/directory_git_sync/data/repositories/github_api_git_sync_repository_test.dart && fvm flutter test test/core/injection/injection_test.dart` | Pass | Parser, Contents API repository, and DI behavior pass. |
| Full harness check | `fvm dart run tool/harness.dart check` | Pass | Format, structure, analyzer, and coverage passed; coverage 573/631 lines (90.81%). |
| GitHub API sync logic acceptance | `fvm dart run tool/harness.dart spec accept github-directory-api-sync` | Logic pass / command non-zero | Logic criteria pass; Maestro criterion is skipped without `--maestro`, so feature is not done. |
| GitHub API sync acceptance | `fvm dart run tool/harness.dart spec accept github-directory-api-sync --maestro --platform all` | Pass | iOS and Android both PASS; evidence copied to `docs/harness/evidence/github-directory-api-sync/`. |
| GitHub download sync Gate A | `fvm dart run tool/harness.dart spec review github-repository-download-sync --approve` | Pass | Spec approved. |
| GitHub download sync targeted tests | `fvm flutter test test/features/directory_git_sync/data/datasources/github_contents_api_test.dart test/features/directory_git_sync/data/repositories/github_api_git_sync_repository_test.dart test/features/directory_git_sync/data/repositories/fixture_git_sync_repository_test.dart test/core/injection/injection_test.dart` | Pass | Datasource, recursive download repository behavior, fixture message, and DI behavior pass. |
| Full harness check | `fvm dart run tool/harness.dart check` | Pass | Format, structure, analyzer, and coverage passed; coverage 589/647 lines (91.04%). |
| GitHub download sync acceptance | `fvm dart run tool/harness.dart spec accept github-repository-download-sync --maestro --platform all` | Pass | iOS and Android both PASS; evidence copied to `docs/harness/evidence/github-repository-download-sync/`. |
| Selected directory display regression | `fvm flutter test test/features/directory_git_sync/presentation/models/selected_directory_display_test.dart` | Pass | iOS Files provider paths now display as `我的 iPhone 中的文件夹` instead of raw container paths. |
| Static analysis | `fvm flutter analyze` | Pass | No analyzer issues after the display fix. |
| Structure guard | `fvm dart run tool/harness.dart structure` | Pass | Harness and architecture checks pass after adding the presentation model. |
| GitHub Device Flow Gate A | `fvm dart run tool/harness.dart spec review github-device-flow-auth --approve` | Pass | Spec approved. |
| GitHub Device Flow targeted tests | `fvm flutter test test/features/token_settings` | Pass | Device Flow API, repository, entity, and BLoC coverage pass. |
| Full harness check | `fvm dart run tool/harness.dart check` | Pass | Format, structure, analyzer, and coverage passed; coverage 741/809 lines (91.59%). |
| GitHub Device Flow acceptance | `fvm dart run tool/harness.dart spec accept github-device-flow-auth --maestro --platform all` | Pass | iOS and Android both PASS; evidence copied to `docs/harness/evidence/github-device-flow-auth/`. |
| GitHub OAuth redirect spec draft | `fvm dart run tool/harness.dart spec new github-oauth-redirect-auth` | Pass | Spec scaffold created and then filled for Gate A review. |
| GitHub OAuth redirect Gate A review | `fvm dart run tool/harness.dart spec review github-oauth-redirect-auth` | Pass | Printed the review checklist before approval. |
| Structure guard | `fvm dart run tool/harness.dart structure` | Pass | Harness and architecture checks pass with the draft feature/spec artifacts. |
| GitHub OAuth redirect Gate A approval | `fvm dart run tool/harness.dart spec review github-oauth-redirect-auth --approve` | Pass | Feature moved to `spec-approved` before implementation. |
| GitHub OAuth redirect targeted tests | `fvm flutter test test/features/token_settings/data/repositories/github_oauth_redirect_repository_test.dart test/features/token_settings/data/repositories/fixture_github_oauth_redirect_repository_test.dart test/features/token_settings/presentation/bloc/token_settings_bloc_test.dart test/features/token_settings/domain/token_settings_entities_test.dart test/core/router/app_router_test.dart` | Pass | OAuth repository, fixture, BLoC, entities, and callback route coverage pass. |
| GitHub OAuth redirect analyzer | `fvm dart analyze lib/features/token_settings lib/core/router test/features/token_settings test/core/router` | Pass | No issues found. |
| Full harness check | `fvm dart run tool/harness.dart check` | Pass | Format, structure, analyzer, and coverage passed; coverage 912/1007 lines (90.57%). |
| GitHub OAuth redirect acceptance | `fvm dart run tool/harness.dart spec accept github-oauth-redirect-auth --maestro --platform all` | Pass | iOS and Android both PASS; evidence copied to `docs/harness/evidence/github-oauth-redirect-auth/`. |

## Blockers / Risks

- No current blockers for `feat-github-oauth-redirect-auth`; it is `done`.
- Real `stg` and `prod` GitHub authorization requires a GitHub OAuth app with
  a callback URL matching the app flavor and `githubOAuthClientId` supplied
  through dart defines. Missing Client ID or redirect URI is surfaced as a
  readable in-app failure.
- Flutter reports future-compatibility warnings for Swift Package Manager
  support in some iOS plugins.
- Android builds report future-compatibility warnings for Gradle, Android
  Gradle Plugin, and Kotlin versions.
- GitHub Contents API file content responses may need additional handling for
  very large files or Git LFS pointers in a future feature.

## Next Session Startup

1. Read `AGENTS.md`.
2. Read `docs/harness/README.md` and relevant harness docs.
3. Read `feature_list.json` and `progress.md`.
4. Run `fvm dart run tool/harness.dart check` for a quick green baseline, or
   `./init.sh` when a fresh restartability proof is needed.

## Recommended Next Step

- Configure real `stg`/`prod` GitHub OAuth App values before live browser
  redirect authorization; run `./init.sh` when a fresh restartability proof is
  needed.
