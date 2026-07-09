# Session Progress Log

## Current State

**Last Updated:** 2026-07-09 CST
**Active Feature:** `feat-github-device-flow-auth`
**Current Activity:** Implemented and accepted GitHub OAuth Device Flow
authorization so users no longer paste personal access tokens. Dual-platform
Maestro acceptance passes and evidence is committed under
`docs/harness/evidence/github-device-flow-auth/`.

## Status

### What's Done

- [x] Completed `feat-directory-git-sync` and refreshed dual-platform
  acceptance evidence after the token/default-directory workflow change.
- [x] Completed `feat-ios-clean-ui` and refreshed dual-platform acceptance
  evidence on the updated workflow.
- [x] Drafted, approved, implemented, and accepted
  `feat-encrypted-token-default-directory`.
- [x] Added `flutter_secure_storage` for platform secure token storage and
  `path_provider` for resolving the app documents directory.
- [x] Added a dedicated Cupertino token settings page for saving and deleting
  the Git access token.
- [x] Changed directory sync to load the saved token from secure storage instead
  of taking token input on the sync page.
- [x] Changed directory sync startup to create and select a default `GitSync`
  app documents directory.
- [x] Removed the GitSync example notes directory UI path; users can still use
  the system directory picker to choose a different directory.
- [x] Updated real Git sync so HTTP credentials are passed through temporary
  `GIT_ASKPASS` environment state during push rather than embedded in the saved
  remote URL.
- [x] Updated specs, UI target map, Maestro flows, feature state, and committed
  evidence paths.
- [x] Added the missing `cupertino_icons` dependency required by the existing
  `CupertinoIcons` usages in the iOS-style UI.
- [x] Enabled stable paste/context-menu behavior on the token and remote URL
  Cupertino text fields.
- [x] Added timeout and exception handling around real Git commands so `stg` and
  `prod` runs do not leave the sync UI spinning indefinitely when system Git is
  unavailable or a command hangs.
- [x] Drafted and approved `github-directory-api-sync` as a new harness spec.
- [x] Added `http` and Android network permission for GitHub REST API calls.
- [x] Added GitHub repository target parsing for `https://github.com/owner/repo`
  and `https://github.com/owner/repo/tree/main/path` URLs.
- [x] Added a GitHub Contents API data source and repository that scans local
  files, fetches existing SHA values, and creates or updates files through the
  GitHub API.
- [x] Changed dependency injection so dev still uses the deterministic fixture,
  while real `stg` and `prod` sync use the GitHub API repository instead of
  launching a system `git` process.
- [x] Updated the sync page placeholder to request a GitHub repository or
  directory URL.
- [x] Ran dual-platform Maestro acceptance for `github-directory-api-sync` on
  dev and copied the reports into `docs/harness/evidence/github-directory-api-sync/`.
- [x] Drafted and approved `github-repository-download-sync` as a new harness
  feature after clarifying that the product goal is remote GitHub repository to
  local device directory sync.
- [x] Changed the real GitHub API sync repository to recursively read GitHub
  Contents API directory entries and write downloaded file bytes into the
  selected local directory while preserving nested relative paths.
- [x] Removed the unused real-sync upload path from `GitHubContentsApi`.
- [x] Updated the directory sync screen copy so the direction is explicitly
  GitHub remote to local directory.
- [x] Updated the selected directory display to show the directory name plus
  wrapped path context instead of one truncated absolute path.
- [x] Hid iOS Files provider and app documents sandbox paths behind
  user-facing selected-directory details such as `我的 iPhone 中的文件夹` and
  `应用默认同步目录`.
- [x] Updated the dev fixture success message to match the remote-download
  product semantics.
- [x] Added datasource and repository regression coverage for directory listing,
  base64 file decoding, recursive download, empty remote directories, readable
  failures, and token redaction.
- [x] Ran dual-platform Maestro acceptance for
  `github-repository-download-sync` and saved the reports under
  `docs/harness/evidence/github-repository-download-sync/`.

- [x] Fixed iOS file visibility for `feat-github-repository-download-sync`: added `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` to `ios/Runner/Info.plist` so downloaded files appear under the app in the iOS Files app. Rebuilt and reinstalled the stg build on the iOS simulator; verified 84 downloaded files remain in the Documents/GitSync container and both keys are present in the built Runner.app Info.plist.
- [x] Drafted, approved, implemented, and accepted
  `feat-github-device-flow-auth`.
- [x] Added GitHub OAuth Device Flow API support for requesting a device code
  and polling `authorization_pending`, `slow_down`, `expired_token`,
  `access_denied`, and success responses.
