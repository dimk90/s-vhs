# How S-VHS Works

`s-vhs` records a terminal by combining small tools with separate jobs. It does
not capture pixels from a terminal window. Instead, it drives a real shell,
records the shell's terminal output and timing, then renders that recording into
a visual format.

<img src="images/svhs-pipeline.svg" width="800px" alt="s-vhs pipeline">


## The Pieces

|               | What it is                | Its job here                                                                                                            |
| ------------- | ------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| **tmux**      | Terminal multiplexer      | Runs the shell in a detached session, keeps its screen state, and fixes its size in rows and columns.                   |
| **asciinema** | Terminal session recorder | Attaches to the tmux session and stores terminal output, control sequences, geometry, and timestamps in a `.cast` file. |
| **`.cast`**   | asciicast v2 file         | The recording itself - text plus timings, the hand-off point between recording and rendering.                           |
| **agg**       | asciinema GIF generator   | Replays the cast into GIF frames using the selected font, font size, line height, and color theme.                      |
| **s-vhs**     | ~1k lines of bash         | Glues them together and gives you `Type`, `Key`, `Wait`, `Show`, `Render` instead of raw tmux commands.                 |

### Recording Script

A recording script (`demo.rec.sh`) is ordinary Bash that sources `s-vhs.sh`:

```bash
source ./s-vhs.sh

SetOutput 'demo.gif'
SetCols 80        # Configure the tmux session to 80 columns
SetRows 24        # Configure the tmux session to 24 rows

Start             # Create the detached tmux session
Show              # Attach asciinema and start recording
Type 'echo hello' # Emulate typing - sends each character to the tmux session
Key Enter         # Send the Enter key to the tmux session
sleep 2
Render            # Finalize the cast and render the requested outputs
```

What happens during a recording:
1. **`Start` creates the terminal.** tmux starts the configured shell inside a
   pseudo-terminal on the dedicated `s-vhs` socket, isolated from the user's
   tmux server and configuration. The session remains alive without a visible
   terminal window, so the script can drive it deterministically.
1. **`Show` starts capture.** asciinema starts headless and runs `tmux attach`
   as its command. It receives the same terminal stream an interactive client
   would receive and writes timestamped events to a cast.
1. **The script drives the session.** `Type`, `Key`, and `Run` send input through
   tmux. The shell or TUI processes that input and redraws the pane; asciinema
   records those updates.
1. **`Render` produces outputs.** s-vhs closes the session, keeps the cast when
   requested, and passes it to the renderer for each visual output.

Every tmux invocation uses the named `s-vhs` socket (`tmux -L s-vhs ...`);
the command sketches below omit that shared prefix.

Each command is a thin wrapper over one of the tools:

| `s-vhs` command | Under the hood                                                            |
| --------------- | ------------------------------------------------------------------------- |
| `Start`         | `tmux new-session -d -x <cols> -y <rows>` - detached, no personal config  |
| `Show`          | `asciinema rec --headless -c 'tmux attach' demo.cast &` in the background |
| `Type`, `Key`   | `tmux send-keys` into the session                                         |
| `Wait`          | `tmux capture-pane -p` piped through `grep` until the pattern appears     |
| `Hide`          | `tmux detach-client` - the recorder stops, the session keeps running      |
| `Render`        | `tmux kill-session`, then `agg demo.cast demo.gif` per requested GIF      |

> [!TIP]
> Two shells are involved, and mixing them up is the classic first bug:
> - **the driver** - your `demo.rec.sh`, where variables, loops, and functions run;
> - **the recorded shell** - the one inside tmux, which sees only the keystrokes you send.

> [!NOTE]
> `Type 'echo $HOME'` sends the literal characters `echo $HOME`; the *recorded*
> shell expands them. Quote accordingly.

### Cast Files

A `.cast` is a timed terminal event log, not a video. It preserves terminal
semantics: text, ANSI control sequences, rows, columns, and event timing, all
without committing to a pixel resolution:

```jsonc
{"version": 2, "width": 100, "height": 40, "timestamp": 1753996800}
[0.42, "o", "$ echo hi\r\n"]   // at 0.42s the terminal printed this text
[0.55, "o", "hi\r\n"]
```

This separation has useful consequences:
- the recording can be replayed with `asciinema play`;
- one recording can feed multiple outputs;
- fonts, themes, and pixel scale are chosen during rendering;
- changing output resolution does not change the recorded timing.

Today s-vhs can retain the cast directly or render it to GIF with `agg`. Other
cast-compatible renderers or converters can occupy the same final stage - for
example, an SVG or video renderer - without changing how tmux runs the terminal
or how asciinema records it.

## Links

- [README](../README.md) - install and the quick start.
- [REFERENCE.md](REFERENCE.md) - every command, with defaults.
- [examples/README.md](../examples/README.md) - the example catalogue.
