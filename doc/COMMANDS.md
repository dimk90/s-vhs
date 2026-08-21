# Commands

- ✅ - Implemented — works today.
- 🟡 - Partial — works with caveats, or only via a lower-level call.
- 📋 - Planned — not implemented yet; `📋 v0.4.0` is scheduled for the next
  release ([PLAN.md](PLAN.md)).
- 🚫 - Not applicable — meaningless for the `tmux` + `asciinema` + renderer pipeline.

The public configuration API is function-only: source `s-vhs.sh`, call all
`Set*` functions, then start the session. Settings shown in the **Today** column
are implemented now; the remaining command names still describe the target API.

| VHS                                  | s-vhs (planned)                 | Today                     | Status      |
| ------------------------------------ | ------------------------------- | ------------------------- | ----------- |
| `Output out.gif`                     | `SetOutput out.gif`             | `SetOutput out.gif`       | ✅          |
| `Output out.txt` / `.ascii`          | `SetOutput out.txt`             | `SetOutput out.txt`       | ✅          |
| `Require prog`                       | `Require`                       | `Require <cmd>...`        | ✅          |
| `Type "text"`                        | `Type <text> [<delay>]`         | `Type`                    | ✅          |
| `Ctrl+R`, `Alt+X`, `Ctrl+Shift+P`    | `Key <key> [<count>] [<delay>]` | `Key C-r`, `Key M-x`      | ✅          |
| `Enter`, `Tab`, `Up`, … (named keys) | `Enter`, `Tab`, `Up`, …         | `Enter`, `Backspace`      | ✅          |
| `Enter 2`, `Backspace 18` (repeat)   | `Enter [<count>] [<time>]`, ... | `Backspace 18 0.05`       | ✅          |
| `ScrollUp` / `ScrollDown`            | `ScrollUp` / `ScrollDown`       | —                         | 📋         |
| `Sleep 2`                            | `Sleep`                         | `Sleep 2`                 | ✅          |
| `Wait /regex/`                       | `Wait`                          | `Wait`                    | 🟡         |
| `Wait+Line /regex/`                  | `Wait` + scope argument         | —                         | 📋 Useful? |
| `Hide`                               | `Hide`                          | `Hide`                    | ✅          |
| `Show`                               | `Show`                          | `Show`                    | ✅          |
| `Screenshot out.png`                 | `Screenshot`                    | —                         | 📋         |
| `Copy` / `Paste`                     | `Copy <text>` / `Paste`         | `Copy` / `Paste`          | ✅          |
| `Env KEY "VAL"`                      | `Env`                           | `Env KEY VAL`             | ✅          |
| `Source other.tape`                  | —                               | `source other.sh`         | ✅          |
|                                      |                                 |                           |             |
| `Set Shell fish`                     | `SetShell`                      | `SetShell` (`bash`)       | ✅          |
| `Set FontSize 40`                    | `SetFontSize`                   | `SetFontSize` (`28`)      | ✅          |
| `Set FontFamily "…"`                 | `SetFontFamily`                 | `SetFontFamily` (chain)   | ✅          |
| `Set Width 1200`                     | `SetCols`                       | `SetCols` (`100`)         | ✅          |
| `Set Height 600`                     | `SetRows`                       | `SetRows` (`40`)          | ✅          |
| `Set LineHeight 1.8`                 | `SetLineHeight`                 | `SetLineHeight` (`1.2`)   | ✅          |
| `Set TypingSpeed 0.1`                | `SetTypingSpeed`                | `SetTypingSpeed` (`0.07`) | ✅          |
| `Set Theme "…"`                      | `SetTheme`                      | `SetTheme` (`dracula`)    | 🟡         |
| `Set Padding 20`                     | `SetPadding`                    | —                         | 📋 v0.4.0  |
| `Set Framerate 60`                   | `SetFramerate`                  | `SetFramerate` (`30`)     | ✅          |
| `Set PlaybackSpeed 2`                | `SetPlaybackSpeed`              | `SetPlaybackSpeed` (`1`)  | ✅          |
| `Set LoopOffset 5`                   | `SetLoopOffset`                 | —                         | 📋         |
| `Set LetterSpacing 20`               | —                               | —                         | 🚫         |
| `Set Margin` / `MarginFill`          | —                               | —                         | 🚫         |
| `Set WindowBar`                      | `SetWindowBar` (SVG only)       | —                         | 📋 v0.4.0  |
| `Set BorderRadius`                   | —                               | —                         | 🚫         |
| `Set CursorBlink`                    | —                               | —                         | 🚫         |
|                                      |                                 |                           |             |
| —                                    | `SetKeyDelay`                   | `SetKeyDelay` (`0.0`)     | ✅          |
| —                                    | `SetSession`                    | `SetSession` (`s-vhs-$$`) | ✅          |
| —                                    | `SetPrompt`                     | `SetPrompt` (`arrow`)     | ✅          |
| —                                    | `SetIdleTimeLimit`              | `SetIdleTimeLimit` (`5`)  | ✅          |
| —                                    | `SetLastFrameDuration`          | `SetLastFrameDuration`    | ✅          |
| —                                    | `SetLoop`                       | `SetLoop` (`on`)          | ✅          |
| —                                    | `SetEmojiFontFamily`            | — (agg default chain)     | 📋 v0.4.0  |
| —                                    | `SetFontFamilyExact`            | `SetFontFamilyExact`      | ✅          |
| —                                    | `SetFontDir`                    | —                         | 📋 v0.4.0  |
| —                                    | `SetFontAntialiasing`           | — (agg `6`)               | 📋 v0.4.0  |
| —                                    | `SetFontHinting`                | — (agg `true`)            | 📋 v0.4.0  |
| —                                    | `SetEngine`                     | `SetEngine` (`swash`)     | ✅          |
| —                                    | `SetBoldIsBright`               | `SetBoldIsBright` (`off`) | ✅          |
| —                                    | `SetCursor` (SVG only)          | — (cursor shown)          | 📋 v0.4.0  |
| —                                    | `SetTitle`                      | `SetTitle`                | ✅          |
| —                                    | `SetQuiet`                      | `SetQuiet` (`off`)        | ✅          |
| —                                    | `SetOptimize`                   | —                         | 📋         |
| —                                    | `SetOutput out.cast`            | `SetOutput out.cast`      | ✅          |
|                                      |                                 |                           |             |
| —                                    | `Start`                         | `Start`                   | ✅          |
| —                                    | `Render`                        | `Render`                  | ✅          |
| —                                    | `Run`                           | `Run`                     | ✅          |
| —                                    | `RunOffRecord`                  | `RunOffRecord`            | ✅          |
| `vhs --version` (CLI)                | `svhs_version`                  | `svhs_version`            | ✅          |
| `vhs new demo.tape` (CLI)            | `s-vhs.sh new`                  | `s-vhs.sh new`            | ✅          |

