# Plan

## v0.2.0

- [x] Implement `Env` command:
  - [x] Make it compatible with `bash`, `fish` and `zsh`;
  - [x] Update `Run "PS1='\[\e[32m\]❯\[\e[0m\] '"` to `Env` for all examples;
- [x] Fix `Show` after `Hide`: the second `Show` passes `--append` next to the
      always-present `--overwrite`, and asciinema rejects that combination
      (`error: the argument '--overwrite' cannot be used with '--append'`), so
      a multi-segment recording dies at the second `Show`.
  - [x] The flags are exclusive: `--overwrite` for the first segment,
        `--append` for every later one. The Show/Hide row in
        [COMMANDS](COMMANDS.md) stays ✅.
  - [x] Keep the closing frame of a hidden segment: a segment ends at its last
        event, so a pause held before `Hide` was dropped and the frame flashed
        by. `Hide` repaints the client first, which stamps that idle time into
        the cast.
  - [x] Extend the `hide-show` example to a second `Show`.
- [x] Implement `RunOffRecord` as `Hide` + `Run` + `Show`:
  - A convenient way to run one short hidden command in between `Start` & `Hide/Render`;
  - [x] Add example.
- [x] Use a dedicated tmux socket (`tmux -L s-vhs ...`) for the recording session:
      `extended-keys` and `extended-keys-format` are server options, so the
      current `tmux set -g` in `Start` also changes them on the user's own
      running tmux server.
  - [x] Every tmux call takes the socket, `_svhs_cleanup` included — a cleanup
        left on the default socket kills the user's own session when it shares
        the configured name, which is also why the `EXIT` trap is installed on
        the sourced path only.
  - [x] Fixes config inheritance too: `tmux -f /dev/null` applies only when the
        server is *created*, so a recording that joins an already running server
        silently inherits the user's `tmux.conf`. The s-vhs server still stays
        shared between recordings, environment included.
- [x] Stop `_svhs_cleanup` from killing a session it did not create: it runs
      `tmux kill-session -t "$_SVHS_SESSION"` unconditionally, so any exit
      before `Start` — a failed setter, a duplicate-session `Start`, or merely
      sourcing `s-vhs.sh` — kills the user's own session of that name.
      Reproduced: with a `demo` session alive, a default-named recording prints
      `duplicate session: demo`, exits 1, and takes the existing session down.
  - [x] Guard the handler with `_SVHS_STARTED`.
  - [x] Retires the trap placement: once cleanup is guarded, the `EXIT` trap no
        longer has to be restricted to the sourced path. The executed-mode guard
        stays — it is the `new` entry point, unrelated to tmux.
  - [x] Report the collision in `Start` and point at `SetSession`, instead of
        letting tmux's `duplicate session: demo` through.
  - [x] Make the default session name unique (e.g. `s-vhs-$$`), so two recordings
        run in parallel without `SetSession`. The name is invisible with the
        status bar off, and `SetSession` stays for attaching by name. Verified:
        parallel recordings already work as soon as the names differ.
      -  [x] Report session name.
- [x] Option to isolate the recorded shell from the user's rc files
      (`bash --norc`, `fish --no-config`, ...):
  - The session inherits `~/.bashrc`, so a recording shows the author's prompt
    (starship, git status, ...) and aliases — it is not reproducible on another
    machine, and a demo GIF leaks unrelated prompt content.
  - The option to make a record with user's prompt/shell setting must be preserved.
  - [x] Discus pros & cons of API like `SetPrompt <system|theme1|theme2|...|custom str>`
  - [x] The `SetPrompt 'native'` disables isolation and records the terminal
        with the user's settings (no `--norc`).
  - [x] The `SetPrompt` with a theme or a literal applies isolation (`--norc`).
    - [x] `native` over `system`: `--norc` skips the *user's* rc files, and
          `/etc` still applies to a login shell.
  - [x] Restricted to `SetShell <bash|zsh|fish>`, with a fallback to `bash`
        when the named shell is not installed.
  - [x] Per-shell mapping: bash `PS1`, zsh `PROMPT`, fish `fish_prompt` — the
        env-var trick only works for the first two, so fish takes its prompt
        as a `-C` function on the command line.
  - [x] Bundle colourful prompt themes, so a recording does not need the
      `Env PS1 '\[\e[32m\]❯\[\e[0m\] '` +  `SetShell "bash --norc"` incantation every
      example repeated.
      - [x] Named themes: `arrow` (default), `plain`, `path`, `powerline`;
            any other value is passed through as a literal prompt.
  - [x] Keep the recording out of the user's shell history: `HISTFILE=` for
        bash and zsh, `--private` for fish. Not `+o history`, which also kills
        recall *inside* the recording, so a `Key C-r` demo would show nothing.
  - [x] Add shell theme example.
  - [x] Update all examples to use `SetPrompt`.
- [x] Implement `Enter`, `Tab`, `Up`, … (named keys).
  - [x] VHS's 15 names, each a one-line wrapper over `Key`, so a count and a
        delay still apply (`Enter 4 0.5`); modified keys stay with `Key C-r`.
  - [x] Update examples and README.
- [x] Add `Sleep` as alias for `sleep` to match style of the `s-vhs`:
   - [x] Update examples.
