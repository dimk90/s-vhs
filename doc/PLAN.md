# Plan

## v0.1.0

- [x] Remove current implementation of padding functionality from `s-vhs.sh`.
  - [x] Save to `doc/HISTORY.md`.
- [x] Select minimal subset of functions which already implemented or easy to add;
- [x] Function names should be intuitive and similar to VHS.
- [x] Decide on using only functions or functions+variables.
- [x] Change existing variables to functions: [COMMANDS](doc/COMMANDS.md).
- [x] Decision about <time> and <repetition> argument.
- [x] Implement minimal example for README#Quick_Start.
  - [x] Add it to `example`.
- [x] Fix the font fallback chain in `render`:
  - [x] Pass the `SetFontFamily` value as agg `--text-font-family`; the current
        `--font-family` bypasses the bundled Symbols Nerd Font and emoji
        fallbacks, so Nerd Font glyphs and emoji render as tofu.
  - [x] Keep the bypassing form as a separate opt-in setting
        (`SetFontFamilyExact`), see [COMMANDS](doc/COMMANDS.md#font-stack-).
  - [x] Generate `test` to confirm the glyphs are back.
- [x] Refactor implemented `s-vhs.sh` functions to target format [COMMANDS](doc/COMMANDS.md).
  - [x] Add repeat count to `Key <key> [<count>] [<delay>]`.
- [x] Add `_svhs_` prefix to private functions.
- [x] Fix TODOs in the `s-vhs.sh`.
- [x] Add version number, copyright and git repo link to `s-vhs.sh` header:
  - [x] Check what is the best way to to keep version number inside `s-vhs.sh`.
        Kept as a literal in `svhs_version` (`## Version` section); prefixed
        rather than a VHS-like command name.
  - [x] Set version to `0.1.0`.
  - [x] Add it to `doc/COMMANDS.md` and `doc/REFERENCE.md` if needed.
- [x] Make `s-vhs.sh` compatible with macOS bash (3.2):
  - [x] Check if it's really important for macOS users. Is 3.2 version still common?
        Yes — every macOS release still ships 3.2.57 as `/bin/bash`; zsh only
        replaced it as the default login shell. Full 3.2 support it is.
  - [x] Guard empty-array expansion under `set -u` (`"${arr[@]}"` is an
        unbound variable error before bash 4.4 — hits `font_args` in `render`).
        Also affected the empty-output check in `Start`.
  - [x] Replace GNU-only `truncate -s` (absent on stock macOS).
        Now `_svhs_truncate`, built on `head -c` plus a replacing `mv`.
  - [x] Check fractional `sleep` and other coreutils assumptions on BSD tools.
        Nothing else to fix: macOS `sleep` takes any `strtod` value, and a bare
        `mktemp` behaves as `mktemp -t tmp` there.
  - [x] No bash 4+ syntax is used today — keep it that way (no `declare -A`,
        `mapfile`, `${var,,}`, `&>>`, namerefs). Recorded in `AGENTS.md`.
- [x] Add check for missing dependencies: tmux, agg (if output set to GIF), ... to session start function.
  - [x] `Start` checks `tmux` and `asciinema` always, `agg` only when a `.gif`
        output is requested, so a cast-only recording needs no renderer.
- [x] Draft template for recording script: with most common settings (commented).
      A bare starting point: one active `SetOutput`, the common settings
      commented out with their defaults, minimal body.
  - [x] Add it to README;
  - [x] Scaffold it with `svhs_new <path>`, like `vhs new demo.tape`. The
        heredoc in `s-vhs.sh` is the source of truth — the README block is the
        only other copy, `examples/` keeps none.
  - [x] Reach it without sourcing: executing `s-vhs.sh` dispatches its only
        subcommand (`s-vhs.sh new demo.rec.sh`), which also works piped
        (`curl … | bash -s -- new demo.rec.sh`) for v0.2.0 remote import.
        The `EXIT` trap moved to the sourced path — scaffolding must not kill
        a tmux session that happens to share the default name.
- [ ] Implement basic examples:
  - [ ] Check which examples could be implemented with the current version of `s-vhs.sh`:
    - https://github.com/charmbracelet/vhs/tree/main/examples/settings
    - https://github.com/charmbracelet/vhs/tree/main/examples/commands
  - [ ] Create table of examples (name + description + checkbox for planned) and put to `doc`.
  - [ ] Ask me to mark examples to implement.
  - [ ] Write/Implement recording scripts for examples and put to `examples`.
  - [ ] Run recording scripts and generate GIFs, put it to `examples/images`.
- [ ] Publish to the github.
- [ ] Update `pi-context-view` recordings + add reference to the `s-vhs`.


## v0.2.0

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
- [ ] Fix `Show` after `Hide`: the second `Show` passes `--append` next to the
      always-present `--overwrite`, and asciinema rejects that combination
      (`error: the argument '--overwrite' cannot be used with '--append'`), so
      a multi-segment recording dies at the second `Show`.
  - [ ] Mark the Show/Hide row in [COMMANDS](doc/COMMANDS.md) 🟡 until fixed.
- [ ] Decide on isolating the recorded shell from the user's rc files
      (`bash --norc`, `fish --no-config`, ...):
  - The session inherits `~/.bashrc`, so a recording shows the author's prompt
    (starship, git status, ...) and aliases — it is not reproducible on another
    machine, and a demo GIF leaks unrelated prompt content.
  - Against: VHS behaves the same way, and a dotfiles/prompt demo *wants* the
    real config; a bare `--norc` prompt (`bash-5.3$`) looks worse by default.
  - Options: keep inheriting, add a `SetShell 'bash --norc'` recipe to the docs
    only, or add an explicit setting (e.g. `SetCleanShell`) that maps to the
    right flag per shell.
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
- [ ] Make list of planned function which are easy to implement:
  - [ ] function ...
  - [ ] ...
- [ ] Check which examples could be implemented with the current version of `s-vhs.sh`:
  - https://github.com/charmbracelet/vhs/tree/main/examples/settings
  - https://github.com/charmbracelet/vhs/tree/main/examples/commands


## v0.3.0

- [ ] Implement animated SVG output format.
  - [ ] Update readme header with one more bullet:
    ```Markdown
    - **Animated SVG output**
      ([#644](https://github.com/charmbracelet/vhs/discussions/644),
      [#109](https://github.com/charmbracelet/vhs/issues/109),
      [#105](https://github.com/charmbracelet/vhs/issues/105)).
    ```
- [ ] Write advanced example with emulating mouse selection.
  - [ ] Add new commands to [COMMANDS](doc/COMMANDS.md) if possible: e.g `Highlight`.
  - [ ] Add feature + issue ref (https://github.com/charmbracelet/vhs/issues/66) to README;
- [ ] Publish link in the related VHS issues.


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
- [ ] Add `SetPadding X` function.
- [ ] Rended visualization for all available themes.
- [ ] MP4 output (same `.cast`, different renderer):
  - [ ] MP4 — render with `ffmpeg`?
