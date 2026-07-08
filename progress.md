# Session Progress Log

## Current State

**Last Updated:** 2026-07-08 CST
**Active Feature:** `feat-github-directory-api-sync`
**Current Activity:** Implemented GitHub Repository Contents API-backed sync for
real `stg` and `prod` runs. Dual-platform Maestro dev acceptance passes on iOS
and Android, and evidence is committed under `docs/harness/evidence/`.

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

### What's Next

1. No outstanding implementation or acceptance work for
   `feat-github-directory-api-sync`.
2. Future work can add one-commit-per-sync behavior through Git Trees/Commits
   API or GitHub OAuth.

## Blockers / Risks

- [ ] No blockers for `feat-encrypted-token-default-directory`; it is `done`.
- [ ] Flutter warns that some iOS plugins do not support Swift Package Manager.
  This is not blocking current validation but may become an issue in a future
  Flutter release.
- [ ] Android build warns that the Gradle, Android Gradle Plugin, and Kotlin
  versions will need upgrades before future Flutter versions drop support.
- [ ] GitHub Contents API creates one commit per file. A future feature can move
  to Git Trees/Commits API if a single commit per directory sync is required.

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
  system `git` process. The real sync path now uses GitHub REST API file
  create/update calls for the user-specified repository or directory URL.
- **Keep dev deterministic:** The dev flavor remains on
  `FixtureGitSyncRepository` so Maestro acceptance does not require a live
  GitHub account or token.

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