- [x] Added a dev-only deterministic Device Flow fixture that displays
  `ABCD-1234`, points to `https://github.com/login/device`, and saves
  `test-token` without contacting GitHub.
- [x] Replaced the token settings page's manual token input with a GitHub
  Device Flow authorization action and visible device code / verification URL.
- [x] Updated directory sync copy to describe GitHub authorization instead of
  manual access-token setup.
- [x] Added `githubOAuthClientId` and `githubOAuthScope` app config fields;
  real `stg` and `prod` builds require `githubOAuthClientId` through dart
  defines, while dev remains fixture-backed.
- [x] Updated all Maestro token setup steps to use the Device Flow fixture and
  refreshed the generated UI target map.
- [x] Saved dual-platform acceptance reports for `github-device-flow-auth`.
### What's Next

1. No outstanding implementation or acceptance work for
   `feat-github-device-flow-auth`.
2. Future work can add delete-mirroring, conflict handling, large file support,
   background sync, account switching, or OAuth client setup guidance as
   separate features.

## Blockers / Risks

- [ ] No blockers for `feat-encrypted-token-default-directory`; it is `done`.
- [ ] Flutter warns that some iOS plugins do not support Swift Package Manager.
  This is not blocking current validation but may become an issue in a future
  Flutter release.
- [ ] Android build warns that the Gradle, Android Gradle Plugin, and Kotlin
  versions will need upgrades before future Flutter versions drop support.
- [ ] GitHub Contents API file content responses may need additional handling
  for very large files or Git LFS pointers in a future feature.
- [ ] Real `stg` and `prod` GitHub authorization requires a GitHub OAuth app
  with Device Flow enabled and `githubOAuthClientId` supplied through dart
  defines. Missing client ID is handled as a readable in-app failure.

## Decisions Made

- **Use platform secure storage:** Git tokens are stored through
  `flutter_secure_storage`, keeping key management with the OS instead of app
  code.
- **Keep one saved Git token:** Multi-account and per-repository credentials are
  out of scope for this feature.
- **Default to an app documents directory:** On startup, GitSync creates and
  selects a `GitSync` directory under the app documents directory.
- **Avoid token-in-remote URLs:** HTTP push authentication uses a temporary
  askpass script and environment variables so `.git/config` keeps the clean
  remote URL.
- **Keep UI behavior in Maestro:** Token settings navigation and the saved-token
  sync path are covered by iOS and Android Maestro flows.
- **Use GitHub Contents API for mobile sync:** Mobile apps should not start a
  system `git` process. The active real sync path now uses GitHub REST API
  directory and file reads to download the user-specified repository or
  directory URL into the selected local device directory.
- **Correct sync direction:** The product goal is remote GitHub repository to
  local phone directory sync. Uploading local files to GitHub is out of scope
  for `feat-github-repository-download-sync`.
- **Keep dev deterministic:** The dev flavor remains on
  `FixtureGitSyncRepository` so Maestro acceptance does not require a live
  GitHub account or token.
- **Use GitHub Device Flow for auth:** Token setup now uses GitHub OAuth
  Device Flow: the app requests a device code with a configured client ID,
  displays `github.com/login/device` plus the user code, polls GitHub, and
  stores the returned token through the existing secure token repository. No
  `client_secret`, callback scheme, or deep link is used.
- **Keep Device Flow fixture-backed in dev:** Dev acceptance uses
  `FixtureGitHubDeviceFlowRepository` so UI flows never require a real browser
  session or GitHub account.

## Files Modified This Session

- `feature_list.json`, `progress.md`, and `session-handoff.md` - Updated
  feature state, evidence, and restart notes.
- `pubspec.yaml` and `pubspec.lock` - Added `flutter_secure_storage` and
  `path_provider`.
- `lib/core/router/` and `lib/core/injection/` - Added token settings route and
  dependency registrations.
- `lib/features/directory_git_sync/` - Added default directory resolution,
  saved-token sync behavior, clean remote URL push handling, and removed the
  example notes UI path.
- `lib/features/token_settings/` - Added secure token storage, use cases, BLoC,
  and settings page.
- `test/features/directory_git_sync/`, `test/features/token_settings/`, and
  `test/core/` - Added and updated unit tests for the new behavior.
- `docs/harness/specs/` and `.maestro/` - Added the new spec and refreshed all
  affected Maestro flows.
- `docs/harness/evidence/` - Refreshed acceptance reports for all three specs.
- `pubspec.yaml` and `pubspec.lock` - Added `cupertino_icons` so Cupertino icon
  glyphs are bundled instead of rendering as question marks.
