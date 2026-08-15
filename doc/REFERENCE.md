# S-VHS Commands

Every command implemented in `s-vhs.sh`.

## Settings

| Command                      | Default    | Description                                                                                     |
| ---------------------------- | ---------- | ----------------------------------------------------------------------------------------------- |
| `SetOutput <path.ext>`       | —          | Add an output; repeatable. `.cast`, `.gif` and `.svg`[^svg-fonts] are supported                 |
| `SetSession <name>`          | `s-vhs-$$` | Session name on the dedicated s-vhs tmux server                                                 |
| `SetCols <cols>`             | `100`      | Terminal width in character cells                                                               |
| `SetRows <rows>`             | `40`       | Terminal height in character cells                                                              |
| `SetFontSize <px>`           | `28`       | Rendered font size in pixels                                                                    |
| `SetFontFamily <family>`     | renderer's | Text font[^svg-fonts], keeping the Nerd Font and emoji fallbacks; excludes `SetFontFamilyExact` |
| `SetFontFamilyExact <list>`  | renderer's | Complete family list[^svg-fonts], bypassing all fallbacks; excludes `SetFontFamily`             |
| `SetLineHeight <multiplier>` | `1.2`      | Line-height multiplier passed to the renderer                                                   |
| `SetTheme <theme>`           | `dracula`  | Theme name[^themes] or custom palette passed to each requested renderer                         |
| `SetShell <shell>`           | `bash`     | Shell run inside the session: `bash`, `zsh` or `fish`; a missing shell falls back to bash       |
| `SetPrompt <prompt>`         | `arrow`    | Prompt theme, literal prompt, or `native`[^prompts]                                             |
| `SetTypingSpeed <seconds>`   | `0.07`     | Default delay between characters typed by `Type`                                                |
| `SetKeyDelay <seconds>`      | `0.0`      | Default pause after a key press sent by `Key`                                                   |
| `Env <name> <value>`         | —          | Export a variable into the recorded shell; repeatable                                           |

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
    a custom palette when one recording requests both GIF and SVG.

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

| Command                             | Description                                                                                                                                                                                    |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Start [no-wait]`                   | Check dependencies, start the detached session on the dedicated s-vhs tmux server, wait until the shell's line editor starts reading, and print how to attach to it; `no-wait` skips that wait |
| `Show`                              | Start recording; later calls append to the same cast                                                                                                                                           |
| `Hide`                              | Stop recording, leaving the session alive                                                                                                                                                      |
| `Type <text> [delay]`               | Emulate typing literal text, one character at a time                                                                                                                                           |
| `Key <key-name> [count] [delay]`    | Press a tmux-named key[^keys] (`Enter`, `Down`, `C-r`) `count` times                                                                                                                           |
| `Enter`, `Tab`, … `[count] [delay]` | Press one named key[^keys]; same arguments as `Key`                                                                                                                                            |
| `Sleep <seconds>`                   | Pause the recording, holding the last frame on screen                                                                                                                                          |
| `Wait <pattern> [timeout]`          | Poll the visible pane until a grep pattern appears (default: 15s)                                                                                                                              |
| `Run <command> [settle]`            | Type and run a command, then wait (default: 2s)                                                                                                                                                |
| `RunOffRecord <command> [settle]`   | Run a command off camera: `Hide` + `Run` + `Show`; fails when not recording                                                                                                                    |
| `Render`                            | End the recording and write every requested output                                                                                                                                             |

[^keys]: Named keys: `Enter`, `Tab`, `Space`, `Backspace`, `Escape`, `Up`,
    `Down`, `Left`, `Right`, `PageUp`, `PageDown`, `Home`, `End`, `Insert`,
    `Delete`. A modified key stays with `Key` and tmux notation: `Key C-r`.

> [!NOTE]
> `[delay]`, `[settle]`, and `[timeout]` are in seconds; `[delay]` defaults to
> `SetTypingSpeed` for `Type` and to `SetKeyDelay` for `Key`, which sleeps that
> long after every one of its `[count]` presses (default: `1`).

> [!NOTE]
> Teardown is automatic: sourcing `s-vhs.sh` installs an `EXIT` trap that kills the
> session and the recorder, so a failed script never leaves either running.

## Utility & CLI

| Command                    | Description                                                                                                                                                                                                             |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `svhs_version`             | Print the version of the sourced `s-vhs.sh`                                                                                                                                                                             |
| `svhs_watch [session]`     | Function form of `s-vhs.sh watch`, for use after sourcing `s-vhs.sh`                                                                                                                                                    |
| `s-vhs.sh new [path]`      | Write an executable recording script with a pinned import, or print it when the path is omitted                                                                                                                         |
| `s-vhs.sh watch [session]` | Watch a recording live from another terminal without attaching a tmux client; wait for a named session, or follow the newest `s-vhs-<pid>` session when omitted; return to waiting after it ends and run until `Ctrl-C` |
