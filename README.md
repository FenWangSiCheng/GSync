# Flutter Harness Project

**Repository-local AI coding harness for a feature-first Flutter app.**

This repository is a Flutter application wrapped in an agent-oriented harness.
The harness is the primary architecture: it makes instructions, state, validation,
scope, lifecycle, runtime signals, and project-local skills visible on disk so
agents can restart work without hidden context.

## Why A Harness?

AI coding agents need more than source code — they need repeatable entry points,
mechanical verification, durable state tracking, and explicit scope boundaries.
The harness encodes these as checked-in artifacts so every agent session starts
from the same ground truth, not from whatever the last session left in memory.

The approach follows the [OpenAI harness engineering field report][openai-harness]
and the [walkinglabs learn-harness-engineering][walkinglabs] model:

- Repository knowledge is the system of record.
- The top-level agent file is a map, not a manual.
- Architecture rules are explicit and tested.
- Validation is runnable from a single local entry point.
- Runtime behavior emits structured signals an agent can inspect.
- Quality and cleanup work are tracked as durable repo artifacts.
- Root state and lifecycle artifacts make sessions restartable.

[openai-harness]: https://openai.com/index/harness-engineering/
[walkinglabs]: https://github.com/walkinglabs/learn-harness-engineering

## Start Here

1. **[`AGENTS.md`](AGENTS.md)** — short startup map for coding agents.
2. **[`docs/harness/README.md`](docs/harness/README.md)** — harness subsystem map.
3. **[`feature_list.json`](feature_list.json)** — feature status, dependencies, and
   evidence.
4. **[`progress.md`](progress.md)** — current session state and next steps.
5. **[`session-handoff.md`](session-handoff.md)** — restart notes for future
   sessions.

## Harness Architecture

The harness is split into durable subsystems. Each subsystem has checked-in
artifacts and a mechanical verification path.

### Instructions

Route agents to the right local rules without turning the root file into a manual.

| Artifact | Purpose |
| --- | --- |
| [`AGENTS.md`](AGENTS.md) | One-page agent entry point with startup workflow and working loop. |
| [`docs/harness/README.md`](docs/harness/README.md) | Harness subsystem map and repository layout. |
| [`docs/harness/ARCHITECTURE.md`](docs/harness/ARCHITECTURE.md) | Flutter clean architecture boundaries and dependency rules. |
| [`docs/harness/TASKS.md`](docs/harness/TASKS.md) | How to write durable execution plans for multi-step work. |

### State

Track active scope, feature status, dependencies, blockers, and evidence on disk.

| Artifact | Purpose |
| --- | --- |
| [`feature_list.json`](feature_list.json) | Feature tracker — status, dependencies, spec links, and completion evidence. |
| [`progress.md`](progress.md) | Session continuity — decisions, risks, files touched, next step, and verification output. |

### Verification

Provide repeatable bootstrap, doctor, structure, format, analyzer, coverage, and
test commands. Every check runs locally without secrets or remote state.

| Artifact | Purpose |
| --- | --- |
| [`init.sh`](init.sh) | Walkinglabs-compatible lifecycle entrypoint — resolves Flutter packages, bootstraps generated code, then runs the full check. |
| [`tool/harness.dart`](tool/harness.dart) | Dart command runner with `doctor`, `structure`, `bootstrap`, `coverage`, `check`, `spec`, and Maestro helpers. |
| [`test/harness/`](test/harness/) | Structural guard tests that protect harness assumptions (skill presence, architecture layering, generated-file freshness, canonical UI map coverage, committed evidence alignment, and CI wiring). |
| [`docs/harness/VALIDATION.md`](docs/harness/VALIDATION.md) | Command reference, full check behavior, coverage gate, Maestro policy, and failure triage order. |

### Scope

Keep work feature-focused and record explicit dependencies before widening scope.

| Artifact | Purpose |
| --- | --- |
| [`feature_list.json`](feature_list.json) | Declares active feature, dependencies, and evidence gates. |
| [`docs/harness/TASKS.md`](docs/harness/TASKS.md) | Rules for scoping multi-step work and writing durable plans. |

### Lifecycle

