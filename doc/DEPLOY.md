# GitHub Pages Deployment

GitHub Pages provides short, versioned remote-import URLs:

```text
https://dimk90.github.io/s-vhs/v0.2.0
```

The final path is the version itself. It does not end in `/s-vhs.sh` because
`s-vhs` is already part of the project URL.

## Strategy

Publish from a dedicated orphan branch named `deploy`. The branch is independent
of `develop` and `master`; never merge it into either one. It contains only the
files served by Pages:

```text
.nojekyll
latest
v0.1.0
v0.2.0
...
```

Each extensionless `vX.Y.Z` file is an exact copy of `s-vhs.sh` from that tag.
Released version files are immutable: publication must fail rather than replace
an existing version with different content. `latest` is replaced on every
stable release.

Pages publishes one branch snapshot and cannot read files directly from Git
tags. The release workflow therefore copies each tagged `s-vhs.sh` into
`deploy`, preserving all earlier versions. Use Pages' **Deploy from a branch**
source, not `actions/deploy-pages`, whose artifact replaces the whole site on
every deployment.

The `.nojekyll` marker disables unnecessary Jekyll processing and makes Pages
serve these files verbatim. The site deliberately has no landing page, so the
root URL may return 404 even when a version URL works.

## Initialize the Branch

Fetch the existing stable tags. If the worktree contains uncommitted changes,
stash them first; `push` here means saving them to Git's local stash stack,
not pushing them to GitHub:

```bash
git fetch origin --tags
git stash push --include-untracked -m 'Before initializing Pages' # omit if clean
```

Create the orphan branch and seed it with the existing release, a matching
`latest` alias, and the Jekyll marker:

```bash
git switch --orphan deploy

touch .nojekyll
git show v0.1.0:s-vhs.sh > v0.1.0
cp v0.1.0 latest

git add .nojekyll v0.1.0 latest
git commit -m "[ci] Initialize Pages deploy branch"
git push -u origin deploy
```

Return to `develop` and restore the stashed changes, if any:

```bash
git switch develop
git stash pop # omit if no stash was created
```

Use `git stash pop --index` instead when the previous staged/unstaged state must
be restored exactly. Do not force-push over an existing `deploy` branch.

## Configure GitHub Pages

After the `deploy` branch exists on GitHub:

1. Open the repository's **Settings → Pages** page:
   <https://github.com/dimk90/s-vhs/settings/pages>.
2. Under **Build and deployment**, select **Deploy from a branch** as the
   source.
3. Select the `deploy` branch and `/ (root)` folder, then click **Save**.
4. Wait for the `pages-build-deployment` run in the repository's **Actions**
   tab to finish.
5. Keep **Enforce HTTPS** enabled. No custom domain or `_config.yaml` is needed.

The published project-site prefix remains
`https://dimk90.github.io/s-vhs/`; the branch name does not appear in it.

Verify the seeded release rather than the intentionally empty site root:

```bash
curl -fsSL https://dimk90.github.io/s-vhs/v0.1.0 -o /tmp/s-vhs-v0.1.0
cmp /tmp/s-vhs-v0.1.0 <(git show v0.1.0:s-vhs.sh)
rm /tmp/s-vhs-v0.1.0
```

## Release Publication

`.github/workflows/release.yml` publishes Pages before creating the GitHub
release:

1. Validate the stable `vX.Y.Z` tag and `svhs_version`.
2. Read the current `deploy` branch without force-pushing.
3. Copy the tagged `s-vhs.sh` to the extensionless path named by the tag.
4. Fail if that path already exists with different content; do nothing if it
   already contains the same content.
5. Replace `latest` with the same file.
6. Commit both files to `deploy` while preserving every earlier version.
7. Explicitly request a Pages build and wait for it to finish.
8. Verify that the public version URL serves the exact released bytes.
9. Create the GitHub release from the matching changelog section.

GitHub does not trigger a branch-based Pages build when `GITHUB_TOKEN` pushes
the source commit. The workflow therefore declares both `contents: write` for
the branch update and `pages: write` for the explicit build request.

All releases share one workflow concurrency group, so different tags cannot
race while updating `deploy`. Rerunning an older release verifies its pinned
file without moving `latest` backwards. Do not protect the branch in a way that
prevents the release workflow from updating it.
