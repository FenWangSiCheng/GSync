# Session Handoff

## Current Objective

- Goal: Keep the selected local directory identical to the selected GitHub
  repository path after a successful sync.
- Current status: `feat-github-local-mirror-sync` is `done`. The repository now
  reads all remote files, writes the remote tree locally, then removes local
  files, links, and directories that are absent from the remote tree. A failed
  remote request does not start cleanup.
- Verification: `fvm dart run tool/harness.dart check` passes with coverage
  1011/1103 lines (91.66%). Dual-platform Maestro acceptance for
  `github-local-mirror-sync` passes on iOS and Android; evidence is saved under
  `docs/harness/evidence/github-local-mirror-sync/`.
- Feature state: `feat-directory-git-sync`, `feat-ios-clean-ui`, and
  `feat-encrypted-token-default-directory` are `done`;
  `feat-github-directory-api-sync` is `done`;
  `feat-github-repository-download-sync` is `done`;
  `feat-github-device-flow-auth` is `done`;
  `feat-github-repository-picker-sync` and
  `feat-ios-hig-repository-discovery` are `done`;
  `feat-github-local-mirror-sync` is `done`.

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
- [x] Fixed real-device iOS Files directory write access for GitHub download
  sync by replacing iOS directory picking with a local document-picker channel,
  retaining the selected security-scoped URL, and wrapping real download writes
  in `DirectoryAccessScope`.
- [x] Added GitHub repository and branch catalog loading after authorization.
- [x] Replaced the typed GitHub URL sync UI with repository and branch
  selection.
- [x] Updated dev fixtures, Maestro flows, specs, UI target map, feature state,
  progress, and evidence for repository picker sync.
- [x] Added iOS-native local repository filtering with a 44pt
  `CupertinoSearchTextField`, plus accessible result-count and empty-result
  feedback, without changing catalog or sync logic.
- [x] Removed the forced light Cupertino theme so the app follows the system
  appearance.
- [x] Ran and saved dual-platform Maestro evidence for
  `ios-hig-repository-discovery`.
- [x] Drafted, approved, implemented, and accepted
  `feat-github-local-mirror-sync`.
- [x] Made successful remote-to-local syncs delete residual local files, links,
  and directories after the complete remote tree is read.
- [x] Added regression tests for residual deletion, file/directory type
  collisions, and remote-download failure safety.
- [x] Ran and saved dual-platform Maestro evidence for
  `github-local-mirror-sync`.

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
| iOS Files directory access hotfix | `fvm flutter test test/features/directory_git_sync/data/datasources/directory_access_scope_test.dart test/features/directory_git_sync/data/repositories/github_api_git_sync_repository_test.dart test/core/injection/injection_test.dart` | Pass | Verifies security-scoped start/action/stop behavior, download repository behavior, and DI wiring. |
| Full harness check | `fvm dart run tool/harness.dart check` | Pass | Format, structure, analyzer, and coverage passed; coverage 756/824 lines (91.75%). |
| iOS stg simulator compile | `xcodebuild -workspace ios/Runner.xcworkspace -scheme stg -configuration Debug-stg -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` | Pass | Confirms `ios/Runner/AppDelegate.swift` directory access channel compiles. |
| GitHub repository picker sync check | `fvm dart run tool/harness.dart check` | Pass | Format, structure, analyzer, and coverage passed; coverage 935/1027 lines (91.04%). |
| GitHub repository picker sync acceptance | `fvm dart run tool/harness.dart spec accept github-repository-picker-sync --maestro --platform all` | Pass | iOS and Android both PASS; evidence copied to `docs/harness/evidence/github-repository-picker-sync/`. |
| iOS HIG repository discovery check | `fvm dart run tool/harness.dart check` | Pass | Format, structure, analyzer, and coverage passed; coverage 935/1027 lines (91.04%). |
| iOS HIG repository discovery acceptance | `fvm dart run tool/harness.dart spec accept ios-hig-repository-discovery --maestro --platform all` | Pass | iOS and Android both PASS; evidence copied to `docs/harness/evidence/ios-hig-repository-discovery/`. |

## Code Simplification Pass (2026-07-10)

The project-local `code-simplifier` skill was applied across `lib/`. The pass
kept generated files and feature boundaries intact, removed a one-use Dio
initialization abstraction, shared GitHub API error parsing, reduced DI and
presentation/BLoC duplication, and left UI behavior unchanged.

Latest verification: `fvm dart run tool/harness.dart check` passes; coverage is
1003/1090 lines (92.02%).

## Blockers / Risks

- No current blockers for `feat-github-device-flow-auth`.
- Real `stg` and `prod` GitHub authorization requires a GitHub OAuth app with
  Device Flow enabled and `githubOAuthClientId` supplied through dart defines.
  Missing client ID is surfaced as a readable in-app failure.
- Flutter reports future-compatibility warnings for Swift Package Manager
  support in some iOS plugins.
- Android builds report future-compatibility warnings for Gradle, Android
  Gradle Plugin, and Kotlin versions.
- GitHub Contents API file content responses may need additional handling for
  very large files or Git LFS pointers in a future feature.
- Large GitHub accounts may still need catalog pagination or server-side search;
  the current search filters only the catalog already loaded by the app.
- The real-device iOS Files fix still needs a manual smoke test on an iPhone:
  select a folder under "On My iPhone" or another Files provider, authorize
  GitHub, and sync a repository containing nested files.

## Next Session Startup

1. Read `AGENTS.md`.
2. Read `docs/harness/README.md` and relevant harness docs.
3. Read `feature_list.json` and `progress.md`.
4. Run `fvm dart run tool/harness.dart check` for a quick green baseline, or
   `./init.sh` when a fresh restartability proof is needed.

## Recommended Next Step

- Pick the next feature in `feature_list.json` or draft a new feature using the
  same spec-first lifecycle. The next likely product additions are repository
  pagination, subdirectory selection, mirror previews or recovery, large-file
  support, background sync, or account switching.
