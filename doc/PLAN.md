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
- [ ] Implement `RunOffRecord` as `Hide` + `Run` + `Show`:
  - A convenient way to run one short command in between `Start` & `Hide/Render`;
  - [ ] Add example.
- [ ] Use a dedicated tmux socket (`tmux -L s-vhs ...`) for the recording session:
      `extended-keys` and `extended-keys-format` are server options, so the
      current `tmux set -g` in `Start` also changes them on the user's own
      running tmux server.
  - [ ] Every tmux call takes the socket, `_svhs_cleanup` included — a cleanup
        left on the default socket kills the user's own session when it shares
        the configured name, which is also why the `EXIT` trap is installed on
        the sourced path only.
  - [ ] Fixes config inheritance too: `tmux -f /dev/null` applies only when the
        server is *created*, so a recording that joins an already running server
        silently inherits the user's `tmux.conf`. The s-vhs server still stays
        shared between recordings, environment included (see the `Env` warning
        in [COMMANDS](COMMANDS.md#env-)).
- [ ] Stop `_svhs_cleanup` from killing a session it did not create: it runs
      `tmux kill-session -t "$_SVHS_SESSION"` unconditionally, so any exit
      before `Start` — a failed setter, a duplicate-session `Start`, or merely
      sourcing `s-vhs.sh` — kills the user's own session of that name.
      Reproduced: with a `demo` session alive, a default-named recording prints
      `duplicate session: demo`, exits 1, and takes the existing session down.
  - [ ] Guard the handler with `_SVHS_STARTED`.
  - [ ] Retires the trap placement: once cleanup is guarded, the `EXIT` trap no
        longer has to be restricted to the sourced path. The executed-mode guard
        stays — it is the `new` entry point, unrelated to tmux.
  - [ ] Report the collision in `Start` and point at `SetSession`, instead of
        letting tmux's `duplicate session: demo` through.
- [ ] Make the default session name unique (e.g. `s-vhs-$$`), so two recordings
      run in parallel without `SetSession`. The name is invisible with the
      status bar off, and `SetSession` stays for attaching by name. Verified:
      parallel recordings already work as soon as the names differ.
- [ ] Option to isolate the recorded shell from the user's rc files
      (`bash --norc`, `fish --no-config`, ...):
  - The session inherits `~/.bashrc`, so a recording shows the author's prompt
    (starship, git status, ...) and aliases — it is not reproducible on another
    machine, and a demo GIF leaks unrelated prompt content.
  - [ ] Pick the API: a `SetPrompt <system|theme1|theme2|...>` with a few named themes (plain,
        arrow, powerline, path+git), or a value passed straight through as a
        PS1 string.
  - [ ] Options: keep inheriting, add a `SetShell 'bash --norc'` recipe to the docs
    only, or add an explicit setting (e.g. `SetPrompt <system|theme1|theme2|...>`) 
    that maps to the right flag per shell.
  - [ ] Per-shell mapping: bash `PS1`, zsh `PROMPT`, fish `fish_prompt` — the
        env-var trick only works for the first two.
  - [ ] Bundle colourful prompt themes, so a recording does not need the
      `SetShell "env PS1='\[\e[32m\]❯\[\e[0m\] ' bash --norc"` incantation every
      example repeats today.
  - [ ] Add clear vs non-clean shell example to README.
  - [ ] Update all examples to use `SetPrompt` instead of `SetShell "env PS1='\[\e[32...`.
  - [ ] Update shell to `fish` for all examples and re-render GIFs.
- [ ] Remote import:
  - [ ] Add example with nice one-liner for `curl+source` remote import s-vhs from: `https://github.../v0.1.0/.../s-vhs.sh`.
  - [ ] Add it to the README -> "Remote Import".
  - [ ] Scaffold without a local copy:
        `curl -fsSL https://.../v0.1.0/.../s-vhs.sh | bash -s -- new demo.rec.sh`.
        Works already — piped input leaves `BASH_SOURCE` unset, which the
        executed-mode guard treats as execution.
  - [ ] Decide which import line that scaffold writes: the template's
        `source ./s-vhs.sh` assumes a local copy the remote user does not have,
        so it should probably emit the pinned `curl+source` one-liner instead.
- [ ] Update `pi-context-view` recordings + add reference to the `s-vhs`.
  - [ ] Add example "S-VHS in the Wild" to README.

## v0.3.0

- [ ] Make list of planned function which are easy to implement:
  - [ ] Add `Sleep` as alias for `sleep`.
  - [ ] function ...
  - [ ] ...
- [ ] Update existing examples and README if needed.
- [ ] Rename EXAMPLES.md to examples/README.md ?
- [ ] Check which examples could be implemented with the current version of `s-vhs.sh`:
  - https://github.com/charmbracelet/vhs/tree/main/examples/settings
  - https://github.com/charmbracelet/vhs/tree/main/examples/commands
- [ ] Implement animated SVG output format.
  - [ ] Update readme header with one more bullet:
    ```Markdown
    - **Animated SVG output**
      ([#644](https://github.com/charmbracelet/vhs/discussions/644),
      [#109](https://github.com/charmbracelet/vhs/issues/109),
      [#105](https://github.com/charmbracelet/vhs/issues/105)).
    ```
  - [ ] Update installation instructions and dependencies description.
  - [ ] Re-render all examples to animated SVG?
- [ ] Write advanced example with emulating mouse selection.
  - [ ] Add new commands to [COMMANDS](doc/COMMANDS.md) if possible: e.g `Highlight`.
  - [ ] Add feature + issue ref (https://github.com/charmbracelet/vhs/issues/66) to README;
  - [ ] Add demo to README.
- [ ] Publish link in the related VHS issues.
- [ ] Update template (`s-vhs new`) with common settings (if any new).


## v0.4.0

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
- [ ] Add custom agg themes:
  - [ ] my spaceship theme.
  - [ ] tokyo-night theme.
  - [ ] catppuccin themes.
  - [ ] Add example with custom theme (hex colors).