[vhs-ref]: https://github.com/charmbracelet/vhs#vhs-command-reference


### Font stack 🟡

`SetFontFamily` names the text font only: it maps to `agg --text-font-family`,
so agg keeps appending its automatic fallbacks — the bundled Symbols Nerd Font
for powerline glyphs and devicons, plus the emoji chain. `SetFontFamily
"Iosevka Term"` therefore still renders Nerd Font symbols and emoji that the
family itself does not contain.

`SetFontFamilyExact` maps to `--font-family`, which per `agg --help` specifies
"the complete font family list, **bypassing automatic fallbacks**"; anything
missing from the listed families renders as tofu. agg refuses both flags in one
invocation, so the two setters are mutually exclusive — the second one called
fails immediately.

```shell
SetFontFamily 'Iosevka Term'                    # + Symbols Nerd Font, emoji
SetFontFamilyExact 'JetBrainsMono Nerd Font Mono'   # this list and nothing else
```

| Setting              | agg flag               | Status     | Note                                        |
| -------------------- | ---------------------- | ---------- | ------------------------------------------- |
| `SetEmojiFontFamily` | `--emoji-font-family`  | 📋 v0.4.0 | Narrow or replace the emoji chain.          |
| `SetFontDir`         | `--font-dir` (repeats) | 📋 v0.4.0 | Repo-local fonts — reproducible CI renders. |