- `lib/features/directory_git_sync/presentation/pages/directory_sync_page.dart`
  and `lib/features/token_settings/presentation/pages/token_settings_page.dart`
  - Enabled explicit Cupertino text field selection/context menus for paste.
- `lib/features/directory_git_sync/data/repositories/process_git_sync_repository.dart`
  and its test - Added real Git command timeout/exception failure handling.
- `docs/harness/specs/github-directory-api-sync/` and `.maestro/` - Added the
  new GitHub API sync spec, acceptance checklist, and dev fixture flows.
- `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`, and
  `pubspec.lock` - Added network permission and `http`.
- `lib/features/directory_git_sync/data/models/github_repository_target.dart` -
  Added GitHub target parsing.
- `lib/features/directory_git_sync/data/datasources/github_contents_api.dart`
  and `lib/features/directory_git_sync/data/repositories/github_api_git_sync_repository.dart`
  - Added GitHub Contents API sync.
- `lib/core/injection/` and `test/core/injection/injection_test.dart` - Wired
  real sync to the GitHub API repository outside dev fixtures.
- `test/features/directory_git_sync/data/models/` and
  `test/features/directory_git_sync/data/repositories/github_api_git_sync_repository_test.dart`
  - Added parsing and API repository coverage.
- `docs/harness/specs/github-repository-download-sync/`, `.maestro/ios/github_repository_download_sync_flow.yaml`,
  and `.maestro/android/github_repository_download_sync_flow.yaml` - Added the
  remote-to-local sync spec and dev fixture acceptance flows.
- `lib/features/directory_git_sync/data/datasources/github_contents_api.dart`
  and `lib/features/directory_git_sync/data/repositories/github_api_git_sync_repository.dart`
  - Changed real GitHub sync to list remote contents and download files into
  the selected local directory.
- `lib/features/directory_git_sync/presentation/pages/directory_sync_page.dart`
  and `lib/features/directory_git_sync/presentation/bloc/directory_sync_bloc.dart`
  - Updated selected-directory presentation and sync-direction copy.
- `lib/features/directory_git_sync/presentation/models/selected_directory_display.dart`
  and `test/features/directory_git_sync/presentation/models/selected_directory_display_test.dart`
  - Added user-facing selected-directory display mapping and regression tests
  for iOS Files provider paths.
- `test/features/directory_git_sync/data/datasources/github_contents_api_test.dart`
  and `test/features/directory_git_sync/data/repositories/github_api_git_sync_repository_test.dart`
  - Added remote download regression coverage.
- `docs/harness/evidence/github-repository-download-sync/report-ios.json` -
  Saved the passing iOS acceptance report.
- `docs/harness/specs/github-device-flow-auth/`, `.maestro/ios/github_device_flow_auth_flow.yaml`, and `.maestro/android/github_device_flow_auth_flow.yaml`
  - Added Device Flow spec, acceptance checklist, UI target delta, and
  dual-platform Maestro flows.
- `docs/harness/specs/encrypted-token-default-directory/ui-map.delta.yaml` and
  `docs/harness/specs/ui-map.yaml` - Removed obsolete manual token input
  targets and regenerated the canonical UI target map.
- `dart_defines/dev.json`, `dart_defines/stg.json`, and
  `dart_defines/prod.json` - Added GitHub OAuth scope/client-id config fields.
- `lib/core/config/app_config.dart` and `lib/core/injection/` - Added GitHub
  OAuth config and Device Flow dependency registrations.
- `lib/features/token_settings/` - Added Device Flow domain entities, API
  datasource, fixture and real repositories, use cases, BLoC polling behavior,
  and Device Flow settings UI.
- `lib/features/directory_git_sync/` - Updated missing-auth validation and
  visible copy from manual access token to GitHub authorization.
- `test/features/token_settings/`, `test/core/config/app_config_test.dart`,
  `test/core/injection/injection_test.dart`, and
  `test/features/directory_git_sync/presentation/bloc/directory_sync_bloc_test.dart`
  - Added Device Flow API/repository/BLoC/entity coverage and updated auth
  wording expectations.
- `docs/harness/evidence/github-device-flow-auth/` - Saved dual-platform
  acceptance reports.

## Evidence of Completion

- [x] `fvm dart run tool/harness.dart check` passes: format clean, structure
  green, analyzer clean, 123 coverage-gated tests pass, coverage 423/468 lines
  (90.38%) against the 90% threshold.
