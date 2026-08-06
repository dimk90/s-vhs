# Release Instructions

1. Finalize the release documentation:
   - replace `Unreleased` for the version in `CHANGELOG.md` with the release
     date in `DD.MM.YYYY` format;
   - remove the completed version section from `doc/PLAN.md`, leaving future
     work in the roadmap;
   - verify that README commands, examples and the recording template are
     current.

1. Point every literal pinned remote import URL at the tag being released — in
   `README.md` and in `examples/remote-import.rec.sh`.

1. Bump the version literal in `svhs_version`.

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

1. Push `master` and only the target tag atomically. Do not publish anything if
   this push fails:

   ```bash
   git push --atomic origin master refs/tags/v0.?.?
   ```

1. Wait for the `Publish GitHub release` workflow to complete. Verify that the
   versioned Pages import and `latest` serve the released library, and that the
   published release has the target tag and title.
   Do not create the release manually if the workflow fails.

1. Return to the `develop` branch:

   ```bash
   git switch develop
   ```

1. Verify that the pinned remote import URL now resolves, using the exact import
   form the README documents:

   ```bash
   bash -c 'source <(curl -fsSL https://dimk90.github.io/s-vhs/v0.?.?) && wait "$!" || exit 1; svhs_version'
   ```
