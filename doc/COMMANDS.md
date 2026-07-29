# Command Reference

- ✅ - Implemented — works today.
- 🟡 - Partial — works with caveats, or only via a lower-level call.
- 📋 - Planned — not implemented yet.
- 🚫 - Not applicable — meaningless for the `tmux` + `asciinema` + `agg` pipeline.

| VHS                                  | s-vhs (planned)                   | Today                              | Status |
| ------------------------------------ | --------------------------------- | ---------------------------------- | ------ |
| `Output out.gif`                     | `SetOutput`                       | `GIF=`, `CAST=`                    | 🟡    |
| `Output out.txt` / `.ascii`          | `SetOutput` + `asciinema convert` | —                                  | 📋    |
| `Require prog`                       | `Require`                         | —                                  | 📋    |
| `Type "text"`                        | `Type`                            | `type_text`                        | ✅     |
| `Ctrl+R`, `Alt+X`, `Ctrl+Shift+P`    | `Key`                             | `key C-r`, `key M-x`               | ✅     |
| `Enter`, `Tab`, `Up`, … (named keys) | `Enter`, `Tab`, `Up`, …           | `key Enter`, `key BSpace`          | 📋    |
| `Enter 2`, `Backspace 18` (repeat)   | `Key … <count>`                   | —                                  | 📋    |
| `ScrollUp` / `ScrollDown`            | `ScrollUp` / `ScrollDown`         | —                                  | 📋    |
| `Sleep 2`                            | `Sleep`                           | `sleep 2`                          | ✅     |
| `Wait /regex/`                       | `Wait`                            | `wait_for`                         | 🟡    |
| `Wait+Line /regex/`                  | `Wait` + scope argument           | —                                  | 📋    |
| `Hide`                               | `Hide`                            | `stop_recording`                   | ✅     |
| `Show`                               | `Show`                            | `record`                           | ✅     |
| `Screenshot out.png`                 | `Screenshot`                      | —                                  | 📋    |
| `Copy` / `Paste`                     | `Copy` / `Paste`                  | —                                  | 📋    |
| `Env KEY "VAL"`                      | `Env`                             | `export KEY=VAL`                   | 🟡    |
| `Source other.tape`                  | —                                 | `source other.sh`                  | ✅     |
|                                      |                                   |                                    |        |
| `Set Shell fish`                     | `SetShell`                        | `DEMO_SHELL` (`fish`)              | ✅     |
| `Set FontSize 40`                    | `SetFontSize`                     | `FONT_SIZE` (`28`)                 | ✅     |
| `Set FontFamily "…"`                 | `SetFontFamily`                   | `FONT_FAMILY` (bypasses fallbacks) | 🟡    |
| `Set Width 1200`                     | `SetCols`                         | `COLS` (`100`)                     | 🟡    |
| `Set Height 600`                     | `SetRows`                         | `ROWS` (`40`)                      | 🟡    |
| `Set LineHeight 1.8`                 | `SetLineHeight`                   | `LINE_HEIGHT` (`1.2`)              | ✅     |
| `Set TypingSpeed 0.1`                | `SetTypingSpeed`                  | `TYPE_DELAY` (`0.1`)               | ✅     |
| `Set Theme "…"`                      | `SetTheme`                        | `AGG_THEME` (`kanagawa`)           | 🟡    |
| `Set Padding 20`                     | `SetPadding`                      | —                                  | 📋    |
| `Set Framerate 60`                   | `SetFramerate`                    | — (agg `30`)                       | 📋    |
| `Set PlaybackSpeed 2`                | `SetPlaybackSpeed`                | — (agg `1`)                        | 📋    |
| `Set LoopOffset 5`                   | `SetLoopOffset`                   | —                                  | 📋    |
| `Set LetterSpacing 20`               | —                                 | —                                  | 🚫    |
| `Set Margin` / `MarginFill`          | —                                 | —                                  | 🚫    |
| `Set WindowBar`                      | —                                 | —                                  | 🚫    |
| `Set BorderRadius`                   | —                                 | —                                  | 🚫    |
| `Set CursorBlink`                    | —                                 | —                                  | 🚫    |
|                                      |                                   |                                    |        |
| —                                    | `SetKeyDelay`                     | `KEY_DELAY` (`0.0`)                | ✅     |
| —                                    | `SetSession`                      | `SESSION` (`demo`)                 | ✅     |
| —                                    | `SetIdleTimeLimit`                | — (agg `5`)                        | 📋    |
| —                                    | `SetLastFrameDuration`            | — (agg `3`)                        | 📋    |
| —                                    | `SetLoop`                         | — (agg loops)                      | 📋    |
| —                                    | `SetEmojiFontFamily`              | — (agg default chain)              | 📋    |
| —                                    | `SetFontFamilyExact`              | — (today's `FONT_FAMILY`)          | 📋    |
| —                                    | `SetFontDir`                      | —                                  | 📋    |
| —                                    | `SetFontAntialiasing`             | — (agg `6`)                        | 📋    |
| —                                    | `SetFontHinting`                  | — (agg `true`)                     | 📋    |
| —                                    | `SetRenderer`                     | — (agg `swash`)                    | 📋    |
| —                                    | `SetBoldIsBright`                 | — (agg off)                        | 📋    |
| —                                    | `SetTitle`                        | —                                  | 📋    |
| —                                    | `SetQuiet`                        | —                                  | 📋    |
| —                                    | `SetOptimize`                     | —                                  | 📋    |
|                                      |                                   |                                    |        |
| —                                    | `Start`                           | `start_session`                    | ✅     |
| —                                    | `Render`                          | `render`                           | ✅     |
| —                                    | `RunOffRecord`                    | `run_off_record`                   | ✅     |

[vhs-ref]: https://github.com/charmbracelet/vhs#vhs-command-reference

> Add to final command reference: 
> Teardown is automatic: sourcing `s-vhs.sh` installs an `EXIT` trap that kills the
> session and the recorder, so a failed script never leaves either running.


## Settings

Every setting is an overridable default (`: "${NAME:=…}"`), so a recording
script assigns it **before** `source s-vhs.sh`. Whether the `Set*` functions
are added on top of the variables is still open ([PLAN.md](PLAN.md), v0.1.0).

### Width / Height → Cols / Rows 🟡

`s-vhs` sizes the terminal in **cells, not pixels** — the whole point of
[#578](https://github.com/charmbracelet/vhs/issues/578). There is no pixel-size
setting; pixel size follows from `COLS`/`ROWS` × glyph size at `FONT_SIZE`.

```shell
COLS=80
ROWS=30
FONT_SIZE=21
```

> Print estimated resolution in `start_session` ('e.g. ::: N Rows x M Cols x F FontSize -> Resolution W x H') ?

### Theme 🟡

`AGG_THEME` takes an `agg` theme name: `asciinema`, `dracula`, `github-dark`,
`github-light`, `kanagawa`, `kanagawa-dragon`, `kanagawa-light`, `monokai`,
`nord`, `solarized-dark`, `solarized-light`, `gruvbox-dark`, `custom`.

Missing vs. VHS: an inline palette (VHS accepts a JSON theme object). `agg`
takes one as `--theme` with comma-separated hex triplets — background, default
text, then 8 (or 16) palette colors — but `AGG_THEME` is passed through
unvalidated, so an ad-hoc palette already works today.

### Font stack 🟡

`render` currently passes `FONT_FAMILY` as `agg --font-family`, which per
`agg --help` specifies "the complete font family list, **bypassing automatic
fallbacks**". That silently drops agg's bundled Symbols Nerd Font and the whole
emoji chain, so a recording with `FONT_FAMILY="Iosevka Term"` renders powerline
glyphs, devicons and emoji as tofu.

The fix is to pass `--text-font-family` instead, keeping the fallbacks, and to
expose the bypassing form under a name that says so ([PLAN.md](PLAN.md), v0.1.0):

| Setting              | agg flag               | Note                                          |
| -------------------- | ---------------------- | --------------------------------------------- |
| `SetFontFamily`      | `--text-font-family`   | Keeps Nerd Font + emoji fallbacks.            |
| `SetEmojiFontFamily` | `--emoji-font-family`  | Narrow or replace the emoji chain.            |
| `SetFontFamilyExact` | `--font-family`        | Today's behaviour; no fallbacks, opt-in only. |
| `SetFontDir`         | `--font-dir` (repeats) | Repo-local fonts — reproducible CI renders.   |

The remaining glyph-quality knobs have no VHS equivalent:

| Setting               | agg flag              | Default | Why it matters                                                                                        |
| --------------------- | --------------------- | ------- | ----------------------------------------------------------------------------------------------------- |
| `SetFontAntialiasing` | `--font-antialiasing` | `6`     | Alpha-coverage levels in glyph masks; the sharpness-vs-file-size dial (`off` = 2 levels).             |
| `SetFontHinting`      | `--font-hinting`      | `true`  | Swash only; matters at small `FONT_SIZE`.                                                             |
| `SetRenderer`         | `--renderer`          | `swash` | COLRv1 emoji (recent Noto Color Emoji) only render under `resvg`; swash falls back to monochrome.     |
| `SetBoldIsBright`     | `--bold-is-bright`    | off     | agg is literal; most terminals show bold red as bright red, so demos look off next to the real thing. |

### Padding 📋

Missing. An earlier `render 40` argument added the border with `magick`
(preferred) or `ffmpeg`; it was removed because re-encoding the finished GIF
costs sharpness and an extra dependency for a cosmetic frame. The code is kept
in [HISTORY.md](HISTORY.md) and is planned to return as `SetPadding`
([PLAN.md](PLAN.md), v0.4.0).

> Check if there any way to pad without a second encode / `magick` artifacts.


### Renderer pass-through 📋

Five settings are one `agg` flag each — a default plus a flag appended in
`render`, no new logic:

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
> `SetIdleTimeLimit` can be implemented at render time (tweakable after the fact)
> or baked into the cast at record time.

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

VHS renders one tape to many outputs; `s-vhs` always records a `.cast` and
currently renders exactly one GIF from it. Both paths are required variables:

```shell
CAST=doc/casts/demo.cast
GIF=doc/images/demo.gif
```

| VHS output                     | s-vhs                                    | Status |
| ------------------------------ | ---------------------------------------- | ------ |
| `.gif`                         | `GIF` variable, rendered by `agg`        | ✅     |
| `.mp4`                         | planned via `ffmpeg`                     | 📋    |
| `.webm`                        | —                                        | 📋    |
| `.png` frame dir               | —                                        | 📋    |
| `.ascii` / `.txt` golden files | `asciinema convert -f txt` from the cast | 📋    |
| —                              | `.cast` — always written, replayable     | ✅     |

Animated SVG (`termsvg`) is planned too, and has no VHS equivalent
([#644](https://github.com/charmbracelet/vhs/discussions/644)). How the format
is selected — separate `GIF`/`SVG`/`MP4` variables vs. one `SetOutput demo.svg`
deriving the renderer from the extension — is undecided ([PLAN.md](PLAN.md)).

## Type ✅

`type_text` types character by character with a delay, exactly like VHS's
`Type` + `Set TypingSpeed`. VHS's per-command `Type@500ms` override is the
optional second argument.

```shell
type_text '/context'        # TYPE_DELAY between keystrokes
type_text 'slow' 0.5        # VHS: Type@500ms "slow"
```

Quoting is plain shell quoting; no backtick escaping as in VHS.

## Keys 🟡

One generic `key` function takes a **tmux key name** and an optional pause:

```shell
key Enter
key Down 0.2                # pause 0.2s afterwards
```

Differences from VHS:

- No repeat count 📋 (`Enter 2`, `Backspace 18`); use a loop or repeated calls.
  `tmux send-keys -N <count>` repeats natively but without a delay between
  presses, so VHS's `Key@<time> <count>` still needs a loop.

Modifiers work through tmux's own notation, so `Ctrl+R` is `key C-r`, `Alt+X` is
`key M-x`, and `Ctrl+Alt+Shift+P` is `key C-M-S-p`. `start_session` enables
`extended-keys` with `csi-u` format, so apps that read CSI-u sequences receive
the modified keys correctly.

```shell
key C-r                     # VHS: Ctrl+R
key C-c                     # VHS: Ctrl+C
```

> Any way to have `Ctrl+R` instead of `C-r` ? Is easier to read.

### ScrollUp / ScrollDown 📋

Missing. Would need tmux copy-mode (`tmux copy-mode -t "$SESSION"` plus
`send-keys -X scroll-up`), and the scrollback is captured only if the alternate
screen is not in use.

## Wait 🟡

`wait_for` polls `tmux capture-pane` until a pattern appears, failing after a
timeout instead of guessing sleeps.

```shell
wait_for 'Context Usage'        # default timeout: 15s
wait_for 'Session compacted' 30
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
`tmux paste-buffer -p -t "$SESSION"` (`-p` for bracketed paste, so TUIs see a
real paste) — so this is mostly a naming decision. Note it would use the tmux
buffer, not the system clipboard.

## Env 🟡

No dedicated function today: exported variables are inherited by the tmux
server started in `start_session`.

```shell
export HELLO=WORLD
start_session
type_text 'echo $HELLO'
key Enter
```

> [!WARNING]
> tmux reuses a running server, so a session may inherit the environment of an
> earlier one. `start_session` uses `tmux -f /dev/null`, which isolates config
> but not the server environment.

A planned `Env` function closes that hole by passing the pair straight to the
session: `tmux new-session -e KEY=VAL`.

## Source ✅

It's a shell script — `source common-setup.sh` is the equivalent, and full
shell control flow (loops, conditionals, functions) comes for free
([#66](https://github.com/charmbracelet/vhs/issues/66)).
