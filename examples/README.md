# Examples


| Name             | Shows                                                                       |
| ---------------- | --------------------------------------------------------------------------- |
| `quick-start`    | A minimal recording: type a command, run it, render the GIF                 |
| `logo`           | Fast, colourful typing for the animated README header                       |
| `type`           | `Type` at the default speed and with a per-call delay                       |
| `enter`          | `Enter 4 0.5` - repeat count and delay after each press                     |
| `arrow`          | `Left 10 0.12` and `Right 10 0.05` walking the cursor along the line        |
| `backspace`      | `Backspace 18 0.05` deleting typed text                                     |
| `ctrl`           | `Key C-u` and tmux modifier notation (`C-`, `M-`, `S-`)                     |
| `clipboard`      | `Copy` and `Paste` - a bracketed paste arriving in a single frame           |
| `wait`           | `Wait '^build succeeded'` synchronizing on output instead of a sleep        |
| `wait-line`      | `WaitLine '^Username:$'` matching only the cursor's current row             |
| `cols-rows`      | `SetCols`/`SetRows` - the terminal is sized in cells, not pixels            |
| `font-size-<px>` | One 34x2 grid rendered at 10, 20 and 40 px                                  |
| `font-family`    | `SetFontFamily` falling back over a missing family, plus bundled Nerd icons |
| `line-height`    | `SetLineHeight 1.8` against the 1.2 default                                 |
| `theme`          | `SetTheme` pinning a named palette, plus `SetTypingSpeed`                   |
| `playback`       | `SetPlaybackSpeed`, `SetFramerate`, `SetLastFrameDuration`, `SetLoop`       |
| `prompt`         | `SetPrompt` themes and `SetShell` picking the recorded shell                |
| `require-env`    | `Require` checking a tool up front, `Env` configuring it for the shell      |
| `hide-show`      | Off-record `Run`, then `Hide` and `Show` appending another segment          |
| `run-off-record` | `RunOffRecord` - one hidden command without a `Hide`/`Show` pair            |
| `multi-output`   | Four `SetOutput` calls - a replayable cast and a text log next to the GIF and SVG |
| `svg-frame`      | `SetPadding`, `SetWindowBar` and `SetCursor` - the SVG-only framing         |
| `optimize`       | `SetOptimize` - a scrolling build log, against its unoptimized twin         |
| `remote-import`  | A pinned `curl` + `source` import with no local copy of `s-vhs.sh`          |
| `shell-power`    | Loops, variables and functions in the recording script itself               |
