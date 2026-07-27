# Plan

## v0.1.0

- [ ] Implement basic recording functions:
  - [ ] Select minimal subset of functions which already implemented or easy to add;
  - [ ] Function names should be intuitive and similar to VHS.
  - [ ] Decide on using only functions or functions+variables.
  - [ ] Refactor draft `s-vhs.sh`
- [ ] Remove current implementation of padding functionality from `s-vhs.sh`.
- [ ] Implement basic examples, similar to VHS:
  - [ ] Implement minimal example for README#Quick_Start.
  - [ ] https://github.com/charmbracelet/vhs/tree/main/examples/settings
  - [ ] https://github.com/charmbracelet/vhs/tree/main/examples/commands
  - [ ] Define set of examples with available functions.
  - [ ] Add script example.
  - [ ] Add recordings scripts to `examples` folder.
  - [ ] Add rendered GIFs to README + links to `examples`.
- [ ] Make `s-vhs.sh` compatible with macOS bash (3.2):
  - [ ] Guard empty-array expansion under `set -u` (`"${arr[@]}"` is an
        unbound variable error before bash 4.4 — hits `font_args` in `render`).
  - [ ] Replace GNU-only `truncate -s` (absent on stock macOS).
  - [ ] Check fractional `sleep` and other coreutils assumptions on BSD tools.
  - [ ] No bash 4+ syntax is used today — keep it that way (no `declare -A`,
        `mapfile`, `${var,,}`, `&>>`, namerefs).
- [ ] Add advanced example with emulating mouse selection.
- [ ] Add template for recording scrip: with all available setting (commented).
- [ ] Publish link to the project in related VHS issues.
- [ ] Add version number to the `s-vhs.sh`.


## v0.2.0

- [ ] Add `SetPadding X` function.
- [ ] Rended visualization for all available themes.
- [ ] Add SVG and MP4 output (same `.cast`, different renderer):
  - [ ] Animated SVG — use `termsvg`; `svg-term-cli` pulls in Node.
  - [ ] MP4 — render with `ffmpeg`.
  - [ ] Decide how the format is selected (`GIF`/`SVG`/`MP4` variables vs. one
        `SetOutput demo.svg` deriving the renderer from the extension).
