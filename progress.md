# Session Progress Log

## Current State

**Last Updated:** 2026-06-29 CST
**Active Feature:** None (feat-001 is done)


## Status

### What's Done

- [x] feat-001 (Home Step Counter) is implemented and accepted.
  - `lib/features/home/presentation/bloc/` owns counter events, state, and transitions.
  - `HomePage` renders BLoC state and dispatches counter events.
  - `test/features/home/presentation/bloc/home_counter_bloc_test.dart` covers initial, increment, repeated increment, and reset behavior with 100% coverage.
  - `.maestro/ios/home_counter_flow.yaml` and `.maestro/android/home_counter_flow.yaml` are the Maestro E2E flows.
  - `fvm dart run tool/harness.dart spec accept home-counter --maestro` passes on iOS.
  - `docs/harness/evidence/home-counter/report.json` is committed acceptance evidence.
- [x] Flutter harness provides repository docs, structural tests, a Dart command runner, and debug runtime events.
- [x] `tool/harness.dart` provides bootstrap, doctor, format, structure, test, check, eval, and spec commands.
- [x] `./init.sh` wraps bootstrap and check for session startup.
- [x] CI workflow (`.github/workflows/harness.yml`) runs `./init.sh` as the primary harness gate.
- [x] Official Flutter and Dart agent skills are installed under `.agents/skills`.
- [x] UI behavior is verified by Maestro flows; Flutter/Dart tests are for non-UI logic, data, BLoC, repository, configuration, and harness rules.
- [x] `test/harness/architecture_guard_test.dart` guards harness structure, feature state, spec evaluation workflow, architecture layer boundaries, and UI test policy.

### What's Next

1. Decide whether device-backed Maestro checks should remain explicit or become part of a separate CI/device job.
2. Add coverage thresholds once current coverage is measured and baselined.

## Blockers / Risks

- [ ] Maestro eval depends on external simulator/device state and remains outside the default `check` command.
- [ ] UI-only specs require `--maestro` for PASS because they intentionally have no `kind: test` criteria.

## Decisions Made

- **Use root artifacts for harness compatibility**: Keep `feature_list.json`, `progress.md`, `init.sh`, and `session-handoff.md` as root state artifacts.
- **Keep `tool/harness.dart` as the authoritative Flutter command runner**: `init.sh` wraps the Dart runner instead of duplicating Flutter commands.
- **Keep official agent skills checked into the project**: Store Flutter and Dart skills in `.agents/skills`.
- **Keep Maestro eval outside the default check**: Device-backed E2E should be explicit.
- **Use Maestro for UI behavior instead of widget tests**: Screen rendering, visible text, controls, and navigation are accepted through `.maestro/` flows.
- **Device-backed Maestro checks remain explicit**: Keep `--maestro` flag requirement.
- **Added ANDROID_HOME/platform-tools auto-discovery**: `tool/harness.dart` automatically searches common Android SDK locations for adb.

## Files Modified This Session

- `feature_list.json` - Cleaned up to only feat-001 (Home Step Counter).
- `progress.md` - Updated session progress.
- `session-handoff.md` - Updated next-session handoff.
- `docs/harness/specs/home-counter/acceptance.yaml` - Updated feature ID.
- `docs/harness/evidence/home-counter/report.json` - Updated feature ID.
- `test/harness/architecture_guard_test.dart` - Updated spec evaluation tests.
- `docs/harness/VALIDATION.md` - Updated spec references.
- `docs/harness/specs/README.md` - Removed stale references.
- `docs/harness/specs/acceptance.yaml` - Removed (feat-008 artifact).
- `docs/harness/specs/user-profile-flow.md` - Removed (feat-008 artifact).
- `docs/harness/specs/ui-map.yaml` - Removed (feat-008 artifact).
- `.maestro/android/user_profile_flow.yaml` - Removed (feat-008 artifact).
- `.maestro/ios/user_profile_flow.yaml` - Removed (feat-008 artifact).

## Evidence of Completion

- [x] `./init.sh` passes: Full baseline verification successful.
- [x] `fvm dart run tool/harness.dart structure` passes: All harness structure tests pass.
- [x] `fvm dart run tool/harness.dart check` passes: Format clean, analyzer clean, all Flutter tests pass.
- [x] Home Counter BLoC coverage: 100% (7/7 lines hit).
- [x] feat-001 status is done in feature_list.json with complete evidence.
- [x] `fvm dart run tool/harness.dart spec accept home-counter --maestro` passes on iOS.
