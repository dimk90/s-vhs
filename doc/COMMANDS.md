# Commands

- ✅ - Implemented — works today.
- 🟡 - Partial — works with caveats, or only via a lower-level call.
- 📋 - Planned — not implemented yet; `📋 v0.4.0` is scheduled for the next
  release ([PLAN.md](PLAN.md)).
- 🚫 - Not applicable — meaningless for the `tmux` + `asciinema` + renderer pipeline.

The public configuration API is function-only: source `s-vhs.sh`, call all
`Set*` functions, then start the session. Settings shown in the **Today** column
are implemented now; the remaining command names still describe the target API.

| VHS                                  | s-vhs (planned)                 | Today                       | Status |
| ------------------------------------ | ------------------------------- | --------------------------- | ------ |
| `Output out.gif`                     | `SetOutput out.gif`             | `SetOutput out.gif`         | ✅     |
| `Output out.txt` / `.ascii`          | `SetOutput out.txt`             | `SetOutput out.txt`         | ✅     |
| `Require prog`                       | `Require`                       | `Require <cmd>...`          | ✅     |
| `Type "text"`                        | `Type <text> [<delay>]`         | `Type`                      | ✅     |
| `Ctrl+R`, `Alt+X`, `Ctrl+Shift+P`    | `Key <key> [<count>] [<delay>]` | `Key C-r`, `Key M-x`        | ✅     |
| `Enter`, `Tab`, `Up`, … (named keys) | `Enter`, `Tab`, `Up`, …         | `Enter`, `Backspace`        | ✅     |
| `Enter 2`, `Backspace 18` (repeat)   | `Enter [<count>] [<time>]`, ... | `Backspace 18 0.05`         | ✅     |
| `ScrollUp` / `ScrollDown`            | `ScrollUp` / `ScrollDown`       | —                           | 📋    |
| `Sleep 2`                            | `Sleep`                         | `Sleep 2`                   | ✅     |
| `Wait /regex/`                       | `Wait`                          | `Wait`                      | 🟡    |
| `Wait+Line /regex/`                  | `WaitLine <pattern> [timeout]`  | `WaitLine`                  | ✅     |
| `Hide`                               | `Hide`                          | `Hide`                      | ✅     |
| `Show`                               | `Show`                          | `Show`                      | ✅     |
| `Screenshot out.png`                 | `Screenshot`                    | —                           | 📋    |
| `Copy` / `Paste`                     | `Copy <text>` / `Paste`         | `Copy` / `Paste`            | ✅     |
| `Env KEY "VAL"`                      | `Env`                           | `Env KEY VAL`               | ✅     |
| `Source other.tape`                  | —                               | `source other.sh`           | ✅     |
|                                      |                                 |                             |        |
| `Set Shell fish`                     | `SetShell`                      | `SetShell` (`bash`)         | ✅     |
| `Set FontSize 40`                    | `SetFontSize`                   | `SetFontSize` (`28`)        | ✅     |
| `Set FontFamily "…"`                 | `SetFontFamily`                 | `SetFontFamily` (chain)     | ✅     |
| `Set Width 1200`                     | `SetCols`                       | `SetCols` (`100`)           | ✅     |
| `Set Height 600`                     | `SetRows`                       | `SetRows` (`40`)            | ✅     |
| `Set LineHeight 1.8`                 | `SetLineHeight`                 | `SetLineHeight` (`1.2`)     | ✅     |
| `Set TypingSpeed 0.1`                | `SetTypingSpeed`                | `SetTypingSpeed` (`0.07`)   | ✅     |
| `Set Theme "…"`                      | `SetTheme`                      | `SetTheme` (`dracula`)      | 🟡    |
| `Set Padding 20`                     | `SetPadding` (SVG only)         | `SetPadding` (`0`)          | ✅     |
| `Set Framerate 60`                   | `SetFramerate`                  | `SetFramerate` (`30`)       | ✅     |
| `Set PlaybackSpeed 2`                | `SetPlaybackSpeed`              | `SetPlaybackSpeed` (`1`)    | ✅     |
| `Set LoopOffset 5`                   | `SetLoopOffset`                 | —                           | 📋    |
| `Set LetterSpacing 20`               | —                               | —                           | 🚫    |
| `Set Margin` / `MarginFill`          | —                               | —                           | 🚫    |
| `Set WindowBar`                      | `SetWindowBar` (SVG only)       | `SetWindowBar` (`off`)      | ✅     |
| `Set BorderRadius`                   | —                               | —                           | 🚫    |
| `Set CursorBlink`                    | —                               | —                           | 🚫    |
|                                      |                                 |                             |        |
| —                                    | `SetKeyDelay`                   | `SetKeyDelay` (`0.0`)       | ✅     |
| —                                    | `SetSession`                    | `SetSession` (`s-vhs-$$`)   | ✅     |
| —                                    | `SetPrompt`                     | `SetPrompt` (`arrow`)       | ✅     |
| —                                    | `SetIdleTimeLimit`              | `SetIdleTimeLimit` (`5`)    | ✅     |
| —                                    | `SetLastFrameDuration`          | `SetLastFrameDuration`      | ✅     |
| —                                    | `SetLoop`                       | `SetLoop` (`on`)            | ✅     |
| —                                    | `SetEmojiFontFamily`            | `SetEmojiFontFamily`        | ✅     |
| —                                    | `SetFontFamilyExact`            | `SetFontFamilyExact`        | ✅     |
| —                                    | `SetFontDir`                    | `SetFontDir` (repeats)      | ✅     |
| —                                    | `SetFontAntialiasing`           | `SetFontAntialiasing` (`6`) | ✅     |
| —                                    | `SetFontHinting`                | `SetFontHinting` (`on`)     | ✅     |
| —                                    | `SetEngine`                     | `SetEngine` (`swash`)       | ✅     |
| —                                    | `SetBoldIsBright`               | `SetBoldIsBright` (`off`)   | ✅     |
| —                                    | `SetCursor` (SVG only)          | `SetCursor` (`on`)          | ✅     |
| —                                    | `SetPaddingX` (SVG only)        | `SetPaddingX`               | ✅     |
| —                                    | `SetPaddingY` (SVG only)        | `SetPaddingY`               | ✅     |
| —                                    | `SetTitle`                      | `SetTitle`                  | ✅     |
| —                                    | `SetQuiet`                      | `SetQuiet` (`off`)          | ✅     |
| —                                    | `SetOptimize`                   | —                           | 📋    |
| —                                    | `SetOutput out.cast`            | `SetOutput out.cast`        | ✅     |
|                                      |                                 |                             |        |
| —                                    | `Start`                         | `Start`                     | ✅     |
| —                                    | `Render`                        | `Render`                    | ✅     |
| —                                    | `Run`                           | `Run`                       | ✅     |
| —                                    | `RunOffRecord`                  | `RunOffRecord`              | ✅     |
| `vhs --version` (CLI)                | `svhs_version`                  | `svhs_version`              | ✅     |
| `vhs new demo.tape` (CLI)            | `s-vhs.sh new`                  | `s-vhs.sh new`              | ✅     |

