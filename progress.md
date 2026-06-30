# Session Progress Log

## Current State

**Last Updated:** 2026-06-30 CST
**Active Feature:** feat-003 (Home User Display, done)


## Status

### What's Done

- [x] feat-001 (Home Step Counter) is implemented and accepted.
  - `lib/features/home/presentation/bloc/` owns counter events, states, and transitions.
  - `HomePage` renders BLoC state and dispatches counter events.
  - `test/features/home/presentation/bloc/home_counter_bloc_test.dart` covers initial, increment, repeated increment, and reset behavior with 100% coverage.
  - `.maestro/ios/home_counter_flow.yaml` and `.maestro/android/home_counter_flow.yaml` are the Maestro E2E flows.
  - `fvm dart run tool/harness.dart spec accept home-counter --maestro` passes on iOS.
  - `docs/harness/evidence/home-counter/report.json` is committed acceptance evidence.
- [x] feat-002 (Home Counter Decrement) is implemented and done.
  - `docs/harness/specs/home-counter-decrement/` defines spec, acceptance.yaml, and ui-map delta.
  - Added `DecrementHomeCounter` event and `_onDecrement` handler with zero-floor guard.
  - `HomePage` renders `-1` button with `Semantics(identifier: 'home.counter.decrement')`.
  - `.maestro/{ios,android}/home_counter_decrement_flow.yaml` covers decrement-at-zero, decrement-to-1, decrement-to-0 scenarios.
  - `test/features/home/presentation/bloc/home_counter_bloc_test.dart` expanded with 3 new decrement tests (above zero, at zero, 1→0).
  - `fvm dart run tool/harness.dart spec accept home-counter-decrement --maestro --platform ios` reports PASS.
  - `docs/harness/evidence/home-counter-decrement/report.json` is committed acceptance evidence.
  - Fixed `tool/harness.dart` to pass `--platform` to Maestro CLI in both `eval` and `_specAccept`.
- [x] feat-003 (Home User Display) is implemented and done.
  - `docs/harness/specs/home-user-display/` defines spec, acceptance.yaml (6 criteria), and ui-map delta (5 new targets).
  - Created `HomeUserBloc`, `HomeUserEvent`, `HomeUserState` in `lib/features/home/presentation/bloc/`.
  - `HomeUserBloc` depends on `GetUserUseCase` (constructor injection), loads user1 on init.
  - `HomePage` refactored to `MultiBlocProvider` with `_HomeUserSection` and `_HomeCounterSection` widgets.
  - User card displays avatar (`Images.userAvatar`), name, email above the counter in a `ListView`.
  - `.maestro/{ios,android}/home_user_display_flow.yaml` verifies user card, counter, and cross-interaction.
  - `test/features/home/presentation/bloc/home_user_bloc_test.dart` passes 6 tests (initial, loaded, generic error, ApiException error, correct userId, multi-event).
  - `fvm dart run tool/harness.dart check` passes: format clean, structure 17/17, analyzer clean, all 159 tests pass.
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
3. Consider what feature to implement next (feat-004).

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
- **Reuse GetUserUseCase in HomeUserBloc**: feat-003 reuses the existing user feature domain layer via constructor injection instead of duplicating data access.

## Files Modified This Session

- `feature_list.json` - Added feat-003 (Home User Display), status done.
- `progress.md` - Updated session progress with feat-003 details.
- `docs/harness/specs/home-user-display/spec.md` - Created user display spec.
- `docs/harness/specs/home-user-display/acceptance.yaml` - Created 6 acceptance criteria.
- `docs/harness/specs/home-user-display/ui-map.delta.yaml` - Created 5 new UI targets.
- `lib/features/home/presentation/bloc/home_user_event.dart` - Created LoadHomeUser event.
- `lib/features/home/presentation/bloc/home_user_state.dart` - Created HomeUserInitial/Loading/Loaded/Error states.
- `lib/features/home/presentation/bloc/home_user_bloc.dart` - Created HomeUserBloc with GetUserUseCase dependency.
- `lib/features/home/presentation/pages/home_page.dart` - Refactored to MultiBlocProvider, added _HomeUserSection with user card.
- `test/features/home/presentation/bloc/home_user_bloc_test.dart` - Created 6 BLoC tests.
- `.maestro/ios/home_user_display_flow.yaml` - Created iOS Maestro flow.
- `.maestro/android/home_user_display_flow.yaml` - Created Android Maestro flow.

## Evidence of Completion

- [x] `fvm dart run tool/harness.dart check` passes: Format clean, structure 17/17, analyzer clean, all 159 tests pass.
- [x] HomeUserBloc tests: 6/6 pass (initial, loaded, generic error, ApiException, userId, multi-event).
- [x] feat-003 status is done in feature_list.json with complete evidence.
- [x] `fvm dart run tool/harness.dart spec accept home-user-display --maestro --platform ios` reports PASS on iOS (6/6 criteria).
- [x] `docs/harness/evidence/home-user-display/report.json` committed as acceptance evidence.
