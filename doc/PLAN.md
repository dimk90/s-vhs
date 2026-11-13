
##  Backlog

- [x] Turn on 24-bit color in the tmux server by default.
  - Without it, tmux turns 24-bit colors into the nearest 256-color ones, so
    Pi themes, `bat`, `delta`, `nvim` are recorded with slightly wrong colors.
  - agg and asg draw 24-bit color; only tmux reduces it.
  - Fix: `tmux set -as terminal-features ',*:RGB'` before the recorder
    attaches; maybe also `COLORTERM=truecolor` in the pane.
  - Low risk: the server is private (`-L s-vhs`).

- [ ] Add note about compression efficiency:
  - use `logo` as short example.
  - use `stress.rec.sh` as long example.
  - SetOptimize on/off
  - Quality drop for video.

- [ ] Show time or some spinner during recording.

- [ ] Add `SUPPORT-MATRIX` to the README documentation section.
  - Add email to support matrix
  - Add PowerPoint to support section.

- [ ] Update for the recent ASG release.
  - Update Animated SVG issues.

- [ ] Report the theme colors to programs that ask the terminal for them.
  - Programs query the background with OSC 11 (and the foreground with OSC 10,
    the palette with OSC 4). Inside tmux they get black, not the `SetTheme`
    background the renderer draws, so colors derived from it are wrong
    (e.g. the pi-tui-prompt-box background).
  - Fix: `tmux set -w window-style 'bg=<theme background>'` (and `fg=`).
  - Hex palette: colors are known. Named theme: names differ between agg and
    asg, so s-vhs needs its own name-to-colors table, or supports hex only.
  - Side effect: tmux writes that background into every cell, so the `.cast`
    keeps it when rendered again with another theme. Document it, or add a
    setting to turn it off.
  - Workaround today: both `tmux set` commands via `Run` before `Show`.

- [ ] Tab doesn't work.
	- Check why Key 'BTab' is working but Tab is not.
