# S-VHS Commands

Every command implemented in `s-vhs.sh`.

## Settings

| Command                      | Default    | Description                                                 |
| ---------------------------- | ---------- | ----------------------------------------------------------- |
| `SetOutput <path.ext>`       | —          | Add an output; repeatable. `.cast` and `.gif` are supported |
| `SetSession <name>`          | `demo`     | tmux session name used for the recording                    |
| `SetCols <cols>`             | `100`      | Terminal width in character cells                           |
| `SetRows <rows>`             | `40`       | Terminal height in character cells                          |
| `SetFontSize <px>`           | `28`       | Rendered font size in pixels                                |
| `SetFontFamily <family>`     | agg's      | Text font, keeping the Nerd Font and emoji fallbacks        |
| `SetFontFamilyExact <list>`  | agg's      | Complete family list, bypassing all fallbacks               |
| `SetLineHeight <multiplier>` | `1.2`      | Line-height multiplier passed to the renderer               |
| `SetTheme <theme>`           | `kanagawa` | agg theme name or custom palette                            |
| `SetShell <command>`         | `bash`     | Shell command run inside the tmux session                   |
| `SetTypingSpeed <seconds>`   | `0.07`     | Default delay between characters typed by `Type`            |
| `SetKeyDelay <seconds>`      | `0.0`      | Default pause after a key press sent by `Key`               |

> [!NOTE]
> At least one `SetOutput` is required. `SetFontFamily` and `SetFontFamilyExact`
> are mutually exclusive — agg rejects both flags at once, so the second call
> fails.

## Commands

| Command                            | Description                                                        |
| ---------------------------------- | ------------------------------------------------------------------ |
| `Start`                            | Start the detached tmux session with the configured geometry       |
| `Show`                             | Start recording; later calls append to the same cast               |
| `Hide`                             | Stop recording, leaving the session alive                          |
| `Type <text> [delay]`              | Emulate typing, one character at a time                            |
| `Key <key-name> [count] [delay]`   | Press a tmux-named key (`Enter`, `Down`, `C-r`) `count` times      |
| `Wait <pattern> [timeout]`         | Poll the visible pane until a grep pattern appears (default: 15s)  |
| `RunOffRecord <command> [settle]`  | Type and run a command, then wait (default: 2s)                    |
| `Render`                           | End the recording and write every requested output                 |

> [!NOTE]
> `[delay]`, `[settle]`, and `[timeout]` are in seconds; `[delay]` defaults to
> `SetTypingSpeed` for `Type` and to `SetKeyDelay` for `Key`, which sleeps that
> long after every one of its `[count]` presses (default: `1`).
