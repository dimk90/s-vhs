# Debugging Recording Scripts

## Watch the Recording Live

📌 **A recording is quiet by design**: the script prints only a few `:::` lines
while everything happens in a detached tmux session. When it hangs or draws
the wrong thing, there is nothing on screen to explain why.

📌 **Debug it by observing that tmux session from a second terminal**. Observing must
not interfere with the recording - attaching a tmux client can resize the pane
or disturb the asciinema recorder - so look through pane snapshots instead of
attaching.

A simple option is GNU `watch` around `capture-pane`. It needs a fixed session
name, so set one before `Start`:

```bash
SetSession 'debug'
```
> Only one recording can hold it at a time.

Then, in a second terminal:

```bash
watch --color 'tmux -L s-vhs capture-pane -ep -t debug'
```

This is fine for plain shell output, but GNU watch can drop 24-bit
(`38;2;R;G;B`) color sequences, so truecolor TUIs come out miscolored.

The better option is the built-in viewer:
- it preserves 24-bit color, and
- with no session name it automatically follows the newest s-vhs recording - no
`SetSession` needed:

```bash
./s-vhs.sh watch
```

Without a local `s-vhs.sh`, the remote import runs it too:

```bash
curl -fsSL https://dimk90.github.io/s-vhs/latest | bash -s -- watch
```

Start the viewer whenever - it waits for a session to appear, keeps following
across edit-and-rerun cycles, and stops on `Ctrl-C`. Make its terminal at
least `SetCols` by `SetRows`, or every row is cut off at the right edge.

## When `Start` Itself Times Out

`Start` polls the new session until the shell's line editor starts reading,
and fails with a timeout after ten seconds if that never happens - typically
when the shell never reaches a prompt, e.g. zsh asking its first-run
configuration question or a startup file waiting for input. The failed `Start`
takes the session with it, leaving nothing to look at.

To see what the shell is actually stuck on, disable the polling and watch:

```bash
Start 'no-wait'
```

The session now stays alive, and the viewer shows whatever blocked the
startup. Use `no-wait` only to inspect a stuck startup, not to record - input
sent before the line editor is ready gets echoed twice.

## Localize Renderer Artifacts

When a rendered output such as a GIF or SVG shows artifacts, first find out
whether the problem is in the recording or in the renderer. Keep a cast
alongside the normal output:

```bash
SetOutput 'debug.cast'
SetOutput 'demo.gif'
```

Replay the cast with timing and color:

```bash
asciinema play debug.cast
```

Compare the replay with the rendered output. If the replay already shows the
artifact, the recording itself is at fault -> debug the script with the live
viewer above.

If the replay looks right, the problem is in the renderer (`agg` for GIF or
`asg` for SVG).
