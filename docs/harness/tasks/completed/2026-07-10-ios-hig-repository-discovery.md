# iOS HIG Repository Discovery

## Goal

Make the directory-sync repository list easier to discover on iOS while
honoring system appearance, without changing GitHub sync behavior.

## Acceptance Criteria

- Authorized users can filter the loaded repository list with a native
  `CupertinoSearchTextField`.
- Filtered result count and the empty-result state are visible to VoiceOver and
  Maestro through stable semantic identifiers.
- System light and dark appearance are not overridden by the app theme.
- `fvm dart run tool/harness.dart check` and dual-platform Maestro acceptance
  pass.

## Progress

- [x] Draft spec and Maestro flow.
- [x] Approve Gate A.
- [x] Implement presentation-only search and appearance change.
- [x] Run acceptance and record evidence.

## Decisions

- 2026-07-10: Search is intentionally local to the repository list already
  loaded by the existing BLoC; API search and pagination remain out of scope.
- 2026-07-10: The feature keeps existing repository-option semantic identifiers
  so prior repository-selection acceptance remains valid.
- 2026-07-10: The user requested the new feature directly; that authorization
  is recorded as the Gate A approval after reviewing the generated checklist.
- 2026-07-10: The search field is explicitly 44pt high to meet the iOS minimum
  touch-target requirement rather than relying on the control's 40pt default.

## Validation

- 2026-07-10: `./init.sh` passed before this feature was drafted.
- 2026-07-10: Initial dual-platform Maestro run found an iOS-only flow issue:
  the keyboard obscured the result summary after entering a query. Android
  passed. iOS does not expose a standard keyboard-dismiss action for this
  control, so the shared flow scrolls the result row into view instead.
- 2026-07-10: `fvm dart run tool/harness.dart check` passed with 935/1027
  covered included lines (91.04%, minimum 90%).
- 2026-07-10: `fvm dart run tool/harness.dart spec accept
  ios-hig-repository-discovery --maestro --platform all` passed on iPhone 16
  Pro (iOS 18.6) and Pixel_9a (Android); reports were copied to
  `docs/harness/evidence/ios-hig-repository-discovery/`.
