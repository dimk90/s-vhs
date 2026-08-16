# Plan

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
- [ ] Test on macOS + installation instruction.


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
- [ ] Color theme unification between `agg` and `asg`:
  - [ ] theme defined in s-vhs and pass colors via custom theme option.
  - [ ] Add theme list with visualizations.
- [ ] Improve default fish colors: commands and completion colors, bold commands,...
  - [ ] Update shell to `fish` for all examples and re-render GIFs.
  - [ ] Add custom agg themes:
  - [ ] my spaceship theme.
  - [ ] tokyo-night theme.
  - [ ] catppuccin themes.
  - [ ] Add example with custom theme (hex colors).
- [ ] Add a `git` theme (bash/zsh command substitution, fish `__fish_git_prompt`)?
- [ ] Optional GIF optimization step (see COMMANDS.md).
- [ ] Print estimated resolution in `Start` ('e.g. ::: N Rows x M Cols x F FontSize -> Resolution W x H') ?
