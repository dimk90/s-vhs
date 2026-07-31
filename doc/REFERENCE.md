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
| `SetTypingSpeed <seconds>`   | `0.07`     | Default delay between characters typed by `type_text`       |
| `SetKeyDelay <seconds>`      | `0.0`      | Default pause after a key press sent by `key`               |

> [!NOTE]
> At least one `SetOutput` is required. `SetFontFamily` and `SetFontFamilyExact`
> are mutually exclusive — agg rejects both flags at once, so the second call
> fails.

## Commands

| Command                             | Description                                                       |
| ----------------------------------- | ----------------------------------------------------------------- |
| `start_session`                     | Start the detached tmux session with the configured geometry      |
| `record`                            | Start recording; later calls append to the same cast (VHS `Show`) |
| `stop_recording`                    | Stop recording, leaving the session alive (VHS `Hide`)            |
| `type_text <text> [delay]`          | Emulate typing, one character at a time                           |
| `key <key-name> [pause]`            | Press one tmux-named key (`Enter`, `Down`, `C-r`), then pause     |
| `wait_for <pattern> [timeout]`      | Poll the visible pane until a grep pattern appears (default: 15s) |
| `run_off_record <command> [settle]` | Type and run a command, then wait (default: 2s)                   |
| `render`                            | End the recording and write every requested output                |

> [!NOTE]
> `[delay]`, `[pause]`, `[settle]`, and `[timeout]` are in seconds; `[delay]` and
> `[pause]` default to `SetTypingSpeed` and `SetKeyDelay`.
