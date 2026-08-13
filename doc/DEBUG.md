# Debugging Recording Scripts

A recording runs inside a detached tmux session. The safest way to debug it is
to inspect that pane without attaching another tmux client: this preserves the
configured terminal size, cannot send accidental input, and does not interfere
with the asciinema client used by `Show` and `Hide`.

## Use a Predictable Session Name

Give the recording a fixed tmux target before `Start`:

```bash
SetSession 'debug'

Start
Show
```

Only one recording can use that name at a time. Remove `SetSession` after
finishing the investigation if recordings should run concurrently again.

The live viewer below finds a default session on its own; every `capture-pane`
command needs the name.

## Start Without Waiting for the Shell

`Start` returns only once the shell's line editor starts reading, and fails
after ten seconds if that never happens. A `SetPrompt native` startup file that
asks a question or turns the line editor off never gets there, and the failed
`Start` takes the session with it, leaving nothing to look at.

Start the session anyway with `no-wait`:

```bash
SetSession 'debug'

Start 'no-wait'
```

The session then stays alive and the commands below show what its shell is
waiting on. Input sent in this state races with the shell's startup - a typed
command is echoed by the terminal driver and then again by the line editor, so
it appears twice. Use `no-wait` to inspect a stuck startup, not to record.

## Watch the Pane Live

`svhs_watch` shows the recorded pane in another terminal. Start it whenever —
it waits for the session:

```bash
./s-vhs.sh watch debug
```

Without a local `s-vhs.sh`, the remote import runs it too:

```bash
curl -fsSL https://dimk90.github.io/s-vhs/v0.3.0 | bash -s -- watch debug
```

Then run the recording normally:

```bash
./demo.rec.sh
```

With no session name the viewer follows the newest default `s-vhs-<pid>`
session, so it keeps up with an edit-and-rerun loop even though every run is
named after a new PID. A `SetSession` name has to be passed explicitly.

Once the recording ends the viewer waits again instead of exiting. `Ctrl-C`
stops it and hands the terminal back as it was.

The viewer's terminal should be at least as large as the recording's `SetCols`
by `SetRows` grid; in a smaller one every row is cut off at the right edge.

The viewer is deliberately built from snapshots, and takes no tmux client of
its own:

- `tmux -L s-vhs` selects the dedicated s-vhs tmux server.
- `capture-pane -p` writes the visible pane to stdout without creating a client.
- `-e` retains ANSI text attributes, including 24-bit color.
- Rows are repainted in place and cleared to their end, ten times a second.
  The screen is cleared only once, avoiding the flicker that clearing every
  frame causes.

A recording script that already sources the library can call the function
itself, `svhs_watch 'debug'` — but it blocks until interrupted, so it belongs
in a second terminal, not in the middle of a recording.

Do not reach for `watch --color 'tmux -L s-vhs capture-pane -ep -t debug'` when
debugging a truecolor TUI such as Pi. GNU watch can discard `38;2;R;G;B` color
sequences even though basic prompt colors remain visible.

## Capture a Snapshot

For a searchable, uncolored snapshot of the visible pane:

```bash
tmux -L s-vhs capture-pane -p -t debug
```

Include the entire tmux scrollback and save it for comparison:

```bash
tmux -L s-vhs capture-pane -p -S - -t debug > debug-pane.txt
```

Add `-e` when ANSI color and attributes need to be preserved. These commands
fail once `Render` or the recording script's exit cleanup has removed the
session.

## Inspect What Was Recorded

The live pane shows current state; a cast shows exactly what asciinema captured,
including timing and terminal control sequences. Keep one alongside the normal
output while debugging:

```bash
SetOutput 'debug.cast'
SetOutput 'demo.gif'
```

Replay it with timing and color:

```bash
asciinema play debug.cast
```

Or convert it to plain text for searching and diffs:

```bash
asciinema convert -f txt debug.cast -
```

The live viewer uses the current terminal's font and palette, while GIF output
uses the font, size, line height, and theme configured for agg. Use the viewer
to diagnose commands, input, redraws, and timing—not as a pixel preview of the
rendered GIF.

## Avoid Attaching a Client

`Start` prints a `tmux attach` command, but an attached debugging client is not
passive. A normal client may resize the pane, and even a read-only,
size-ignoring client can interfere with recorder-client detection or be detached
by `Hide`. Prefer `capture-pane` while investigating recording behavior.

If a recording was killed with `SIGKILL` and left the fixed session behind,
remove only that session before trying again:

```bash
tmux -L s-vhs kill-session -t debug
```
