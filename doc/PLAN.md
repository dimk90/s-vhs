# Plan

## v0.1.0

- [ ] Implement basic recording functions:
  - [x] Select minimal subset of functions which already implemented or easy to add;
  - [x] Function names should be intuitive and similar to VHS.
  - [x] Decide on using only functions or functions+variables.
  - [ ] Change existing variables to functions: [COMMANDS](doc/COMMANDS.md).
  - [ ] Refactor implemented `s-vhs.sh` functions to target format [COMMANDS](doc/COMMANDS.md).
- [ ] Add version number to the `s-vhs.sh`:
  - Check what is the best way to to keep version number inside `s-vhs.sh`.
  - Set version to `0.1.0`.
  - Add it to `doc/COMMANDS.md` if needed.
- [ ] Remove current implementation of padding functionality from `s-vhs.sh`.
  - Save to `doc/HISTORY.md`.
- [ ] Make `s-vhs.sh` compatible with macOS bash (3.2):
  - [ ] Guard empty-array expansion under `set -u` (`"${arr[@]}"` is an
        unbound variable error before bash 4.4 — hits `font_args` in `render`).
  - [ ] Replace GNU-only `truncate -s` (absent on stock macOS).
  - [ ] Check fractional `sleep` and other coreutils assumptions on BSD tools.
  - [ ] No bash 4+ syntax is used today — keep it that way (no `declare -A`,
        `mapfile`, `${var,,}`, `&>>`, namerefs).
- [ ] Implement minimal example for README#Quick_Start.
  - Add nice one liner for `curl+source` remote import s-vhs from: `https://github.../v0.1.0/.../s-vhs.sh`.
- [ ] Add check for missing dependencies: tmux, agg (if output set to GIF), ...
- [ ] Implement basic examples:
  - [ ] Check which examples could be implemented with the current version of `s-vhs.sh`:
    - https://github.com/charmbracelet/vhs/tree/main/examples/settings
    - https://github.com/charmbracelet/vhs/tree/main/examples/commands
  - [ ] Create table of examples (name + description + checkbox for planned) and put to `doc`.
  - [ ] Ask me to mark examples to implement.
  - [ ] Write/Implement recording scripts for examples and put to `examples`.
  - [ ] Run recording scripts and generate GIFs, put it to `doc/images`.
- [ ] Implement animated SVG output format.
- [ ] Write advanced example with emulating mouse selection.
- [ ] Draft template for recording scrip: with all available setting (commented).
- [ ] Publish link to the project in related VHS issues.


## v0.2.0

- [ ] Add `SetPadding X` function.
- [ ] Rended visualization for all available themes.
- [ ] MP4 output (same `.cast`, different renderer):
  - [ ] Animated SVG — use `termsvg`; `svg-term-cli` pulls in Node.
  - [ ] MP4 — render with `ffmpeg`.
  - [ ] Decide how the format is selected (`GIF`/`SVG`/`MP4` variables vs. one
        `SetOutput demo.svg` deriving the renderer from the extension).
