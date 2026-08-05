# Commands

- ✅ - Implemented — works today.
- 🟡 - Partial — works with caveats, or only via a lower-level call.
- 📋 - Planned — not implemented yet.
- 🚫 - Not applicable — meaningless for the `tmux` + `asciinema` + renderer pipeline.

The public configuration API is function-only: source `s-vhs.sh`, call all
`Set*` functions, then start the session. Settings shown in the **Today** column
are implemented now; the remaining command names still describe the target API.

| VHS                                  | s-vhs (planned)                 | Today                     | Status      |
| ------------------------------------ | ------------------------------- | ------------------------- | ----------- |
| `Output out.gif`                     | `SetOutput out.gif`             | `SetOutput out.gif`       | ✅          |
| `Output out.txt` / `.ascii`          | `SetOutput out.txt`             | —                         | 📋         |
| `Require prog`                       | `Require`                       | —                         | 📋         |
| `Type "text"`                        | `Type <text> [<delay>]`         | `Type`                    | ✅          |
| `Ctrl+R`, `Alt+X`, `Ctrl+Shift+P`    | `Key <key> [<count>] [<delay>]` | `Key C-r`, `Key M-x`      | ✅          |
| `Enter`, `Tab`, `Up`, … (named keys) | `Enter`, `Tab`, `Up`, …         | `Enter`, `Backspace`      | ✅          |
| `Enter 2`, `Backspace 18` (repeat)   | `Enter [<count>] [<time>]`, ... | `Backspace 18 0.05`       | ✅          |
| `ScrollUp` / `ScrollDown`            | `ScrollUp` / `ScrollDown`       | —                         | 📋         |
| `Sleep 2`                            | `Sleep`                         | `sleep 2`                 | ✅          |
| `Wait /regex/`                       | `Wait`                          | `Wait`                    | 🟡         |
| `Wait+Line /regex/`                  | `Wait` + scope argument         | —                         | 📋 Useful? |
| `Hide`                               | `Hide`                          | `Hide`                    | ✅          |
| `Show`                               | `Show`                          | `Show`                    | ✅          |
| `Screenshot out.png`                 | `Screenshot`                    | —                         | 📋         |
| `Copy` / `Paste`                     | `Copy` / `Paste`                | —                         | 📋         |
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
| `Set Padding 20`                     | `SetPadding`                    | —                         | 📋         |
| `Set Framerate 60`                   | `SetFramerate`                  | — (agg `30`)              | 📋         |
| `Set PlaybackSpeed 2`                | `SetPlaybackSpeed`              | — (agg `1`)               | 📋         |
| `Set LoopOffset 5`                   | `SetLoopOffset`                 | —                         | 📋         |
| `Set LetterSpacing 20`               | —                               | —                         | 🚫         |
| `Set Margin` / `MarginFill`          | —                               | —                         | 🚫         |
| `Set WindowBar`                      | —                               | —                         | 🚫         |
| `Set BorderRadius`                   | —                               | —                         | 🚫         |
| `Set CursorBlink`                    | —                               | —                         | 🚫         |
|                                      |                                 |                           |             |
| —                                    | `SetKeyDelay`                   | `SetKeyDelay` (`0.0`)     | ✅          |
| —                                    | `SetSession`                    | `SetSession` (`s-vhs-$$`) | ✅          |
| —                                    | `SetPrompt`                     | `SetPrompt` (`arrow`)     | ✅          |
| —                                    | `SetIdleTimeLimit`              | — (agg `5`)               | 📋         |
| —                                    | `SetLastFrameDuration`          | — (agg `3`)               | 📋         |
| —                                    | `SetLoop`                       | — (agg loops)             | 📋         |
| —                                    | `SetEmojiFontFamily`            | — (agg default chain)     | 📋         |
| —                                    | `SetFontFamilyExact`            | `SetFontFamilyExact`      | ✅          |
| —                                    | `SetFontDir`                    | —                         | 📋         |
| —                                    | `SetFontAntialiasing`           | — (agg `6`)               | 📋         |
| —                                    | `SetFontHinting`                | — (agg `true`)            | 📋         |
| —                                    | `SetRenderer`                   | — (agg `swash`)           | 📋         |
| —                                    | `SetBoldIsBright`               | — (agg off)               | 📋         |
| —                                    | `SetTitle`                      | —                         | 📋         |
| —                                    | `SetQuiet`                      | —                         | 📋         |
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

