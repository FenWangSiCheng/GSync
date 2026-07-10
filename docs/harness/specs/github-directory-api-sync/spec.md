# Spec: github-directory-api-sync

## Goal

Verify that GitSync can sync the selected local directory to a GitHub
repository path through the GitHub Repository Contents API, without starting a
system `git` process on mobile platforms.

## Preconditions

- Run the `dev` flavor.
- The dev build keeps using deterministic repository, branch, and token
  fixtures for Maestro acceptance.
- Real `stg` and `prod` builds can still parse GitHub repository URLs
  internally, while the primary UI selects repositories and branches from the
  authorized account.

## Steps

1. Launch the app.
2. Confirm the default local sync directory is selected.
3. Open token settings and save the GitHub access token.
4. Return to the directory sync screen.
5. Select the fixture GitHub repository and branch.
6. Tap Sync.
7. Wait for the sync to finish.

## Acceptance Criteria

- The existing dev happy path remains visible and finishes with a success state
  without typing a repository URL.
- Real sync parses GitHub repository root URLs and GitHub branch directory URLs.
- Real sync uploads each regular local file through GitHub Repository Contents
  API create/update calls.
- Existing remote file SHA values are fetched before updates so GitHub accepts
  overwrites.
- Mobile real sync no longer calls `Process.run('git', ...)`.
- Authentication, target parsing, and GitHub API failures are surfaced as a
  readable failed state.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
