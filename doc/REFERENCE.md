# S-VHS Commands

Every command implemented in `s-vhs.sh`, plus the settings planned for the next
release, marked `(planned)`.

## Settings

### Session

Settings for the recording session, its cast metadata and its outputs.

| Command                                | Default               | Description                                                                                                                                                                                                                 |
| -------------------------------------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SetOutput <path.ext>`                 | —                     | Add an output; repeatable. `.cast`, `.txt`, `.gif`, `.webp` and `.svg`[^svg-fonts] are supported; WebP uses agg + FFmpeg losslessly                                                                                         |
| `SetSession <name>`                    | `s-vhs-$$`            | Session name on the dedicated s-vhs tmux server                                                                                                                                                                             |
| `SetCols <cols>`                       | `100`                 | Terminal width in character cells                                                                                                                                                                                           |
| `SetRows <rows>`                       | `40`                  | Terminal height in character cells                                                                                                                                                                                          |
| `SetShell <shell>`                     | `bash`                | Shell run inside the session: `bash`, `zsh` or `fish`; a missing shell falls back to bash                                                                                                                                   |
| `SetPrompt <prompt>`                   | `arrow`               | Prompt theme, literal prompt, or `native`[^prompts]                                                                                                                                                                         |
| `SetHighlightColors <bg> [fg] [attrs]` | `bg=yellow, fg=black` | Colors `Highlight` paints its selection with; each is a tmux style value - a name, a `colour0`..`colour255` index or `#rrggbb` - and `[attrs]` is a comma-separated list of tmux style attributes such as `bold,underscore` |
| `SetHighlightSpeed <seconds>`          | `0.03`                | Default delay per cell swept by `Highlight`                                                                                                                                                                                 |
| `SetTypingSpeed <seconds>`             | `0.07`                | Default delay between characters typed by `Type`                                                                                                                                                                            |
| `SetKeyDelay <seconds>`                | `0.0`                 | Default pause after a key press sent by `Key`                                                                                                                                                                               |
| `Env <name> <value>`                   | —                     | Export a variable into the recorded shell; repeatable                                                                                                                                                                       |
| `SetTitle <text>`                      | —                     | Title stored in the cast metadata and shown by players                                                                                                                                                                      |
| `SetQuiet`                             | `off`                 | Suppress recorder, text converter, raster renderer and s-vhs `:::` messages, keeping errors                                                                                                                                 |
| `Require <cmd>...`                     | —                     | Fail unless every command is available on `PATH`                                                                                                                                                                            |

### Render

Renderers and converters for the formats in the `Applies to` column:

- `agg` -> `GIF` output.
- `agg` + `ffmpeg` (`libwebp_anim`) -> `WebP` output.
- `asg` -> `SVG` output.

A setting the other renderer lacks is applied to the outputs that support it,
and `Render` reports the rest.

