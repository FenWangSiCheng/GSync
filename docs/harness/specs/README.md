# Spec Evaluation

This directory stores human-readable acceptance specs, UI target maps, and
machine-checkable acceptance checklists for agentic UI evaluation.

## The four-stage flow

A point (a feature or a bug) becomes a verified result through four stages with
two review gates:

```text
Stage 0  Human gives a point (feature or bug)
   |
Stage 1  AI drafts a reviewable acceptance script  (spec.md + ui-map.delta + acceptance.yaml)
   |
   v
   === Gate A: human reviews the acceptance checklist ===
   |        not approved -> back to Stage 1
   |        approved      -> feature status becomes spec-approved
   v
Stage 2  AI implements the feature or fixes the bug under lib/
   |
   v
   === Gate B: AI runs acceptance and reports a result ===
            spec accept <id>  ->  PASS / FAIL / BLOCKED + evidence
```

The rule the gates enforce: **implementation only happens after the human
approves the acceptance script.** `test/harness/architecture_guard_test.dart`
guards this: every feature with a business layer (`domain/` or `data/`) must
link a spec in `feature_list.json` whose status is past gate A.

## Commands

```sh
# Stage 1: scaffold a reviewable spec (fills templates for the AI to complete)
fvm dart run tool/harness.dart spec new <id>

# Gate A: print the acceptance checklist for human review
fvm dart run tool/harness.dart spec review <id>
# Approve it (flips the linked feature to spec-approved)
fvm dart run tool/harness.dart spec review <id> --approve

# Gate B: run acceptance and write a pass/fail report
fvm dart run tool/harness.dart spec accept <id>
# Also run Maestro criteria on a booted simulator/device
fvm dart run tool/harness.dart spec accept <id> --maestro
```

UI acceptance criteria use `kind: maestro` and run only when `--maestro` is
passed with a booted device. `kind: test` is reserved for non-UI logic, data,
or business unit tests; do not use widget tests for UI behavior. The report is
written to `build/harness/evidence/<id>/report.json`.

## File layout

- `<id>/spec.md` — human-readable goal, preconditions, steps, and acceptance
  criteria. New specs use a per-spec directory.
- `<id>/ui-map.delta.yaml` — only the new UI targets this spec introduces; merge
  into `ui-map.yaml` once approved.
- `<id>/acceptance.yaml` — the machine-checkable checklist. UI claims map to
  `kind: maestro` with a `flow`; non-UI logic claims may map to `kind: test`
  with a unit-test `file`.
- `ui-map.yaml` — the canonical UI target map shared by all specs.
- `user-profile-flow.md`, `acceptance.yaml` — the reference demo, kept flat.

## Translation rules

- Prefer `semantics_identifier` from `ui-map.yaml`.
- Do not invent labels or targets.
- Map UI behavior to Maestro flows, not Flutter widget tests.
- Use `kind: test` only for logic, data mapping, BLoC, repository, or other
  non-UI unit tests.
- If a step cannot be mapped to a known target, report `BLOCKED` instead of
  generating a guessed command.

Keep specs readable enough for product, QA, and engineering review. Keep
execution details in `.maestro/` so a spec can be reviewed before the generated
flow changes.