- [x] `fvm dart run tool/harness.dart check` passes after the icon dependency
  fix: format clean, structure green, analyzer clean, 123 coverage-gated tests
  pass, coverage 423/468 lines (90.38%) against the 90% threshold.
- [x] `fvm dart run tool/harness.dart spec review encrypted-token-default-directory --approve`
  passes and marks the spec approved.
- [x] `fvm dart run tool/harness.dart spec accept encrypted-token-default-directory --maestro --platform all`
  passes with iOS and Android both PASS.
- [x] `fvm dart run tool/harness.dart spec accept directory-git-sync --maestro --platform all`
  passes after refreshing the workflow.
- [x] `fvm dart run tool/harness.dart spec accept ios-clean-ui --maestro --platform all`
  passes after refreshing the workflow.
- [x] `fvm flutter test test/features/directory_git_sync/data/repositories/process_git_sync_repository_test.dart`
  passes after adding real Git process failure and timeout regression coverage.
- [x] `fvm flutter analyze` passes after the paste and real Git failure-state
  fixes.
- [x] `fvm dart run tool/harness.dart structure` passes after the paste and real
  Git failure-state fixes.
- [x] `fvm dart run tool/harness.dart spec review github-directory-api-sync --approve`
  passes and marks the spec approved.
- [x] `fvm flutter test test/features/directory_git_sync/data/models/github_repository_target_test.dart`
  passes.
- [x] `fvm flutter test test/features/directory_git_sync/data/repositories/github_api_git_sync_repository_test.dart`
  passes.
- [x] `fvm flutter test test/core/injection/injection_test.dart` passes.
- [x] `fvm dart run tool/harness.dart check` passes: format clean, structure
  green, analyzer clean, coverage-gated tests pass, coverage 573/631 lines
  (90.81%) against the 90% threshold.
- [x] `fvm dart run tool/harness.dart spec accept github-directory-api-sync`
  passes all logic acceptance items but exits non-zero because the Maestro item
  is skipped without `--maestro`.
- [x] `fvm dart run tool/harness.dart spec accept github-directory-api-sync --maestro --platform all`
  passes with iOS and Android both PASS; reports copied to
  `docs/harness/evidence/github-directory-api-sync/`.
- [x] `fvm dart run tool/harness.dart spec review github-repository-download-sync --approve`
  passes and marks the new spec approved.
- [x] `fvm flutter test test/features/directory_git_sync/data/datasources/github_contents_api_test.dart test/features/directory_git_sync/data/repositories/github_api_git_sync_repository_test.dart test/features/directory_git_sync/data/repositories/fixture_git_sync_repository_test.dart test/core/injection/injection_test.dart`
  passes.
- [x] `fvm dart run tool/harness.dart spec ui-map --check` passes after adding
  the new spec delta.
- [x] `fvm dart run tool/harness.dart check` passes: format clean, structure
  green, analyzer clean, coverage-gated tests pass, coverage 589/647 lines
  (91.04%) against the 90% threshold.
- [x] `fvm dart run tool/harness.dart spec accept github-repository-download-sync --maestro --platform ios`
  passes on iOS.
- [x] `fvm dart run tool/harness.dart spec accept github-repository-download-sync --maestro --platform android`
  passes on Android.
- [x] `fvm dart run tool/harness.dart spec accept github-repository-download-sync --maestro --platform all`
  passes with iOS and Android both PASS; reports copied to
  `docs/harness/evidence/github-repository-download-sync/`.
- [x] `fvm flutter test test/features/directory_git_sync/presentation/models/selected_directory_display_test.dart`
  passes after hiding iOS file-provider sandbox paths from the selected
  directory UI.
- [x] `fvm flutter analyze` passes after the selected-directory display fix.
- [x] `fvm dart run tool/harness.dart structure` passes after adding the
  selected-directory presentation model.
- [x] `fvm dart run tool/harness.dart spec review github-device-flow-auth --approve`
  passes and marks the new spec approved.
- [x] `fvm flutter test test/features/token_settings` passes with Device Flow
  API, repository, entity, and BLoC coverage.
- [x] `fvm dart run tool/harness.dart check` passes: format clean, structure
  green, analyzer clean, coverage-gated tests pass, coverage 741/809 lines
  (91.59%) against the 90% threshold.
- [x] `fvm dart run tool/harness.dart spec accept github-device-flow-auth`
  passes all logic acceptance items but exits non-zero because the Maestro item
  is skipped without `--maestro`.
- [x] `fvm dart run tool/harness.dart spec accept github-device-flow-auth --maestro --platform all`
  passes with iOS and Android both PASS; reports copied to
  `docs/harness/evidence/github-device-flow-auth/`.
