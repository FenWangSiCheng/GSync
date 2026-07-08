# Session Handoff

## Current Objective

- Goal: Maintain this repository as a blank Flutter harness template.
- Current status: Demo UI, demo features, demo assets, demo Maestro flows, demo
  specs, and demo evidence have been removed. The harness framework remains.
- Feature state: `feature_list.json` currently has no features.

## Completed

- [x] App route now renders a minimal blank template page.
- [x] Feature directories are empty placeholders ready for real project work.
- [x] Canonical UI map is empty and generated from future approved spec deltas.
- [x] Maestro CI skips cleanly when there are no `done` specs.
- [x] Harness guard tests were updated for blank-template state.

## Verification Evidence

| Check | Command | Result | Notes |
|---|---|---|---|
| Structure guard | `fvm dart run tool/harness.dart structure` | Pass | 19/19 harness structure tests. |
| Analyzer | `fvm flutter analyze` | Pass | No issues found. |
| Tests | `fvm flutter test` | Pass | 95/95 tests. |
| Full harness check | `fvm dart run tool/harness.dart check` | Pass | Format, structure, analyzer, and coverage gate passed; included coverage 153/166 lines (92.17%). |

## Blockers / Risks

- No known blockers.
- Device-backed Maestro remains required before any future user-visible feature
  is marked `done`.

## Next Session Startup

1. Read `AGENTS.md`.
2. Read `docs/harness/README.md` and relevant harness docs.
3. Read `feature_list.json` and `progress.md`.
4. Run `fvm dart run tool/harness.dart check` or the narrowest relevant check.

## Recommended Next Step

- Add the first real feature to `feature_list.json`, scaffold its spec with
  `fvm dart run tool/harness.dart spec new <id>`, and keep implementation gated
  by the existing harness workflow.