- [x] Remote import research:
  - [x] Discuss how to do remote import for current repo with specified version (e.g. v0.2.0).
    - [x] Pin the raw URL at the tag,
          `https://raw.githubusercontent.com/dimk90/s-vhs/v0.2.0/s-vhs.sh`. It
          exists the moment the tag does — no release asset to upload, no
          second publishing surface. A shorter Pages URL is in the backlog.
    - [x] Import with `source <(curl -fsSL …)`, not `eval "$(curl …)"`:
          inside `eval` the caller's `BASH_SOURCE[0]` is still `$0`, so the
          executed-mode guard misfires and prints `usage: s-vhs.sh new [path]`.
          Process substitution reads as a sourced path.
    - [x] A failed or truncated fetch is silent — `source <(…)` returns 0 and
          the recording runs on with every command undefined, so the documented
          form needs a guard line.
  - [x] Release step: point the pinned URL at the tag being released before
        cutting it, and verify it resolves afterwards — in [RELEASE](RELEASE.md).
- [ ] Shorten the remote import URL with GitHub Pages:
      `https://dimk90.github.io/s-vhs/v0.2.0` (37 chars) instead of
      `https://raw.githubusercontent.com/dimk90/s-vhs/v0.2.0/s-vhs.sh` (62).
      No trailing `/s-vhs.sh` — the name is already in the middle of the URL.
  - Pages publishes one snapshot of one branch and cannot read tags (its Jekyll
    allows no custom plugins), so every version must exist as a file: the
    release workflow copies `s-vhs.sh` to `deploy` as `v<X.Y.Z>`, plus a
    `latest` alias. Extensionless files are served verbatim as
    `application/octet-stream` — `dimk90.github.io/anarchy/wipe-disk` proves it.
  - [x] Document the deployment strategy and initialization in
        [DEPLOY](DEPLOY.md).
  - [ ] Initialize the orphan `deploy` branch with a `.nojekyll` marker and the
        existing release files.
  - [ ] Enable Pages: Settings → Pages → Deploy from a branch → `deploy` /
        `(root)`.
  - [ ] Add the copy step to `release.yml`; it already has `contents: write`.
        Preserve old versions and update `latest` without force-pushing. Deploy
        from a branch, not `actions/deploy-pages`, which replaces the whole site
        per run and would drop older versions.
  - [ ] Land it any time: the raw URLs of released versions keep working.
  - [x] Weigh the cost first — a deploy that fails after the tag lands leaves
        the release's own README pointing at a 404.
- [ ] Remote import:
  - [ ] Add example with nice one-liner for `curl+source` remote import s-vhs from: `https://github.../v0.1.0`.
  - [ ] Add it to the README -> "Remote Import".
  - [ ] Scaffold without a local copy via `https://github.../v0.1.0`.
  - [ ] Decide which import line that scaffold writes: the template's
        `source ./s-vhs.sh` assumes a local copy the remote user does not have,
        so it should probably emit the pinned `curl+source` one-liner instead.
- [ ] Update `pi-context-view` recordings + add reference to the `s-vhs`.
  - [ ] Add example "S-VHS in the Wild" to README.
- [ ] Is it reasonable to have skill for `s-vhs` ?

## v0.3.0

- [ ] Implement animated SVG output format.
  - [ ] Update readme header with one more bullet:
    ```Markdown
    - **Animated SVG output**
      ([#644](https://github.com/charmbracelet/vhs/discussions/644),
      [#109](https://github.com/charmbracelet/vhs/issues/109),
      [#105](https://github.com/charmbracelet/vhs/issues/105)).
    ```
  - [ ] Update installation instructions and dependencies description.
  - [ ] README - agg is listed as a flat requirement, but it is only needed for GIF output; a
        .cast-only recording never invokes it. Worth marking as "for GIF output".
- [ ] Re-render all examples to animated SVG?

## v0.4.0

- [ ] Make list of planned function which are easy to implement:
  - [ ] function ...
  - [ ] ...
- [ ] Update existing examples and README if needed.
- [ ] Check which examples could be implemented with the current version of `s-vhs.sh`:
  - https://github.com/charmbracelet/vhs/tree/main/examples/settings
  - https://github.com/charmbracelet/vhs/tree/main/examples/commands
- [ ] Write advanced example with emulating mouse selection.
  - [ ] Add new commands to [COMMANDS](doc/COMMANDS.md) if possible: e.g `Highlight`.
  - [ ] Add feature + issue ref (https://github.com/charmbracelet/vhs/issues/66) to README;
  - [ ] Add demo to README.
- [ ] Publish link in the related VHS issues.
- [ ] Update template (`s-vhs new`) with common settings (if any new).


## Backlog

- [ ] Fix default font problem: `Error: no faces matching font family options`.
  - `agg` bundles only the symbol and emoji fallbacks; the primary monospace
    text font must resolve from the system, so a host without any of agg's
    default families (`JetBrains Mono`, `Fira Code`, `SF Mono`, `Menlo`,
    `Consolas`, `DejaVu Sans Mono`, `Liberation Mono`) fails before rendering.
  - [ ] When the font family is unset, check whether one of agg's default
        families is available in the system; if so, pass nothing and keep agg's
        own chain.
  - [ ] If none is available, set the font to the first available monospace
        font. Skip bitmap-only faces (`.otb`, `.pcf`) — agg cannot use them,
        e.g. `Terminus` fails the same way as a missing font.
  - [ ] Remove `Iosevka Term` from examples.
- [ ] Add `SetPadding X` function.
- [ ] Rended visualization for all available themes.
- [ ] MP4 output (same `.cast`, different renderer):
  - [ ] MP4 — render with `ffmpeg`?
- [ ] Improve default fish colors: commands and completion colors, bold commands,...
  - [ ] Update shell to `fish` for all examples and re-render GIFs.
  - [ ] Add custom agg themes:
  - [ ] my spaceship theme.
  - [ ] tokyo-night theme.
  - [ ] catppuccin themes.
  - [ ] Add example with custom theme (hex colors).
- [ ] Add a `git` theme (bash/zsh command substitution, fish `__fish_git_prompt`)?
