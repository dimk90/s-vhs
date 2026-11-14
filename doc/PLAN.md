
##  Backlog

- [x] Turn on 24-bit color in the tmux server by default.
  - Without it, tmux turns 24-bit colors into the nearest 256-color ones, so
    Pi themes, `bat`, `delta`, `nvim` are recorded with slightly wrong colors.
  - agg and asg draw 24-bit color; only tmux reduces it.
  - Fix: `tmux set -as terminal-features ',*:RGB'` before the recorder
    attaches; maybe also `COLORTERM=truecolor` in the pane.
  - Low risk: the server is private (`-L s-vhs`).

- [x] Color theme unification between `agg` and `asg`:
  - [x] theme defined in s-vhs and pass colors via custom theme option.
  - [x] Add theme list with visualizations (samples) for each theme.

- [x] Clean up THEMES.md from not important information for better readability. 

- [ ] Report the theme colors to programs that ask the terminal for them.
  - Programs query the background with OSC 11 (and the foreground with OSC 10,
    the palette with OSC 4). Inside tmux they get black, not the `SetTheme`
    background the renderer draws, so colors derived from it are wrong
    (e.g. the pi-tui-prompt-box background).
  - Fix: `tmux set -w window-style 'bg=<theme background>'` (and `fg=`).
  - Bundled theme colors are now defined in s-vhs; custom hex palettes can
    be parsed. Renderer-specific names still have no known colors.
  - Side effect: tmux writes that background into every cell, so the `.cast`
    keeps it when rendered again with another theme. Document it, or add a
    setting to turn it off.
  - Workaround today: both `tmux set` commands via `Run` before `Show`.

- [ ] Show time or some spinner during recording.

- [ ] Add note recording output formats:
  - Demonstrate compression efficiency (GIF without optimization = 100%).
  - Use `stress.rec.sh` as example for compression efficiency.
  - Show compression difference with SetOptimize on/off.
  - Add note about quality drop for video:
    - Video is not optimized for such type of recordings (sharp edges, high contrast and text).
    - yuv422 will produce visible color artefacts.
    - If these two bullets above are correct.
  - Add section about compatibility (merge `SUPPORT-MATRIX`).
    - Should be extended with other apps/platforms? Like email, power point, discord, etc.
  - Recommend the best format if possible.
  - Should be concise and human readable.

- [ ] Fix padding/margin difference between `asg` and `agg`:
  - Check gif and svg from examples/themes for padding difference.

- [ ] Update for the recent ASG release.
  - Update Animated SVG issues.
