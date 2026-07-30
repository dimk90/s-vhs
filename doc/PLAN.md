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
- [ ] Refactor implemented `s-vhs.sh` functions to target format [COMMANDS](doc/COMMANDS.md).
- [ ] Add version number and link to git repo to `s-vhs.sh`:
  - Check what is the best way to to keep version number inside `s-vhs.sh`.
  - Set version to `0.1.0`.
  - Add it to `doc/COMMANDS.md` if needed.
- [ ] Fix the font fallback chain in `render`:
  - [ ] Pass the `SetFontFamily` value as agg `--text-font-family`; the current
        `--font-family` bypasses the bundled Symbols Nerd Font and emoji
        fallbacks, so Nerd Font glyphs and emoji render as tofu.
  - [ ] Keep the bypassing form as a separate opt-in setting
        (`SetFontFamilyExact`), see [COMMANDS](doc/COMMANDS.md#font-stack-).
  - [ ] Generate `test` to confirm the glyphs are back.
- [ ] Make `s-vhs.sh` compatible with macOS bash (3.2):
  - [ ] Check if it's really important for macOS users.
  - [ ] Guard empty-array expansion under `set -u` (`"${arr[@]}"` is an
        unbound variable error before bash 4.4 — hits `font_args` in `render`).
  - [ ] Replace GNU-only `truncate -s` (absent on stock macOS).
  - [ ] Check fractional `sleep` and other coreutils assumptions on BSD tools.
  - [ ] No bash 4+ syntax is used today — keep it that way (no `declare -A`,
        `mapfile`, `${var,,}`, `&>>`, namerefs).
- [ ] Improve examples:
  - [ ] Add nice one-liner for `curl+source` remote import s-vhs from: `https://github.../v0.1.0/.../s-vhs.sh`.
  - [ ] Record GIF and add it to the README.
- [ ] Add check for missing dependencies: tmux, agg (if output set to GIF), ... to session start function.
- [ ] Implement basic examples:
  - [ ] Check which examples could be implemented with the current version of `s-vhs.sh`:
    - https://github.com/charmbracelet/vhs/tree/main/examples/settings
    - https://github.com/charmbracelet/vhs/tree/main/examples/commands
  - [ ] Create table of examples (name + description + checkbox for planned) and put to `doc`.
  - [ ] Ask me to mark examples to implement.
  - [ ] Write/Implement recording scripts for examples and put to `examples`.
  - [ ] Run recording scripts and generate GIFs, put it to `doc/images`.
- [ ] Draft template for recording scrip: with most common settings (commented).
- [ ] Publish to the github.
- [ ] Update `pi-context-view` recordings + add reference to the `s-vhs`.


## v0.2.0

  - [ ] Make list of planned function which are easy to implement:
    - [ ] function ...
    - [ ] ...
  - [ ] Check which examples could be implemented with the current version of `s-vhs.sh`:
    - https://github.com/charmbracelet/vhs/tree/main/examples/settings
    - https://github.com/charmbracelet/vhs/tree/main/examples/commands


## v0.3.0

  - [ ] Implement animated SVG output format.
  - [ ] Write advanced example with emulating mouse selection.
    - [ ] Add new commands to [COMMANDS](doc/COMMANDS.md) if possible: e.g `Highlight`.
    - [ ] Add feature + issue ref (https://github.com/charmbracelet/vhs/issues/66) to README;
- [ ] Publish link in the related VHS issues.


## v0.4.0

- [ ] Add `SetPadding X` function.
- [ ] Rended visualization for all available themes.
- [ ] MP4 output (same `.cast`, different renderer):
  - [ ] MP4 — render with `ffmpeg`?


## Undecided

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
