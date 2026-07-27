# Command Reference

Mapping of every [VHS command][vhs-ref] to its `s-vhs` counterpart.

`s-vhs` is a Bash library, not a tape-file language: a recording script sets
variables, sources `s-vhs.sh` and calls functions. So a VHS `Set X Y` becomes a
variable assigned *before* sourcing, and a VHS command becomes a function call
*after* it.

Function names are **not frozen** yet (see [PLAN.md](PLAN.md)); the tables below
list the planned VHS-like name next to the name that works today.

[vhs-ref]: https://github.com/charmbracelet/vhs#vhs-command-reference

## Legend

| Mark | Meaning                                                                     |
| ---- | --------------------------------------------------------------------------- |
| ✅   | Implemented — works today.                                                  |
| 🟡  | Partial — works with caveats, or only via a lower-level call.               |
| 📋  | Planned — not implemented yet.                                              |
| 🚫  | Not applicable — meaningless for the `tmux` + `asciinema` + `agg` pipeline. |

## Commands at a glance

| VHS                        | s-vhs (planned)            | Today                | Status |
| -------------------------- | -------------------------- | -------------------- | ------ |
| `Output out.gif`           | `SetOutput`                | `GIF=`, `CAST=`      | 🟡    |
| `Require prog`             | `Require`                  | —                    | 📋    |
| `Set X Y`                  | see [Settings](#settings)  | variables            | 🟡    |
| `Type "text"`              | `Type`                     | `type_text`          | ✅     |
| `Enter`                    | `Enter`                    | `key Enter`          | 🟡    |
| `Backspace` `Tab` `Space`  | `Backspace` `Tab` `Space`  | `key BSpace` …       | 🟡    |
| `Up` `Down` `Left` `Right` | `Up` `Down` `Left` `Right` | `key Up` …           | 🟡    |
| `PageUp` `PageDown`        | `PageUp` `PageDown`        | `key PPage`          | 🟡    |
| `Ctrl+R`, `Alt+X`          | `Ctrl`, `Alt`              | `key C-r`, `key M-x` | 🟡    |
| `ScrollUp` `ScrollDown`    | `ScrollUp` `ScrollDown`    | —                    | 📋    |
| `Sleep 2`                  | `Sleep`                    | `sleep 2`            | ✅     |
| `Wait /regex/`             | `Wait`                     | `wait_for`           | 🟡    |
| `Hide`                     | `Hide`                     | `stop_recording`     | ✅     |
| `Show`                     | `Show`                     | `record`             | ✅     |
| `Screenshot out.png`       | `Screenshot`               | —                    | 📋    |
| `Copy` / `Paste`           | `Copy` / `Paste`           | —                    | 📋    |
| `Env KEY "VAL"`            | `Env`                      | `export KEY=VAL`     | ✅     |
| `Source other.tape`        | —                          | `source other.sh`    | ✅     |
| —                          | `Start`                    | `start_session`      | ✅     |
| —                          | `Render`                   | `render`             | ✅     |
| —                          | `RunHidden`                | `run_off_record`     | ✅     |

## Settings

Every setting is an overridable default (`: "${NAME:=…}"`), so a recording
script assigns it **before** `source s-vhs.sh`. Whether the `Set*` functions
are added on top of the variables is still open ([PLAN.md](PLAN.md), v0.1.0).

| VHS                       | s-vhs (planned)        | Variable today       | Default     | Status |
| ------------------------- | ---------------------- | -------------------- | ----------- | ------ |
| `Set Shell fish`          | `SetShell`             | `DEMO_SHELL`         | `fish`      | ✅     |
| `Set FontSize 40`         | `SetFontSize`          | `FONT_SIZE`          | `28`        | ✅     |
| `Set FontFamily "…"`      | `SetFontFamily`        | `FONT_FAMILY`        | agg default | ✅     |
| `Set Width 1200`          | `SetCols`              | `COLS`               | `100`       | 🟡    |
| `Set Height 600`          | `SetRows`              | `ROWS`               | `40`        | 🟡    |
| `Set LineHeight 1.8`      | `SetLineHeight`        | `LINE_HEIGHT`        | `1.2`       | ✅     |
| `Set TypingSpeed 0.1`     | `SetTypingSpeed`       | `TYPE_DELAY`         | `0.1`       | ✅     |
| `Set Theme "…"`           | `SetTheme`             | `AGG_THEME`          | `kanagawa`  | 🟡    |
| `Set Padding 20`          | `SetPadding`           | `render 20` argument | none        | 🟡    |
| `Set Framerate 60`        | `SetFramerate`         | —                    | agg `30`    | 📋    |
| `Set PlaybackSpeed 2`     | `SetPlaybackSpeed`     | —                    | agg `1`     | 📋    |
| `Set LoopOffset 5`        | `SetLoopOffset`        | —                    | —           | 📋    |
| `Set LetterSpacing 20`    | —                      | —                    | —           | 🚫    |
| `Set Margin`/`MarginFill` | —                      | —                    | —           | 🚫    |
| `Set WindowBar`           | —                      | —                    | —           | 🚫    |
| `Set BorderRadius`        | —                      | —                    | —           | 🚫    |
| `Set CursorBlink`         | —                      | —                    | —           | 🚫    |
| —                         | `SetKeyDelay`          | `KEY_DELAY`          | `0.0`       | ✅     |
| —                         | `SetSession`           | `SESSION`            | `demo`      | ✅     |
| —                         | `SetIdleTimeLimit`     | —                    | agg `5`     | 📋    |
| —                         | `SetLastFrameDuration` | —                    | agg `3`     | 📋    |
| —                         | `SetLoop`              | —                    | agg loops   | 📋    |

### Width / Height → Cols / Rows 🟡

`s-vhs` sizes the terminal in **cells, not pixels** — the whole point of
[#578](https://github.com/charmbracelet/vhs/issues/578). There is no pixel-size
setting; pixel size follows from `COLS`/`ROWS` × glyph size at `FONT_SIZE`.

```shell
COLS=80
ROWS=30
FONT_SIZE=21
```

### Theme 🟡

`AGG_THEME` takes an `agg` theme name: `asciinema`, `dracula`, `github-dark`,
`github-light`, `kanagawa`, `kanagawa-dragon`, `kanagawa-light`, `monokai`,
`nord`, `solarized-dark`, `solarized-light`, `gruvbox-dark`, `custom`.

Missing vs. VHS: an inline palette (VHS accepts a JSON theme object). `agg`
takes one as `--theme` with comma-separated hex triplets — background, default
text, then 8 (or 16) palette colors — but `AGG_THEME` is passed through
unvalidated, so an ad-hoc palette already works today.

### Padding 🟡

Implemented as an optional argument to `render`, using `magick` (preferred) or
`ffmpeg` to add a border to the finished GIF:

```shell
render 40   # 40px uniform padding
```

Slated for removal in v0.1.0 and reintroduction as `SetPadding` in v0.2.0
([PLAN.md](PLAN.md)) — post-processing the GIF is the wrong layer.

### Framerate / PlaybackSpeed / LoopOffset 📋

All three map onto existing `agg` flags and are cheap to add:
`--fps-cap`, `--speed`, and `--select` (which can start the render at a time
offset or percentage).

### Not applicable 🚫

`LetterSpacing`, `Margin`, `MarginFill`, `WindowBar`, `BorderRadius` are
frame decorations that `agg` does not render, and `CursorBlink` is a property of
the recorded terminal, not of the cast. Adding them would mean post-processing
the GIF — the same layering mistake as the current padding implementation.

## Output

VHS renders one tape to many outputs; `s-vhs` always records a `.cast` and
currently renders exactly one GIF from it. Both paths are required variables:

```shell
CAST=doc/casts/demo.cast
GIF=doc/images/demo.gif
```

| VHS output                     | s-vhs                                | Status |
| ------------------------------ | ------------------------------------ | ------ |
| `.gif`                         | `GIF` variable, rendered by `agg`    | ✅     |
| `.mp4`                         | planned via `ffmpeg`                 | 📋    |
| `.webm`                        | —                                    | 📋    |
| `.png` frame dir               | —                                    | 📋    |
| `.ascii` / `.txt` golden files | `asciinema --output-format txt`      | 📋    |
| —                              | `.cast` — always written, replayable | ✅     |

Animated SVG (`termsvg`) is planned too, and has no VHS equivalent
([#644](https://github.com/charmbracelet/vhs/discussions/644)). How the format
is selected — separate `GIF`/`SVG`/`MP4` variables vs. one `SetOutput demo.svg`
deriving the renderer from the extension — is undecided ([PLAN.md](PLAN.md)).

## Require 📋

No equivalent. A recording script can do it inline today:

```shell
command -v gum > /dev/null || { echo 'gum is required' >&2; exit 1; }
```

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

- No named wrappers — `Enter`, `Tab`, `Space`, `Up`, `Down`, `Left`, `Right`,
  `Backspace`, `PageUp`, `PageDown` are all spelled as `key <tmux-name>`
  (`BSpace`, `PPage`, `NPage`, …).
- No repeat count (`Enter 2`, `Backspace 18`); use a loop or repeated calls.
- The second argument is a pause *after* the press, whereas VHS's `@time` is the
  interval *between* repeats.

Modifiers work through tmux's own notation, so `Ctrl+R` is `key C-r`, `Alt+X` is
`key M-x`, and `Ctrl+Alt+Shift+P` is `key C-M-S-p`. `start_session` enables
`extended-keys` with `csi-u` format, so apps that read CSI-u sequences receive
the modified keys correctly.

```shell
key C-r                     # VHS: Ctrl+R
key C-c                     # VHS: Ctrl+C
```

### ScrollUp / ScrollDown 📋

Missing. Would need tmux copy-mode (`tmux copy-mode -t "$SESSION"` plus
`send-keys -X scroll-up`), and the scrollback is captured only if the alternate
screen is not in use.

## Sleep ✅

Plain `sleep` — the recorder keeps capturing while the script sleeps.

```shell
sleep 0.5                   # VHS: Sleep 500ms
sleep 2                     # VHS: Sleep 2
```

VHS's `ms`/`s` suffixes are not supported; use fractional seconds.

> [!WARNING]
> `agg --idle-time-limit` (default **5s**) silently caps any single pause, so a
> `sleep 10` renders as 5 seconds. The flag is not exposed yet — see
> `SetIdleTimeLimit` in [Settings](#settings).

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
  (last line only) and the bare `Wait` default of `/>$/` are missing.
- VHS's `@time` sets the poll interval; here it is fixed at `0.2s` and the
  argument is the timeout.

## Hide ✅ / Show ✅

`stop_recording` detaches the recorder from the still-running session (VHS
`Hide`); `record` (re)attaches it (VHS `Show`). The first `record` starts a
fresh cast, later calls append to it.

```shell
start_session
run_off_record 'go build -o example .'   # hidden setup
record                                   # Show
type_text './example'
key Enter
sleep 3
stop_recording                           # Hide
run_off_record 'rm example'
render
```

`run_off_record` is a convenience with no VHS equivalent: type a command, press
Enter and wait, with no recorder attached — a `Hide` / `Type` / `Enter` /
`Sleep` / `Show` block collapsed into one call.

## Screenshot 📋

Missing. Two plausible routes: `tmux capture-pane -p -e` for a text/ANSI dump,
or `agg --select <time>` to render a single frame out of the cast — though that
yields a one-frame GIF, not the PNG that VHS writes.

## Copy / Paste 📋

Missing. tmux provides the primitives — `tmux set-buffer` and
`tmux paste-buffer -t "$SESSION"` — so this is mostly a naming decision. Note it
would use the tmux buffer, not the system clipboard.

## Env ✅

No dedicated function needed: exported variables are inherited by the tmux
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

## Source ✅

It's a shell script — `source common-setup.sh` is the equivalent, and full
shell control flow (loops, conditionals, functions) comes for free
([#66](https://github.com/charmbracelet/vhs/issues/66)).

## s-vhs-only commands

| Function         | Purpose                                              |
| ---------------- | ---------------------------------------------------- |
| `start_session`  | Start the detached tmux session sized `COLS`×`ROWS`. |
| `render`         | Kill the session, render the cast to GIF with `agg`. |
| `run_off_record` | Type + run a command with no recorder attached.      |

Teardown is automatic: sourcing `s-vhs.sh` installs an `EXIT` trap that kills the
session and the recorder, so a failed script never leaves either running.
