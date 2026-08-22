# Plan

## v0.4.0

- [x] Make list of planned functions (COMMANDS.md) which are easy to implement - low hanging fruit:
  - [x] `SetPlaybackSpeed <x>` - `agg --speed`, `asg --speed` (default `1`).
  - [x] `SetFramerate <fps>` - `agg --fps-cap`, `asg --fps` (default `30`).
  - [x] `SetIdleTimeLimit <secs>` - `--idle-time-limit` on both, applied in
        `Render` so the cast keeps its own metadata.
  - [x] `SetLoop <on|off>` - `--no-loop` on both; both loop by default.
  - [x] `SetTitle <text>` - `asciinema rec -t`; only the first segment writes
        metadata, the `--append` ones must not repeat it.
  - [x] `SetQuiet` - `asciinema rec -q`, `agg -q`, and the `::: ` lines.
  - [x] `Require <cmd>...` - wrapper over `_svhs_require_command`, called
        before `Start`.
  - [x] `Copy <text>` / `Paste` - `tmux set-buffer` / `paste-buffer -p`
        (bracketed paste); the tmux buffer, not the system clipboard.
  - [x] `SetOutput out.txt` - `asciinema convert -f txt` in `Render`, no new
        dependency.
  - Single-renderer knobs. Policy: apply such a setting where the renderer
    supports it and report the skipped output with one `::: ` line in `Render`,
    rather than failing the recording.
    - [x] `SetLastFrameDuration <secs>` - `agg --last-frame-duration`
          (default `3`).
    - [x] `SetBoldIsBright <on|off>` - `agg --bold-is-bright` (default off).
    - [x] `SetEngine <swash|resvg>` - `agg --renderer` (default `swash`); named
          `SetEngine` because `SetRenderer` reads as a choice between `agg` and
          `asg`, which is what `SetOutput` already decides.
    - [x] `SetFontAntialiasing <levels|off>` - `agg --font-antialiasing`
          (default `6`).
    - [x] `SetFontHinting <on|off>` - `agg --font-hinting` (default on).
    - [x] `SetFontDir <dir>` - `agg --font-dir`, repeatable like `Env`.
    - [x] `SetEmojiFontFamily <list>` - `agg --emoji-font-family`; replaces
          the emoji tail of the SVG font chain too.
    - [x] `SetPadding <px>` - `asg --padding`, with `SetPaddingX` /
          `SetPaddingY` axis overrides; the GIF side needs a second encode and
          stays out (see COMMANDS.md).
    - [x] `SetWindowBar <on|off>` - `asg --window`; VHS parity for SVG only.
    - [x] `SetCursor <on|off>` - `asg --no-cursor`.
    - [x] `WaitLine <pattern> [timeout]` - match only the cursor's current row;
    - [x] `SetOptimize <on|off>` - `gifsicle --batch -O3` after `agg` (default
          `off`); lossless and 12-25 % smaller, while agg's own recommended
          lossy set adds 1-2 % on <128-color terminal frames. Roughly doubles
          render time.
      - [ ] Add example and include to README: side-by-side table no-optimization | optimization.
      - [ ] Include table to demonstrate optimization efficiency: e.g. big gif, small git, lossy/lossless.
      - [ ] Not only `SetOptimize` -> add other optimization options.
      - [x] Add extra dependency `gifsicle` - optional: a missing one is
            reported in `Render`, never fails the recording.
      - [ ] Add command to install gifsicle to the warning message.
- [ ] Use colorful (yellow) for warnings.
- [ ] Update existing examples and README if needed.
- [ ] Review the "SVG usage issues" draft ([SVG.md](SVG.md)) - refine structure and make readable.
- [ ] Check which examples could be implemented with the current version of `s-vhs.sh`:
  - https://github.com/charmbracelet/vhs/tree/main/examples/settings
  - https://github.com/charmbracelet/vhs/tree/main/examples/commands
- [ ] Update template (`s-vhs new`) with common settings (if any new).
- [ ] Rename `COMMANDS` to `DEV.NOTES`
- [ ] Test on macOS + installation instruction.
- [ ] Update skill for recordings?


## Backlog

- [ ] Update `pi-context-view` recording. Especially `Require`?

- [ ] Write advanced example with emulating mouse selection.
  - [ ] Add new commands to [COMMANDS](doc/COMMANDS.md) if possible: e.g `Highlight`.
  - [ ] Add feature + issue ref (https://github.com/charmbracelet/vhs/issues/66) to README;
  - [ ] Add demo to README.
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
- [ ] Rended visualization for all available themes.
- [ ] Video output (same `.cast`, different renderer):
  - [ ] MP4 - render with `ffmpeg`?
  - [ ] WEBP - `ffmpeg`? MP4 to WEBP?
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