| Command                          | Applies to     | Default      | Description                                                                                                                                                          |
| -------------------------------- | -------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SetFontSize <px>`               | GIF, WebP, SVG | `28`         | Rendered font size in pixels                                                                                                                                         |
| `SetFontFamily <family>`         | GIF, WebP, SVG | renderer's   | Preferred text fonts[^svg-fonts]; if none are available, the renderer uses its defaults; Nerd Font and emoji fallbacks remain enabled; excludes `SetFontFamilyExact` |
| `SetFontFamilyExact <list>`      | GIF, WebP, SVG | renderer's   | Complete family list[^svg-fonts], bypassing all fallbacks; excludes `SetFontFamily` and `SetEmojiFontFamily`                                                         |
| `SetEmojiFontFamily <list>`      | GIF, WebP, SVG | renderer's   | Families emoji are drawn with[^svg-fonts], replacing the renderer's own chain; excludes `SetFontFamilyExact`                                                         |
| `SetFontDir <dir>`               | GIF, WebP      | —            | Additional font directory searched by the renderer, which must exist; repeatable                                                                                     |
| `SetEngine <swash\|resvg>`       | GIF, WebP      | `swash`      | Frame rendering backend; `resvg` draws COLRv1 emoji in color                                                                                                         |
| `SetLineHeight <multiplier>`     | GIF, WebP, SVG | `1.2`        | Line-height multiplier passed to the renderer                                                                                                                        |
| `SetTheme <theme>`               | GIF, WebP, SVG | `dracula`    | Theme name[^themes] or custom palette passed to each requested renderer                                                                                              |
| `SetBoldIsBright <on\|off>`      | GIF, WebP      | `off`        | Draw bold text in the bright ANSI color, as most terminals do                                                                                                        |
| `SetPadding <px>`                | SVG            | `0`          | Padding around the terminal on both axes, in output pixels                                                                                                           |
| `SetPaddingX <px>`               | SVG            | `SetPadding` | Padding left and right of the terminal, overriding `SetPadding` on that axis                                                                                         |
| `SetPaddingY <px>`               | SVG            | `SetPadding` | Padding above and below the terminal, overriding `SetPadding` on that axis                                                                                           |
| `SetWindowBar <on\|off>`         | SVG            | `off`        | Draw macOS-style window decorations - a bar with three buttons - above the terminal                                                                                  |
| `SetCursor <on\|off>`            | SVG            | `on`         | Draw the terminal cursor                                                                                                                                             |
| `SetFramerate <fps>`             | GIF, WebP, SVG | `30`         | Maximum number of rendered frames per second                                                                                                                         |
| `SetPlaybackSpeed <multiplier>`  | GIF, WebP, SVG | `1`          | Playback speed of the rendered animation                                                                                                                             |
| `SetIdleTimeLimit <seconds>`     | GIF, WebP, SVG | `5`          | Cap on idle gaps, applied at render time so the cast keeps its own timing                                                                                            |
| `SetLoop <on\|off>`              | GIF, WebP, SVG | `on`         | Repeat the animation instead of stopping after one pass                                                                                                              |
| `SetLastFrameDuration <seconds>` | GIF, WebP      | `3`          | How long the last frame is held before the loop restarts                                                                                                             |
| `SetOptimize <on\|off>`          | GIF            | `off`        | Shrink the rendered GIF with a lossless `gifsicle` pass; without `gifsicle` installed the GIF is left unoptimized; skipped for WebP                                  |

[^svg-fonts]: An SVG names but does not embed fonts, so its appearance depends
    on fonts installed on the viewer's system, falling back through a chain of
    monospace faces that ends at `monospace`. `asg` draws the cursor and the
    cell backgrounds on a fixed `0.6 × font-size` grid, so a face with a
    `0.6 em` advance - JetBrains Mono, Cascadia Mono, Liberation Mono - keeps
    text aligned with them; others drift further with every column.

[^themes]: Named color themes are renderer-specific, and a name only one
    renderer knows fails at `Render`, after the recording has run. `asg`
    accepts `asciinema`, `dracula`, `github-dark`, `github-light`, `monokai`,
    `solarized-dark` and `solarized-light`; `kanagawa`, `kanagawa-dragon`,
    `kanagawa-light`, `nord`, `gruvbox-dark` and `custom` are `agg`-only. Use
    a custom palette when one recording requests GIF or WebP alongside SVG.

[^prompts]: Bundled prompt themes: `arrow`, `plain`, `path` or `powerline`.
    A literal prompt in the shell's own syntax, or `native`. A theme and a
    literal both keep the shell out of the user's rc files; `native` keeps
    them.

> [!WARNING]
> Every command in this section must be called before `Start`; a call made
> after the session has started fails.

> [!WARNING]
> At least one `SetOutput` is required.


## Core

| Command                             | Description                                                                                                                                                                                                                                                                                    |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Start [no-wait]`                   | Check dependencies, start the detached session on the dedicated s-vhs tmux server, wait until the shell's line editor starts reading, and print how to attach to it; `no-wait` skips that wait                                                                                                 |
| `Show`                              | Start recording; later calls append to the same cast                                                                                                                                                                                                                                           |
| `Hide`                              | Stop recording, leaving the session alive                                                                                                                                                                                                                                                      |
| `Type <text> [delay]`               | Emulate typing literal text, one character at a time                                                                                                                                                                                                                                           |
| `Copy <text>`                       | Store non-empty text in a recording-local tmux buffer without touching the system clipboard                                                                                                                                                                                                    |
| `Paste`                             | Paste the text stored by `Copy` as a bracketed paste                                                                                                                                                                                                                                           |
| `Key <key-name> [count] [delay]`    | Press a tmux-named key[^keys] (`Enter`, `Down`, `C-r`) `count` times                                                                                                                                                                                                                           |
| `Enter`, `Tab`, … `[count] [delay]` | Press one named key[^keys]; same arguments as `Key`                                                                                                                                                                                                                                            |
| `Highlight <text> [hold] [delay]`   | Sweep a selection across `<text>` on the visible pane like a mouse drag, hold it (default: `1`s) and release it; matched literally on a single row, nothing is copied, of several occurrences the one closest to the cursor is taken, and a text that is not on screen is reported and skipped |
| `Sleep <seconds>`                   | Pause the recording, holding the last frame on screen                                                                                                                                                                                                                                          |
| `Wait <pattern> [timeout]`          | Poll the visible pane until a pattern[^wait-patterns] matches (default: 15s)                                                                                                                                                                                                                   |
| `WaitLine <pattern> [timeout]`      | Poll the cursor's current row until a pattern[^wait-patterns] matches (default: 15s)                                                                                                                                                                                                           |
| `Run <command> [settle]`            | Type and run a command, then wait (default: 2s)                                                                                                                                                                                                                                                |
| `RunOffRecord <command> [settle]`   | Run a command off camera: `Hide` + `Run` + `Show`; fails when not recording                                                                                                                                                                                                                    |
| `Render`                            | End the recording and write every requested output; GIF and WebP share one temporary GIF render, deleted afterwards                                                                                                                                                                            |
| `Finally <command>`                 | Register a command to run on exit or fail[^finally]; repeatable, last registered runs first, and a failing one neither stops the others nor changes the exit status                                                                                                                            |