Preserve decisions, touched files, verification output, and the next restart path
so sessions compose instead of conflicting.

| Artifact | Purpose |
| --- | --- |
| [`progress.md`](progress.md) | Updated at end of session with current state and evidence. |
| [`session-handoff.md`](session-handoff.md) | Restart instructions for the next agent session. |
| [`.github/workflows/harness.yml`](.github/workflows/harness.yml) | Primary CI gate that runs the standard harness startup (`./init.sh`). |
| [`.github/workflows/maestro.yml`](.github/workflows/maestro.yml) | Simulator-backed Maestro CI that runs every `done` spec on iOS and Android. |

### Skills

Keep Flutter and Dart agent workflows local to the repository and progressively
loaded so agents only pay for the skill they need.

| Artifact | Purpose |
| --- | --- |
| [`.agents/skills/`](.agents/skills/) | Project-local Flutter and Dart agent skills from official sources. |
| [`docs/harness/SKILLS.md`](docs/harness/SKILLS.md) | Skill inventory, update workflow, and usage rules. |

### Runtime Signals

Emit searchable `[harness]` debug events for startup and networking behavior so
agents can inspect runtime state without guessing.

| Artifact | Purpose |
| --- | --- |
| [`lib/core/harness/`](lib/core/harness/) | Lightweight `HarnessLogger` that emits structured JSON events. |
| [`docs/harness/OPERABILITY.md`](docs/harness/OPERABILITY.md) | Event catalog, log format, and local observability notes. |

### Quality Ledger

Track where the project is strong, where it is thin, and what to improve next —
so agents don't rediscover known gaps.

| Artifact | Purpose |
| --- | --- |
| [`docs/harness/QUALITY.md`](docs/harness/QUALITY.md) | Scorecard across architecture, tests, observability, docs, skills, CI, and lifecycle. |

## Standard Workflow

For a fresh session, use the walkinglabs-compatible lifecycle entrypoint:

```bash
./init.sh
```

`init.sh` first resolves Flutter packages with `fvm flutter pub get`, then
bootstraps generated code, and finally runs the full harness check. The pub get
preflight keeps fresh CI runners from invoking the Dart harness before Flutter SDK
packages are discoverable.

For narrower iteration, use the Dart harness runner directly:

```bash
# Inspect tools, generated files, harness docs, and local skills
fvm dart run tool/harness.dart doctor

# Run structural guard tests
fvm dart run tool/harness.dart structure

# Install dependencies and regenerate committed generated files
fvm dart run tool/harness.dart bootstrap

# Run format, structure, analyzer, and coverage-gated tests
fvm dart run tool/harness.dart check

# Recheck an existing coverage/lcov.info report without rerunning tests
fvm dart run tool/harness.dart coverage --check-only
```

Run `structure` after harness or architecture edits. Run `check` before handing
off broad changes. Update `progress.md`, `feature_list.json`, and
`session-handoff.md` when status, evidence, blockers, or restart instructions
change.

## Coverage Gate

`tool/harness.dart coverage` runs the Flutter test suite with coverage enabled and
enforces a 90% line-coverage threshold for non-UI logic. The gate intentionally
excludes Maestro-owned UI surface (`presentation/pages`, `core/router`,
`core/widgets`, `core/resources`, and `main.dart`) plus generated files, so the
coverage number measures the code that Flutter tests are responsible for.

```bash
fvm dart run tool/harness.dart coverage
```

The full `check` command includes this coverage gate after format, structure, and
analyzer. As of the latest harness update, included coverage is 259/279 lines
(92.83%).

## UI Target Map

Approved specs add UI targets in per-spec `ui-map.delta.yaml` files. The shared
[`docs/harness/specs/ui-map.yaml`](docs/harness/specs/ui-map.yaml) is generated
from deltas whose linked features are past Gate A, and `structure` verifies it is
current:

```bash
# Regenerate the canonical UI target map
fvm dart run tool/harness.dart spec ui-map

# Verify the generated file is up to date
fvm dart run tool/harness.dart spec ui-map --check
```

## Maestro Acceptance

User-visible UI behavior is verified by Maestro flows, not Flutter widget tests.
Device-backed Maestro checks are intentionally outside the default `check`
command, but dual-platform acceptance is required before marking a feature done:

