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

## Watch the Pane Live

Run this viewer in another terminal. It may be started before the recording
script; it remains blank until the `debug` session exists.

```bash
(
    trap 'printf "\033[0m\033[?25h\n"' EXIT
    trap 'exit 130' INT TERM

    printf '\033[2J\033[H\033[?25l'

    while :; do
        tmux -L s-vhs capture-pane -ep -t debug 2> /dev/null |
            awk '{ printf "\033[%d;1H%s\033[0m\033[K", NR, $0 }'
        sleep 0.1
    done
)
```

Then run the recording normally:

```bash
./demo.rec.sh
```

Press `Ctrl-C` in the viewer to stop it. Its terminal should be at least as
large as the recording's `SetCols` by `SetRows` grid; a smaller terminal wraps
or clips the captured rows.

The viewer is deliberately built from snapshots:

- `tmux -L s-vhs` selects the dedicated s-vhs tmux server.
- `capture-pane -p` writes the visible pane to stdout without creating a client.
- `-e` retains ANSI text attributes, including 24-bit color.
- `awk` repaints rows in place and erases stale text at each line's end. The
  screen is cleared only once, avoiding the flicker caused by clearing every
  0.2 seconds.

Do not replace this with `watch --color` when debugging a truecolor TUI such as
Pi. GNU watch can discard `38;2;R;G;B` color sequences even though basic prompt
colors remain visible.

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