[^wait-patterns]: Patterns are case-sensitive extended regular expressions
    (`grep -E`). A match anywhere within a row is enough; `^` and `$` anchor
    the start and end of the row. `.` matches any character, `[0-9]` matches
    a digit, `(...)` groups, and `|` separates alternatives. `*`, `+`, `?`
    and `{m,n}` repeat the preceding expression zero or more, one or more,
    zero or one, and m to n times, respectively. Escape metacharacters to match
    them literally (`\.` for a dot, `\+` for a plus), and single-quote patterns
    to preserve backslashes and prevent shell expansion.

[^keys]: Named keys: `Enter`, `Tab`, `Space`, `Backspace`, `Escape`, `Up`,
    `Down`, `Left`, `Right`, `PageUp`, `PageDown`, `Home`, `End`, `Insert`,
    `Delete`. A modified key stays with `Key` and tmux notation: `Key C-r`.

[^finally]: Teardown is automatic: sourcing `s-vhs.sh` installs an `EXIT` trap
    (`svhs_cleanup`) that kills the session and the recorder, then runs the
    registered commands, so a failed script never leaves either running.
    `Finally` is legal before `Start` and mid-recording alike.

> [!NOTE]
> `[delay]`, `[hold]`, `[settle]`, and `[timeout]` are in seconds; `[delay]`
> defaults to `SetTypingSpeed` for `Type`, to `SetHighlightSpeed` for
> `Highlight`, and to `SetKeyDelay` for `Key`, which sleeps that long after
> every one of its `[count]` presses (default: `1`).

## Utility & CLI

| Command                    | Description                                                                                                                                                                                                             |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `svhs_version`             | Print the version of the sourced `s-vhs.sh`                                                                                                                                                                             |
| `svhs_watch [session]`     | Function form of `s-vhs.sh watch`, for use after sourcing `s-vhs.sh`                                                                                                                                                    |
| `svhs_cleanup`[^teardown]  | Kill the session and the recorder, delete an unrequested temporary cast, the temporary GIF and the `Copy` buffer, then run the `Finally` commands; installed as the `EXIT` trap                                         |
| `s-vhs.sh new [path]`      | Write an executable recording script with a pinned import, or print it when the path is omitted                                                                                                                         |
| `s-vhs.sh watch [session]` | Watch a recording live from another terminal without attaching a tmux client; wait for a named session, or follow the newest `s-vhs-<pid>` session when omitted; return to waiting after it ends and run until `Ctrl-C` |

[^teardown]: Teardown is automatic - no need to call this function
    manually. Register extra teardown steps with `Finally` if needed.
