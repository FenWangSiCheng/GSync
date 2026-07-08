# Spec: github-repository-download-sync

## Goal

Verify that GitSync syncs a GitHub repository or repository subdirectory down to
the selected local device directory.

## Preconditions

- Run the `dev` flavor for UI acceptance.
- The dev build keeps using the deterministic fixture remote
  `https://example.invalid/gitsync-fixture.git` and fixture token `test-token`
  for Maestro acceptance.
- Real `stg` and `prod` builds accept a GitHub repository URL such as
  `https://github.com/owner/repo`, or a GitHub directory URL such as
  `https://github.com/owner/repo/tree/main/notes`.

## Steps

1. Launch the app.
2. Confirm the default local sync directory is selected and readable.
3. Open token settings and save the GitHub access token.
4. Return to the directory sync screen.
5. Enter the GitHub repository or target directory URL.
6. Tap Sync.
7. Wait for the sync to finish.

## Acceptance Criteria

- The selected directory display shows the directory name and enough path
  context to confirm where files will be written.
- Real sync recursively reads the remote GitHub repository path through the
  GitHub Repository Contents API.
- Real sync writes downloaded remote files into the selected local directory,
  preserving nested relative paths.
- Empty remote directories finish with a no-changes message instead of claiming
  files were synced.
- The primary UI copy describes the direction as GitHub remote to local
  directory sync.
- Authentication, target parsing, and GitHub API failures are surfaced as a
  readable failed state without exposing the saved token.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
