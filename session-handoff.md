# Session Handoff

## Current Objective

- Goal: Keep this Flutter repository as a harness project with three verified features (Home Step Counter, Decrement, User Display).
- Current status: feat-001 (Home Step Counter) is done. feat-002 (Home Counter Decrement) is done. feat-003 (Home User Display) is done — all code, tests, structure checks, and Maestro E2E pass with committed evidence.
- Branch / commit: Inspect with `git status --short` and `git log --oneline -1`.

## Completed

- [x] feat-001 (Home Step Counter) is implemented with BLoC pattern, Maestro E2E flows, and committed acceptance evidence.
- [x] feat-002 (Home Counter Decrement) is implemented and done.
  - `DecrementHomeCounter` event + `_onDecrement` handler with zero-floor guard (`if (state.steps > 0)`).
  - `HomePage` renders `-1` button alongside `+1` and `Reset` with `Semantics(identifier: 'home.counter.decrement')`.
  - 3 new BLoC tests: decrement above zero, decrement at zero (no emit), decrement 1→0. Total 7/7 pass.
  - `.maestro/{ios,android}/home_counter_decrement_flow.yaml` covers: decrement at zero stays 0, increment to 2 → decrement to 1 → decrement to 0 → decrement again stays 0.
  - `docs/harness/specs/home-counter-decrement/` defines spec, acceptance.yaml, and ui-map delta.
  - `fvm dart run tool/harness.dart spec accept home-counter-decrement --maestro --platform ios` reports PASS.
  - `docs/harness/evidence/home-counter-decrement/report.json` is committed acceptance evidence.
  - Fixed `tool/harness.dart` to pass `--platform` to Maestro CLI in both `eval` and `_specAccept` methods.
- [x] feat-003 (Home User Display) is implemented and done.
  - `docs/harness/specs/home-user-display/` defines spec, 6 acceptance criteria, 5 new UI targets.
  - `HomeUserBloc` depends on `GetUserUseCase` (constructor injection), loads user1 (John Doe) on init.
  - `HomePage` refactored to `MultiBlocProvider` with `_HomeUserSection` (avatar, name, email) above `_HomeCounterSection`.
  - `test/features/home/presentation/bloc/home_user_bloc_test.dart`: 6 tests (initial, loaded, generic error, ApiException, userId, multi-event).
  - `.maestro/{ios,android}/home_user_display_flow.yaml` verifies user card + counter cross-interaction.
  - `fvm dart run tool/harness.dart spec accept home-user-display --maestro --platform ios` reports PASS (6/6 criteria).
  - `docs/harness/evidence/home-user-display/report.json` is committed acceptance evidence.
- [x] Harness structure tests guard feature state, spec evaluation workflow, architecture boundaries, and UI test policy.
- [x] `tool/harness.dart` includes ANDROID_HOME/platform-tools auto-discovery.
- [x] CI runs `./init.sh` as the primary harness gate.

## Verification Evidence

| Check | Command | Result | Notes |
|---|---|---|---|
| Harness doctor | `fvm dart run tool/harness.dart doctor` | Pass | Reports all tools and skills. |
| Structure guard | `fvm dart run tool/harness.dart structure` | Pass | 17/17 harness structure tests pass. |
| Flutter harness check | `fvm dart run tool/harness.dart check` | Pass | Format clean, analyzer clean, 159 tests pass. |
| Standard startup | `./init.sh` | Pass | Bootstrap completed, full check passed. |
| CI harness gate | `.github/workflows/harness.yml` | Present | Runs `./init.sh` on PRs and pushes. |
| Home Counter BLoC test | `fvm flutter test test/features/home/presentation/bloc/home_counter_bloc_test.dart` | Pass | 7 tests. |
| HomeUserBloc test | `fvm flutter test test/features/home/presentation/bloc/home_user_bloc_test.dart` | Pass | 6 tests. |
| Home Counter iOS acceptance | `fvm dart run tool/harness.dart spec accept home-counter --maestro` | Pass | Maestro flow passes on iOS. |
| Decrement iOS acceptance | `fvm dart run tool/harness.dart spec accept home-counter-decrement --maestro --platform ios` | Pass | All 4 Maestro criteria pass on iOS. |
| Home User Display iOS acceptance | `fvm dart run tool/harness.dart spec accept home-user-display --maestro --platform ios` | Pass | All 6 Maestro criteria pass on iOS. |

## Blockers / Risks

- Maestro eval depends on simulator/device state and remains outside the default `check` command.
- UI-only specs intentionally need `--maestro` to produce PASS.

## Next Session Startup

1. Read `AGENTS.md`.
2. Read `docs/harness/SKILLS.md` when a task touches Flutter or Dart behavior.
3. Read `feature_list.json` and `progress.md`.
4. Review this handoff.
5. Run `./init.sh` or `fvm dart run tool/harness.dart check` before editing.

## Recommended Next Step

- Decide whether to add Maestro to CI or keep it explicit.
- Consider what feature to implement next (feat-004).
