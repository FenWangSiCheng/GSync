# Spec: home-counter

## Goal

Verify that a user can increment a step counter on the Home page and reset it
back to zero.

## Preconditions

- Run the `dev` flavor.
- The Home tab is the default landing tab.

## Steps

1. Launch the app.
2. Open the Home tab.
3. Confirm the step counter shows `Steps: 0`.
4. Tap the `+1` button; the counter shows `Steps: 1`.
5. Tap the `+1` button again; the counter shows `Steps: 2`.
6. Tap the `Reset` button; the counter shows `Steps: 0`.

## Acceptance Criteria

Mirrored as machine-checkable items in `acceptance.yaml`.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
