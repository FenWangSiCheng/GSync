# Spec: github-local-mirror-sync

## Goal

Verify that a GitHub-to-local sync leaves the selected local directory as an
exact mirror of the selected remote repository path.

## Preconditions

- Run the `dev` flavor.
- Dev authorization, repository, and branch selection use the deterministic
  fixtures.
- Real `stg` and `prod` syncs use GitHub Repository Contents API responses.

## Steps

1. Launch the app and complete GitHub authorization.
2. Select a repository and branch.
3. Tap Sync.
4. Wait for the mirror-complete success state.

Mirrored as machine-checkable items in `acceptance.yaml`.

## Mirror Behavior

- Sync downloads all files from the selected remote repository or subdirectory
  and overwrites local files at the same relative paths.
- After a successful remote read, files, links, and directories that do not
  exist remotely are removed only from the selected local directory.
- A local file-versus-remote-directory or local-directory-versus-remote-file
  collision resolves to the remote type.
- If any remote listing or file download fails, the cleanup phase never starts,
  so previously local-only files remain in place.
- The result text reports both the number of downloaded files and locally
  cleared residual entries. An already matching empty directory reports
  no changes.

## Translation Rules

- Prefer `semantics_identifier` from `docs/harness/specs/ui-map.yaml`.
- Do not invent labels or targets.
- If a step cannot be mapped to a known target, report `BLOCKED`.