The remaining glyph-quality knobs have no VHS equivalent; all four land in
v0.4.0 - `SetBoldIsBright` and `SetEngine` already have - and all four are
agg-only:

| Setting               | agg flag              | Default | Why it matters                                                                                        |
| --------------------- | --------------------- | ------- | ----------------------------------------------------------------------------------------------------- |
| `SetFontAntialiasing` | `--font-antialiasing` | `6`     | Alpha-coverage levels in glyph masks; the sharpness-vs-file-size dial (`off` = 2 levels).             |
| `SetFontHinting`      | `--font-hinting`      | `true`  | Swash only; matters at small font sizes.                                                              |
| `SetEngine`           | `--renderer`          | `swash` | COLRv1 emoji (recent Noto Color Emoji) only render under `resvg`; swash falls back to monochrome.     |
| `SetBoldIsBright`     | `--bold-is-bright`    | off     | agg is literal; most terminals show bold red as bright red, so demos look off next to the real thing. |

### Padding 📋 v0.4.0

`asg --padding` / `--padding-x` / `--padding-y` pad an SVG natively, so
`SetPadding` lands for SVG in v0.4.0 and is reported as skipped for a GIF.

The GIF side stays open: an earlier `Render 40` argument added the border with
`magick` (preferred) or `ffmpeg`; it was removed because re-encoding the
finished GIF costs sharpness and an extra dependency for a cosmetic frame. That
code is kept in [HISTORY.md](HISTORY.md).

> Check if there any way to pad without a second encode / `magick` artifacts.


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
draws a macOS-style bar, so `SetWindowBar` is planned for SVG output only.

> Can bew added by .cast modification ?

## Output


| VHS output                     | s-vhs                                        | Status |
| ------------------------------ | -------------------------------------------- | ------ |
| `.mp4`                         | `SetOutput out.mp4`, planned via `ffmpeg`    | 📋    |
| `.webm`                        | `SetOutput out.webm`                         | 📋    |
| `.png` frame dir               | `SetOutput out.png`                          | 📋    |
| `.ascii` / `.txt` golden files | `SetOutput out.txt`, via `asciinema convert` | ✅     |


### ScrollUp / ScrollDown 📋

Missing. Would need tmux copy-mode plus `send-keys -X scroll-up`, and the
scrollback is captured only if the alternate screen is not in use.

## Wait 🟡

`Wait` polls `tmux capture-pane` until a pattern appears, failing after a
timeout instead of guessing sleeps.

```shell
Wait 'Context Usage'        # default timeout: 15s
Wait 'Session compacted' 30
```

Differences from VHS:
- The pattern is a **grep** pattern, not `/regex/`.
- Only VHS's `Wait+Screen` scope: the whole visible pane is matched. `Wait+Line`
  (last line only) and the bare `Wait` default of `/>$/` are missing 📋 — the
  scope is an optional argument piping `capture-pane -p` through `tail -n1`.
- VHS's `@time` sets the poll interval; here it is fixed at `0.2s` and the
  argument is the timeout.

> Is `Wait+Line` useful ?
> TODO: separate command?



## Screenshot 📋

Missing. Two plausible routes: `tmux capture-pane -p -e` for a text/ANSI dump,
or `agg --select <time>` to render a single frame out of the cast — though that
yields a one-frame GIF, not the PNG that VHS writes.

> Convert GIF to PNG/JPG via ffmpeg/magick?
