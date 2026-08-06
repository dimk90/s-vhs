# Release Instructions

Release from `develop`, merge the reviewed release commit into `master`, and tag
the resulting `master` commit. Pushing a stable `vX.Y.Z` tag starts the
`Publish GitHub release` workflow. It publishes the versioned Pages import and
`latest`, verifies the public file, then publishes the matching `CHANGELOG.md`
section as the GitHub release notes.

1. Finalize the release documentation:
   - replace `Unreleased` for the version in `CHANGELOG.md` with the release
     date in `DD.MM.YYYY` format;
   - make the changelog entries match the user-visible release notes;
   - remove the completed version section from `doc/PLAN.md`, leaving future
     work in the roadmap;
   - check that `doc/REFERENCE.md` and `doc/COMMANDS.md` match the shipped
     commands;
   - verify that README commands, examples and the recording template are
     current.

1. Point every literal pinned remote import URL at the tag being released — in
   `README.md` and in `examples/`. The `_SVHS_TEMPLATE` URL derives its version
   from `svhs_version`, so the version bump below updates it automatically. The
   tag does not exist yet, so these URLs stay broken until the push; they are
   verified at the end.

   ```bash
   rg -n '(raw\.githubusercontent\.com/dimk90/s-vhs|dimk90\.github\.io/s-vhs)/v[0-9]' README.md s-vhs.sh doc examples
   ```

1. Bump the version literal in `svhs_version` (`## Version` in `s-vhs.sh`). It
   is the only place the version number is written, and the release workflow
   rejects a tag that disagrees with it.

1. Review and validate the release tree:

   ```bash
   shellcheck s-vhs.sh
   ```
   ```bash
   ./s-vhs.sh new /tmp/release-check.rec.sh && bash -n /tmp/release-check.rec.sh
   ```

1. Re-render every example whose output changed, and replay each rendered file
   before committing it.

1. Commit only the reviewed release files, following the repository's release
   commit convention. Add `examples/` output only if its reviewed rendering
   changed.

   ```bash
   git add CHANGELOG.md doc/PLAN.md README.md s-vhs.sh
   ```
   ```bash
   git commit -m "[doc] Release v0.?.?"
   ```
   ```bash
   git push origin develop
   ```

1. Update `master`, merge `develop`, and validate the exact release tree again:

   ```bash
   git switch master
   ```

   ```bash
   git pull --ff-only origin master
   ```

   ```bash
   git merge --no-ff develop
   ```

1. Tag the tested `master`:

   ```bash
   git tag v0.?.?
   ```

1. Verify the version, tag target, and clean worktree:

   ```bash
   bash -c 'source ./s-vhs.sh; svhs_version'
   ```
   ```bash
   git status --short && git log --oneline -1 && git show --oneline -s v0.?.?
   ```

1. Push `master` and only the target tag atomically. Do not publish anything if
   this push fails:

   ```bash
   git push --atomic origin master refs/tags/v0.?.?
   ```

1. Wait for the `Publish GitHub release` workflow to complete. Verify that the
   versioned Pages import and `latest` serve the released library, and that the
   published release has the target tag and title, the exact target changelog
   section as its notes, and the tested merge commit as its tag target. Do not
   create the release manually if the workflow fails.

1. Verify that the pinned remote import URL now resolves, using the exact import
   form the README documents:

   ```bash
   bash -c 'source <(curl -fsSL https://dimk90.github.io/s-vhs/v0.?.?) && wait "$!" || exit 1; svhs_version'
   ```

1. Return to the `develop` branch:

   ```bash
   git switch develop
   ```
