# Session Handoff

## Current Objective

- Goal: Keep this Flutter repository as a harness project with a single verified feature (Home Step Counter).
- Current status: feat-001 (Home Step Counter) is done. The counter state lives in `lib/features/home/presentation/bloc/` and `HomePage` renders BLoC state and dispatches events. `spec review home-counter` prints the human-reviewable script; `spec accept home-counter --maestro` passes the iOS Maestro flow. UI behavior is Maestro-only; Flutter/Dart tests are for non-UI logic, data, BLoC, repository, configuration, and harness rules.
- Branch / commit: Inspect with `git status --short` and `git log --oneline -1`.

## Completed

- [x] feat-001 (Home Step Counter) is implemented with BLoC pattern, Maestro E2E flows, and committed acceptance evidence.
- [x] `docs/harness/specs/home-counter/` defines the reviewable spec and Maestro-only UI acceptance checklist.
- [x] `.maestro/ios/home_counter_flow.yaml` and `.maestro/android/home_counter_flow.yaml` are the executable E2E flows.
- [x] `docs/harness/evidence/home-counter/report.json` is committed acceptance evidence.
- [x] Harness structure tests guard feature state, spec evaluation workflow, architecture boundaries, and UI test policy.
- [x] `tool/harness.dart` includes ANDROID_HOME/platform-tools auto-discovery.
- [x] CI runs `./init.sh` as the primary harness gate.

## Verification Evidence

| Check | Command | Result | Notes |
|---|---|---|---|
| Harness doctor | `fvm dart run tool/harness.dart doctor` | Pass | Reports all tools and skills. |
| Structure guard | `fvm dart run tool/harness.dart structure` | Pass | All harness structure tests pass. |
| Flutter harness check | `fvm dart run tool/harness.dart check` | Pass | Format clean, analyzer clean, all Flutter tests pass. |
| Standard startup | `./init.sh` | Pass | Bootstrap completed, full check passed. |
| CI harness gate | `.github/workflows/harness.yml` | Present | Runs `./init.sh` on PRs and pushes. |
| Home Counter BLoC test | `fvm flutter test test/features/home/presentation/bloc/home_counter_bloc_test.dart` | Pass | 4 tests, 100% coverage. |
| Home Counter iOS acceptance | `fvm dart run tool/harness.dart spec accept home-counter --maestro` | Pass | Maestro flow passes on iOS. |

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

- Propose a new feature via the spec evaluation workflow: `fvm dart run tool/harness.dart spec new <id>`.