```bash
fvm dart run tool/harness.dart spec accept <spec-id> --maestro --platform all
```

The command runs the spec on an iOS simulator and an Android emulator, then writes
`report-ios.json`, `report-android.json`, and a summary `report.json` under
`build/harness/evidence/<spec-id>/`. Copy all three files into
`docs/harness/evidence/<spec-id>/` and update `feature_list.json` before marking
the feature done. If either platform is unavailable, record `BLOCKED` instead of
done.

The [`.github/workflows/maestro.yml`](.github/workflows/maestro.yml) CI workflow
runs the same dual-platform acceptance for every `done` spec on hosted
simulators. It does not build or upload IPA, APK, or AAB artifacts, so no signing
certificates are required.

## Harness Definition Of Done

A change is harness-ready when:

- The target behavior or repository-visible outcome is implemented.
- Relevant harness docs and root state artifacts match the change.
- The smallest meaningful verification command has run and the result is recorded.
- Any generated files affected by annotations are regenerated and committed.
- The next agent can restart from `./init.sh` or from a documented failing
  baseline with an exact next action.
- The active feature in `feature_list.json` has explicit status, dependencies,
  and evidence.
- For features with UI acceptance, `fvm dart run tool/harness.dart spec accept
  <id> --maestro --platform all` reports PASS on both iOS and Android (or records
  `BLOCKED`).
- New operational signals are structured enough for an agent to search.
- Any newly discovered recurring failure is captured in docs, tests, or tooling.

## Flutter App (What The Harness Manages)

The app is a feature-first Flutter project using clean architecture. The harness
exists to make this app legible and checkable — the app is the work, the harness
is how agents work on it.

### Architecture

```text
lib/features/<feature>/
  domain/
    entities/
    repositories/
    usecase/
  data/
    datasource/
    models/
    repositories/
  presentation/
    bloc/
    pages/
    widgets/
```

Layer rules are enforced by `test/harness/architecture_guard_test.dart`:

- `domain` must not import `data` or `presentation`.
- `data` may depend on `domain` and core infrastructure, but not presentation.
- `presentation` owns Flutter UI, pages, widgets, and BLoCs.
- `core/router/app_router.dart` is the explicit app composition point.
- `AppConfig` owns flavor behavior; avoid ad hoc flavor checks.

![Clean Architecture Diagram](docs/images/clean_architecture.png)

### Data Flow

Request flow:

```text
UI -> Event -> BLoC -> UseCase -> Repository -> DataSource -> API/mock data
```

Response flow:

```text
API/mock data -> Model -> Entity -> UseCase -> BLoC -> State -> UI
```

![Data Flow Diagram](docs/images/data_flow.png)

### Tech Stack

- Flutter SDK `3.44.0`, managed by FVM.
- Dart SDK `>=3.9.2 <4.0.0`.
- Flavors: `dev`, `stg`, and `prod`.
- State management: `flutter_bloc`.
- Routing: `go_router`.
- Networking: Dio with interceptors, mock API support, and proxy behavior.
- Dependency injection: `get_it` and `injectable`.
- Generated Dart files are committed and must stay synchronized after annotation
  changes.

### Run The App

```bash
# Development flavor with local mock API support
fvm flutter run --flavor dev --dart-define-from-file=dart_defines/dev.json

# Staging flavor
fvm flutter run --flavor stg --dart-define-from-file=dart_defines/stg.json

# Production flavor
fvm flutter run --flavor prod --dart-define-from-file=dart_defines/prod.json
```

### Build

```bash
# Development APK
fvm flutter build apk --flavor dev --dart-define-from-file=dart_defines/dev.json

# Staging APK
fvm flutter build apk --flavor stg --dart-define-from-file=dart_defines/stg.json

# Production APK
fvm flutter build apk --flavor prod --dart-define-from-file=dart_defines/prod.json

# Production iOS
fvm flutter build ios --flavor prod --dart-define-from-file=dart_defines/prod.json
```

## License

Licensed under the Apache License, Version 2.0. See [`LICENSE`](LICENSE) for the
full license text.
