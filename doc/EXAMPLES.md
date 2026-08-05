# Examples

Recording scripts derived from VHS's [settings][vhs-settings] and
[commands][vhs-commands] examples, plus a few that only s-vhs can show.

- ✅ - Possible today.
- 🟡 - Possible with a caveat listed below the table.
- 🚫 - Not applicable to the `tmux` + `asciinema` + `agg` pipeline.
- 📋 - Blocked until a planned command lands.

A written example lives in `examples/<name>.rec.sh` and renders
`examples/<name>.gif` next to it. Unless the example is about that very
setting, all of them record at `SetFontSize 40` in `Iosevka Term`, through the
default shell — no personal rc files, and the green `❯` of the `arrow` prompt
theme.

## Settings

| Name             | VHS example          | Shows                                       | Today | Done |
| ---------------- | -------------------- | ------------------------------------------- | ----- | ---- |
| `cols-rows`      | `width`, `height`    | `SetCols`/`SetRows` — cells, not pixels     | ✅    | [x]  |
| `font-size-<px>` | `set-font-size`      | One 34x2 grid rendered at 10, 20 and 40 px  | ✅    | [x]  |
| `font-family`    | `set-font-family`    | Missing family skipped, Nerd icons bundled  | ✅    | [x]  |
| `line-height`    | `set-line-height`    | `SetLineHeight 1.8` against the 1.2 default | ✅    | [x]  |
| `theme`          | `set-theme`          | `SetTheme` with a named theme               | ✅    | [x]  |
| —                | `set-typing-speed`   | Covered by `type`                           | 🟡   | [ ]  |
| —                | `set-letter-spacing` | No agg equivalent                           | 🚫   | —    |
| —                | `set-padding`        | `SetPadding` planned for v0.4.0             | 📋   | —    |
| —                | `set-margin`         | Frame decoration agg does not render        | 🚫   | —    |
| —                | `set-bar`            | Frame decoration agg does not render        | 🚫   | —    |
| —                | `set-border-radius`  | Frame decoration agg does not render        | 🚫   | —    |

> [!NOTE]
> `font-family`: `SetFontFamily 'Some Fancy Font, Fira Code'` — the missing
> family is skipped and the bundled Symbols Nerd Font still supplies the icons.
> `SetFontFamilyExact` would drop that fallback.

> [!NOTE]
> `set-typing-speed`: settings are frozen after `Start`, so no example varies
> the speed mid-tape. `type` shows the per-call `Type <text> <delay>` form
> instead, and `theme` sets `SetTypingSpeed`.

## Commands

| Name        | VHS example    | Shows                                        | Today | Done |
| ----------- | -------------- | -------------------------------------------- | ----- | ---- |
| `type`      | `type`         | `Type` with the default and a per-call delay | ✅    | [x]  |
| `enter`     | `enter`        | `Key Enter 4 0.5` — repeat count and delay   | ✅    | [x]  |
| `arrow`     | `arrow`        | `Key Left 10 0.12`, `Key Right 10 0.05`      | ✅    | [x]  |
| `backspace` | `backspace`    | `Key BSpace 18 0.05`                         | ✅    | [x]  |
| `ctrl`      | `ctrl`         | `Key C-u` and tmux modifier notation         | ✅    | [x]  |
| `hide-show` | `hide`, `show` | Off-record `Run`, `Hide`, then `Show` again  | ✅    | [x]  |
| —           | `tab`          | `Key Tab` completing a filename              | ✅    | [ ]  |
| —           | `space`        | `Key Space <count>`                          | ✅    | [ ]  |
| —           | `comment`      | Plain shell comments; nothing to demonstrate | 🚫   | —    |

## s-vhs only

| Name             | Shows                                                         | Today | Done |
| ---------------- | ------------------------------------------------------------- | ----- | ---- |
| `logo`           | Fast, colourful typing for the animated README header         | ✅    | [x]  |
| `quick-start`    | The README's Quick Start recording                            | ✅    | [x]  |
| `wait`           | `Wait <pattern>` synchronizing on output instead of sleeps    | ✅    | [x]  |
| `multi-output`   | Two `SetOutput` calls — a replayable cast next to the GIF     | ✅    | [x]  |
| `shell-power`    | Loops, variables and functions in the recording script itself | ✅    | [x]  |
| `run-off-record` | One hidden command mid-recording without a `Hide`/`Show` pair | ✅    | [x]  |

> [!NOTE]
> `quick-start` is the only example that keeps the default shell and renders at
> `SetFontSize 34`; the README scales it down to 700 px.

> [!NOTE]
> `wait`: the pattern is anchored (`^build succeeded`), because the pane also
> holds the command line that echoed it.