> Add to final command reference: 
> Teardown is automatic: sourcing `s-vhs.sh` installs an `EXIT` trap that kills the
> session and the recorder, so a failed script never leaves either running.


## Settings

Source `s-vhs.sh` first, configure it exclusively through `Set*` functions, and
call every setter before `Start`. Backing variables are private implementation
details: recording scripts must not assign, export, or depend on them.

Each setter validates an ordinary scalar value immediately. `Start` then checks
that all required configuration, including at least one output, is present
before creating the tmux session or recorder.

```shell
source ./s-vhs.sh

SetOutput demo.gif
SetCols 80
SetRows 30
SetFontSize 21

Start
```

> Print estimated resolution in `Start` ('e.g. ::: N Rows x M Cols x F FontSize -> Resolution W x H') ?

### Theme 🟡

`SetTheme` accepts an `agg` theme name: `asciinema`, `dracula`, `github-dark`,
`github-light`, `kanagawa`, `kanagawa-dragon`, `kanagawa-light`, `monokai`,
`nord`, `solarized-dark`, `solarized-light`, `gruvbox-dark`, `custom`.

Missing vs. VHS: an inline palette (VHS accepts a JSON theme object). `agg`
takes one as `--theme` with comma-separated hex triplets — background, default
text, then 8 (or 16) palette colors. `SetTheme` deliberately passes arbitrary
non-empty values through rather than restricting them to the named themes, so
ad-hoc palettes remain possible.

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

| Setting              | agg flag               | Status | Note                                        |
| -------------------- | ---------------------- | ------ | ------------------------------------------- |
| `SetFontFamily`      | `--text-font-family`   | ✅     | Keeps Nerd Font + emoji fallbacks.          |
| `SetFontFamilyExact` | `--font-family`        | ✅     | No fallbacks, opt-in only.                  |
| `SetEmojiFontFamily` | `--emoji-font-family`  | 📋    | Narrow or replace the emoji chain.          |
| `SetFontDir`         | `--font-dir` (repeats) | 📋    | Repo-local fonts — reproducible CI renders. |

The remaining glyph-quality knobs have no VHS equivalent:

| Setting               | agg flag              | Default | Why it matters                                                                                        |
| --------------------- | --------------------- | ------- | ----------------------------------------------------------------------------------------------------- |
| `SetFontAntialiasing` | `--font-antialiasing` | `6`     | Alpha-coverage levels in glyph masks; the sharpness-vs-file-size dial (`off` = 2 levels).             |
| `SetFontHinting`      | `--font-hinting`      | `true`  | Swash only; matters at small font sizes.                                                              |
| `SetRenderer`         | `--renderer`          | `swash` | COLRv1 emoji (recent Noto Color Emoji) only render under `resvg`; swash falls back to monochrome.     |
| `SetBoldIsBright`     | `--bold-is-bright`    | off     | agg is literal; most terminals show bold red as bright red, so demos look off next to the real thing. |

### Padding 📋

Missing. An earlier `Render 40` argument added the border with `magick`
(preferred) or `ffmpeg`; it was removed because re-encoding the finished GIF
costs sharpness and an extra dependency for a cosmetic frame. The code is kept
in [HISTORY.md](HISTORY.md) and is planned to return as `SetPadding`
([PLAN.md](PLAN.md), v0.4.0).

> Check if there any way to pad without a second encode / `magick` artifacts.


### Renderer pass-through 📋

Five settings are one `agg` flag each — a default plus a flag appended in
`Render`, no new logic:

| Setting                | Flag                    |
| ---------------------- | ----------------------- |
| `SetFramerate`         | `--fps-cap`             |
| `SetPlaybackSpeed`     | `--speed`               |
| `SetIdleTimeLimit`     | `--idle-time-limit`     |
| `SetLastFrameDuration` | `--last-frame-duration` |
| `SetLoop`              | `--no-loop`             |

