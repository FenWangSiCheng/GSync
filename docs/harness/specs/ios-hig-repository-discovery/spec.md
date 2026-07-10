# Spec: ios-hig-repository-discovery

## Goal

Verify that an authorized user can quickly discover an accessible GitHub
repository with an iOS-native search field, without changing repository,
branch, or sync behavior.

## Preconditions

- Run the `dev` flavor.
- Complete the deterministic GitHub Device Flow fixture.
- The dev repository fixture returns the `GitSync/gitsync-fixture` repository.

## Steps

1. Launch the app and complete GitHub authorization.
2. Return to the directory sync screen and wait for the repository list.
3. Enter `fixture` in the repository search field.
4. Confirm that the filtered count and matching repository are visible.
5. Enter a term with no matching repository.
6. Confirm that a readable empty-state message is visible.

## Acceptance Criteria

- The search field appears only after repositories are available.
- Search filters the already-loaded repository list locally by repository name.
- The result count and empty-state message communicate the current result
  state without relying on color alone.
- The existing repository option semantics identifier remains available for a
  matching repository, preserving the existing selection flow.
- Cupertino colors continue to resolve through the active system appearance;
  the app must not force light appearance.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