[vhs-ref]: https://github.com/charmbracelet/vhs#vhs-command-reference


### Renderer pass-through 🟡

A setting only one renderer supports — `SetLastFrameDuration`, `SetEngine`,
`SetBoldIsBright` and the agg-only font knobs above; `SetPadding`,
`SetWindowBar` and `SetCursor` on the asg side — is applied wherever the
renderer supports it, and `Render` reports the output it was skipped for with a
single `::: ` line rather than failing the recording.

`SetLoopOffset` is the odd one out: `agg --select 5..` *drops* the first five
seconds, while VHS's `LoopOffset` keeps every frame and only moves where the
loop starts. There is no cheap equivalent.


### GIF optimization 📋

`agg` encodes with gifski, which looks great and produces large files. agg's own
docs recommend a `gifsicle` pass, which would make a good opt-in `SetOptimize`:

```shell
gifsicle --lossy=80 -k 128 -O2 -Okeep-empty demo.gif -o demo-opt.gif
```

It is post-processing, the same layer as the removed padding, so it must stay
opt-in and off by default.

### Not applicable 🚫

`LetterSpacing`, `Margin`, `MarginFill` and `BorderRadius` are frame decorations
that neither renderer draws, and `CursorBlink` is a property of the recorded
terminal, not of the cast. `WindowBar` moved out of this list: `asg --window`
draws a macOS-style bar, so `SetWindowBar` decorates SVG output only.

> Can bew added by .cast modification ?

## Output


| VHS output       | s-vhs                                     | Status |
| ---------------- | ----------------------------------------- | ------ |
| `.mp4`           | `SetOutput out.mp4`, planned via `ffmpeg` | 📋    |
| `.webm`          | `SetOutput out.webm`                      | 📋    |
| `.png` frame dir | `SetOutput out.png`                       | 📋    |


### ScrollUp / ScrollDown 📋

Missing. Would need tmux copy-mode plus `send-keys -X scroll-up`, and the
scrollback is captured only if the alternate screen is not in use.

## Screenshot 📋

Missing. Two plausible routes: `tmux capture-pane -p -e` for a text/ANSI dump,
or `agg --select <time>` to render a single frame out of the cast — though that
yields a one-frame GIF, not the PNG that VHS writes.

> Convert GIF to PNG/JPG via ffmpeg/magick?