The last three have no VHS equivalent but are already in effect through `agg`'s
defaults, so today a script cannot change them — see the warning under
[Sleep](#sleep-).

`SetLoopOffset` is the odd one out: `agg --select 5..` *drops* the first five
seconds, while VHS's `LoopOffset` keeps every frame and only moves where the
loop starts. There is no cheap equivalent.

> [!NOTE]
> Idle time is capped in **two** places. `asciinema rec -i <secs>` does not alter
> the captured timing — it writes `idle_time_limit` into the cast header, which
> `agg` then honours unless `--idle-time-limit` is given on the command line. So
> `SetIdleTimeLimit` should be applied as a renderer flag in `Render`, rather
> than baked into the cast at record time. Like every setter, it is still called
> before `Start`; applying it later preserves the original cast metadata.

### Recorder metadata 📋

asciinema-side settings with no VHS counterpart. They do not change a single
rendered frame, but the `.cast` is a first-class output here — it is replayable
with `asciinema play` and publishable to asciinema.org.

| Setting    | asciinema flag | Note                                            |
| ---------- | -------------- | ----------------------------------------------- |
| `SetTitle` | `rec -t`       | Cast title, shown by players.                   |
| `SetQuiet` | `rec -q`       | Suppress recorder chatter in the script output. |

### GIF optimization 📋

`agg` encodes with gifski, which looks great and produces large files. agg's own
docs recommend a `gifsicle` pass, which would make a good opt-in `SetOptimize`:

```shell
gifsicle --lossy=80 -k 128 -O2 -Okeep-empty demo.gif -o demo-opt.gif
```

It is post-processing, the same layer as the removed padding, so it must stay
opt-in and off by default.

### Not applicable 🚫

`LetterSpacing`, `Margin`, `MarginFill`, `WindowBar`, `BorderRadius` are
frame decorations that `agg` does not render, and `CursorBlink` is a property of
the recorded terminal, not of the cast.

> Can bew added by .cast modification ?

## Output

`SetOutput` is repeatable: each call adds one requested output rather than
replacing earlier calls. Every recording uses one intermediate `.cast`, shared
by all requested output formats.

```shell
SetOutput doc/casts/demo.cast
SetOutput doc/images/demo.gif
```

An explicitly requested `.cast` is retained at exactly that path and remains
replayable with `asciinema play`. If no `.cast` output is requested, `s-vhs`
records to a temporary cast, uses it to produce the requested outputs, and
removes it automatically.

`Render` first finalizes the cast and then invokes only the tools required by
non-cast outputs. A recording that requests only a `.cast` therefore invokes no
renderer or converter—particularly, it does not require or run `agg`.

| VHS output                     | s-vhs                                            | Status |
| ------------------------------ | ------------------------------------------------ | ------ |
| `.gif`                         | `SetOutput out.gif`, rendered by `agg`           | ✅     |
| `.mp4`                         | `SetOutput out.mp4`, planned via `ffmpeg`        | 📋    |
| `.webm`                        | `SetOutput out.webm`                             | 📋    |
| `.png` frame dir               | `SetOutput out.png`                              | 📋    |
| `.ascii` / `.txt` golden files | `SetOutput out.txt`, via `asciinema convert`     | 📋    |
| —                              | `SetOutput out.cast`, retained without rendering | ✅     |
| —                              | `SetOutput out.svg`, planned via `termsvg`       | 📋    |

The output extension selects the renderer or converter; there are no
format-specific public setting variables. Animated SVG (`termsvg`) has no VHS
equivalent ([#644](https://github.com/charmbracelet/vhs/discussions/644)).


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


## Screenshot 📋

Missing. Two plausible routes: `tmux capture-pane -p -e` for a text/ANSI dump,
or `agg --select <time>` to render a single frame out of the cast — though that
yields a one-frame GIF, not the PNG that VHS writes.

> Convert GIF to PNG/JPG via ffmpeg/magick?

## Copy / Paste 📋

Missing. tmux provides the primitives — `tmux set-buffer` and
`tmux paste-buffer -p` (`-p` for bracketed paste, so TUIs see a real paste) — so
this is mostly a naming decision. Note it would use the tmux buffer, not the
system clipboard.
