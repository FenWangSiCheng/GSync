# Validation

Use `tool/harness.dart` as the stable entry point for local checks.

For a fresh agent session, prefer the walkinglabs lifecycle wrapper:

```bash
./init.sh
```

`init.sh` runs bootstrap first and then the full harness check. Use narrower
commands below while iterating.

## Fast Checks

```bash
fvm dart run tool/harness.dart doctor
fvm dart run tool/harness.dart structure
```

`doctor` reports tool versions and generated-file state. `structure` runs the
structural guard tests that protect harness assumptions.

## Full Check

```bash
fvm dart run tool/harness.dart check
```

The full check runs:

1. `fvm dart format --set-exit-if-changed lib test tool`
2. `fvm dart run tool/harness.dart structure`
3. `fvm flutter analyze`
4. `fvm flutter test`

## Test Policy

UI behavior is verified by Maestro flows, not Flutter widget tests. Keep
`kind: maestro` acceptance criteria for screens, controls, navigation, and
visible text. Use Flutter tests for logic, data mapping, repositories, BLoCs,
configuration, networking, and harness rules.

## Optional Spec Evaluation

Maestro flows are device-backed E2E checks and are intentionally outside the
default `check` command. Install Maestro, launch or install the `dev` app on a
simulator or device, then run:

```bash
fvm dart run tool/harness.dart eval
```

Platform-specific variants are available:

```bash
fvm dart run tool/harness.dart eval-android
fvm dart run tool/harness.dart eval-ios
```

The current demo flows live under `.maestro/android/` and `.maestro/ios/`, and
map to the human-readable spec in `docs/harness/specs/user-profile-flow.md`.

## Bootstrap

```bash
fvm dart run tool/harness.dart bootstrap
```

Bootstrap runs dependency installation and code generation:

1. `fvm flutter pub get`
2. `fvm flutter packages pub run build_runner build --delete-conflicting-outputs`

## Failure Triage

- Formatting failure: run `fvm dart format lib test tool`.
- Generated-code failure: run the bootstrap command.
- Structural failure: read `docs/harness/ARCHITECTURE.md` and fix the import or
  documented exception.
- Walkinglabs structural failure: check `AGENTS.md`, `feature_list.json`,
  `progress.md`, `init.sh`, and `session-handoff.md` before patching code.
- Test failure: prefer the narrowest failing test first, then the full suite.
- Analyzer failure: fix the warning instead of suppressing it unless there is a
  documented project reason.

## External Harness Audit

When the walkinglabs course repository is available locally, run its structural
validator against this repo:

```bash
node /path/to/learn-harness-engineering/skills/harness-creator/scripts/validate-harness.mjs --target .
```

In the Codex desktop bundled runtime, `node` may be available at:

```bash
/Users/wangsicheng/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node
```

## CI

GitHub Actions runs the same standard lifecycle command on pull requests and
pushes to `main` or `master`:

```bash
./init.sh
```

The workflow installs FVM, installs the configured Flutter SDK from
`.fvm/fvm_config.json`, and then runs the standard startup path.

## Flutter Version

The local source of truth is `.fvm/fvm_config.json`. As of this harness update,
the project uses Flutter `3.44.0`.
