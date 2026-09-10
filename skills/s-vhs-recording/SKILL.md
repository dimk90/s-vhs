---
name: s-vhs-recording
description: Write, run and verify s-vhs recording scripts (`*.rec.sh`) that record a terminal session and render it as an animated GIF, WebP or SVG, an asciinema cast or a text log. Use when asked to record a terminal demo, produce a demo GIF or animation for a README, script an asciinema cast, automate typing into a terminal for a screencast, or port a VHS `.tape` file. Covers scaffolding, the `Set*` → `Start` → `Show` → `Render` lifecycle, typing and key presses, hiding setup steps, painting typed text with color, and verifying the result without watching the GIF.
compatibility: Requires bash, tmux and asciinema on PATH; agg for GIF and WebP output, ffmpeg with libwebp_anim for WebP, asg for SVG, gifsicle for GIF optimization. Linux or macOS.
allowed-tools: Read Write Edit Bash(command -v:*) Bash(curl:*) Bash(chmod:*) Bash(asciinema convert:*) Bash(tmux -L s-vhs:*) Bash(ls:*)
---

# S-VHS Recording

[s-vhs](https://github.com/dimk90/s-vhs) drives a detached `tmux` session with
`asciinema` and renders the cast with an output-specific renderer. A recording
is a plain bash script that sources `s-vhs.sh` and calls its commands — there is
no tape language, so loops, variables and functions come for free.

**Reference** — every command, setting and default:
<https://github.com/dimk90/s-vhs/blob/develop/doc/REFERENCE.md>
(raw: `https://raw.githubusercontent.com/dimk90/s-vhs/develop/doc/REFERENCE.md`).
Read it before using any command not shown below; the API is pre-1.0 and moves.

## Setup

| Command      | Needed for                                             |
| ------------ | ------------------------------------------------------ |
| `tmux`       | always                                                 |
| `asciinema`  | always; also writes `.cast` and `.txt` outputs         |
| `agg`        | `.gif` and `.webp` output                              |
| `ffmpeg`     | `.webp` output; must include `libwebp_anim`             |
| `asg`        | `.svg` output                                          |
| `gifsicle`   | `SetOptimize 'on'` for GIF; optional, a missing one only warns |

```bash
command -v tmux asciinema agg
```

Report a missing required dependency instead of working around it.

## 1. Scaffold

Never hand-write the header — the scaffolder pins the library version:

```bash
curl -fsSL https://dimk90.github.io/s-vhs/latest | bash -s -- new demo.rec.sh
```

When `s-vhs.sh` is checked out locally, use `./s-vhs.sh new demo.rec.sh` and
replace the remote import with `source ./s-vhs.sh`.

Name recordings `<topic>.rec.sh` and make them executable.

## 2. Skeleton

```bash
#!/usr/bin/env bash
#
# One sentence on what this recording shows.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck disable=SC1090
source <(curl -fsSL https://dimk90.github.io/s-vhs/v0.5.0) && wait "$!" || exit 1

# Every command the recorded shell drives, checked before anything starts
Require 'git'

# Outputs are relative to nothing — anchor them, the script may run from anywhere
SetOutput "$SCRIPT_DIR/demo.gif"

SetCols 60
SetRows 8
SetFontSize 40
SetOptimize 'on'

Start   # terminal up
Show    # recorder on

Type 'git --version'
Enter
Sleep 2

Render  # recorder off, write every output
```

The `wait "$!"` guard is required with the remote import: without it a failed
or truncated download passes silently.

## 3. Configure

Every `Set*` call goes **before `Start`** and fails afterwards. `Start` needs at
least one `SetOutput`.

- `SetOutput` is repeatable and the extension picks the format: `.gif` (agg),
  `.webp` (agg + FFmpeg), `.svg` (asg), `.cast` (replayable, re-renderable
  later) and `.txt` (plain text log). A cast-only recording needs no renderer.
  WebP preserves the rendered GIF's pixels and timing losslessly, usually in
  fewer bytes, and shares GIF's settings.
- **`Require 'cmd'…` lists what the recorded shell will run.** It fails before
  the session starts instead of leaving a `command not found` frame in the
  middle of the GIF. Skip it only for shell builtins and coreutils.
- **`SetOptimize 'on'` for any GIF or WebP committed to a repository** — a
  lossless `gifsicle -O3` pass for GIF, 12-25 % smaller, roughly doubling
  render time; for WebP the encoder's slowest lossless effort, a few per cent
  smaller for several times the encoding time. Without `gifsicle` installed
  `Render` warns and keeps the unoptimized GIF, so it is safe to leave on.
- `SetCols`/`SetRows` size the grid in **cells, not pixels**. Fit them to the
  content: a two-line demo in a 40-row terminal is mostly empty frame.
- `SetFontSize` is the only pixel setting; it scales the render without
  changing the grid the recorded shell sees. `Start` prints the resulting size
  per renderer (`::: GIF: 60 cols x 8 rows x 40px font -> 1488 x 432 px`) —
  read it back and adjust the grid or the font size before a render that is
  far off the size the user asked for.
- `SetFontFamily 'A, B'` takes a preferred list. For GIF and WebP, agg's
  default text-font chain follows it before the Nerd Font and emoji fallbacks;
  the first installed text family wins.
- The recorded shell is isolated by default: no personal rc files, no history,
  no user prompt in frame. Keep it that way unless the recording is *about*
  the user's setup (`SetPrompt 'native'`).
- `SetTypingSpeed` / `SetKeyDelay` set the defaults; every `Type` and key
  command still takes a per-call delay.
- `Env NAME value` exports into the recorded shell; repeatable.
- Playback is fixed at render time, not by re-recording: `SetPlaybackSpeed`,
  `SetFramerate`, `SetIdleTimeLimit` (caps long pauses), `SetLoop` and
  `SetLastFrameDuration` (GIF and WebP).
- A setting only one renderer supports is applied where it works, and `Render`
  reports the skipped output in yellow. Nothing fails, so a recording that
  writes both a GIF and an SVG may still use `SetWindowBar 'on'` (SVG) or
  `SetBoldIsBright 'on'` (GIF and WebP).

## 4. Body

- `Type` types, it never submits — follow it with `Enter`.
- **Quote for the recorded shell.** `Type 'echo $HOME'` in single quotes is
  expanded by the shell in the recording; double quotes expand it in the
  recording script instead, which is almost never what is wanted.
- **Split a long command line over several typed lines**, one clause each,
  each line ending in its own `Enter`: `Type '…'; Enter`. The recorded shell
  keeps prompting (`>`) until the command is complete, so it reaches the
  screen as a readable block instead of one wrapped line, and the script
  stays readable too. Break where the command has a seam — a `for … do`
  header, a complete command with all of its arguments, a `&&` or `|` link,
  the loop tail — never mid-argument, which would submit a syntax error.
  Indent continuation lines with spaces; `Tab` is completion in the recorded
  shell (a literal tab needs `Key C-v` then `Tab`):

  ```bash
  # Bad: the split lands inside printf's argument list
  Type 'for i in 1 2 3; do printf "%s\n" '
  Type '"line $i"; done'

  # Good: loop header, the command it runs, loop tail
  Type 'for i in 1 2 3; do'; Enter
  Type '  printf "line %s\n" "$i"'; Enter
  Type 'done'; Enter
  ```

  Keep a command that must run *after* the block on the closing line
  (`Type 'done; echo built'; Enter`): once the block is submitted the shell is
  busy, and anything typed then lands in the middle of its output.
- `Key` takes tmux notation for modified keys (`Key C-u`, `Key M-x`). Plain
  named keys are commands of their own: `Enter`, `Tab`, `Space`, `Backspace`,
  `Escape`, `Up`, `Down`, `Left`, `Right`, `PageUp`, `PageDown`, `Home`, `End`,
  `Insert`, `Delete` — each taking `[count] [delay]`, e.g. `Backspace 18 0.05`.
- `Copy 'text'` then `Paste` puts a whole line on screen in one frame — a
  recording-local tmux buffer sent as a bracketed paste, never the system
  clipboard.
- `Highlight 'text' [hold]` sweeps a selection across text **already on the
  visible pane**, the way a mouse drag would, then releases it; nothing is
  copied. Matching is literal and confined to a single row, and of several
  occurrences the one closest to the cursor wins — the output line, not the
  command echoed above it. Text that has not arrived yet is only warned about,
  so `Wait` for it first instead of trusting a `Sleep`.
  `SetHighlightColors 'colour214' 'black' 'bold'` picks the colors it is
  painted with, and `SetHighlightSpeed` how fast it sweeps - per call,
  `Highlight 'text' 1.5 0.01`.
- **Prefer `Wait` over `Sleep` for anything whose duration is not yours to
  decide.** Both `Wait` and `WaitLine` use extended regular expressions
  (`grep -E`); escape regex metacharacters when matching literal text. Anchor
  the pattern so it does not match the command echoed above the output:

  ```bash
  Type 'make build'
  Enter
  Wait '^build succeeded' 60
  ```

  `Wait` scans the whole pane; use `WaitLine` when the pattern must match the
  cursor's current row, such as a prompt that stays on screen
  (`WaitLine '^Username:$'`) or output that repeats earlier text.
- **End with a `Sleep` before `Render`**, or the last frame flashes by.
- Setup belongs off camera. Before `Show`, use `Run 'cmd' 0.5`; mid-recording,
  use `RunOffRecord`, which is `Hide` + `Run` + `Show` in one call. Recording
  resumes at the end of *every* `RunOffRecord`, so chain a command and its
  cleanup on one line rather than in two calls:

  ```bash
  RunOffRecord 'export STAGE=ready; clear' 0.5
  ```

- Repetition is a shell problem, not an s-vhs one:

  ```bash
  run() { Type "$1"; Enter; Sleep "${2:-1}"; }
  for command_line in 'uname -o' 'tput colors'; do run "$command_line"; done
  ```

## 5. Colored text

For a one-off, let the recorded shell do it — the command stays visible:

```bash
Type 'printf "\e[31mred \e[32mgreen\e[0m\n"'
Enter
```

To have text *appear already painted*, with no command on screen, hand the pane
to `cat` and type the escape sequences straight into it (this is how
[`examples/logo.rec.sh`](https://github.com/dimk90/s-vhs/blob/develop/examples/logo.rec.sh)
draws the project logo):

```bash
SetPrompt ''        # empty prompt: nothing but the payload reaches the screen
SetTypingSpeed 0    # escape sequences must not be typed at human speed

Start

# No echo and no line buffering, then wipe the line that asked for it
Run 'stty -echo -icanon min 1 time 0; clear'
# cat takes over the pane and echoes raw input, so escapes can be typed directly
Run 'cat'

Show

readonly WHITE=$'\e[38;2;255;255;255m'
readonly RESET=$'\e[0m'

Type "$WHITE"
Type 'painted as it appears' 0.03   # per-call delay for the visible text only
Type "$RESET"
Enter
Sleep 3

Render
```

## 6. SVG output

`SetOutput demo.svg` renders through `asg`: sharp at any zoom, animated by CSS,
usually smaller than the same recording as a GIF. Prefer it when the result is
displayed on a page that renders SVG animation, keep the GIF when it lands
somewhere that may not (some Markdown viewers, chat previews, social cards).

- An SVG **names** fonts instead of embedding them, so it looks different where
  the named family is missing. `asg` also draws cell backgrounds and the cursor
  on a fixed `0.6 × font-size` grid, so pick a face with a `0.6 em` advance —
  JetBrains Mono, Cascadia Mono, Liberation Mono — or text drifts out of its
  cells column by column.
- SVG-only framing: `SetPadding` (plus `SetPaddingX`/`SetPaddingY`),
  `SetWindowBar 'on'` for macOS-style decorations, `SetCursor 'off'`.
- Named themes are renderer-specific and an unknown name fails at `Render`,
  after the recording has already run. Pass a custom hex palette to `SetTheme`
  when one recording writes both a GIF and an SVG.
- Full list of pitfalls and workarounds:
  <https://github.com/dimk90/s-vhs/blob/develop/doc/SVG.md>.

## 7. Run

```bash
chmod +x demo.rec.sh && ./demo.rec.sh
```

`Start` prints the s-vhs version and a `tmux -L s-vhs attach -t <session>` line.
To watch the recording being driven, either attach with that command from
another terminal, or start the read-only viewer there — `./s-vhs.sh watch`, or
`curl -fsSL https://dimk90.github.io/s-vhs/latest | bash -s -- watch` without a
local copy — which waits for the session, follows it, and needs no tmux client. The session is named
after the script's PID (`s-vhs-$$`), so parallel runs never collide and need no
`SetSession`; call it only to pin a fixed, predictable attach target. Any exit,
including a mid-recording failure, tears the session down through the `EXIT`
trap installed at `source` time. Anything else the recording creates - a
`mktemp -d` fixture, a started server - is removed by registering a
`Finally 'rm -rf "$WORK_DIR"'` at creation time, single-quoted so it expands at
exit; a last line of cleanup only covers the take that succeeds, and a `Wait`
timeout is the most common way one does not.

## 8. Verify

A GIF, WebP or SVG cannot be reviewed by an agent — verify through the text log
instead. Add a `.txt` output (keep it if the project wants one, otherwise drop
the line after checking):

```bash
SetOutput "$SCRIPT_DIR/demo.txt"
```

Then grep the expected **command output**, not the typed text: typing is
recorded one character per event, so a typed string spans many events and will
not match, while output arrives in one chunk. An existing cast converts the
same way without re-recording:

```bash
asciinema convert -f txt demo.cast -
```

Then confirm each requested file exists and is non-empty — `Render` prints
`::: Wrote <path>` per output, and any yellow `::: ` line is a warning worth
reading back to the user.

State plainly that the animation itself was not viewed; ask the user to eyeball
it for timing and framing.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `Set…: settings cannot change after the session starts` | A setting moved below `Start`; all `Set*` belong to the configuration phase |
| `Start: configure at least one output with SetOutput` | No `SetOutput` call |
| `Start: session already exists` | A pinned `SetSession` name is taken, or a `SIGKILL`ed run left its session behind; `tmux -L s-vhs kill-server` |
| `Require: <cmd> is not installed, required for the recording` | The recording drives a command the machine lacks — install it or drop that step |
| `Wait: timeout waiting for: <pattern>` | The pattern never appeared — check the anchor and raise the timeout |
| `no faces matching font family options` | No `SetFontFamilyExact` family is installed, or no preferred or default agg text font is available |
| `SetFontFamily: cannot be combined with SetFontFamilyExact` | agg rejects both flags; pick one |
| Renderer rejects the theme name | Named themes differ between agg and asg; use a custom hex palette for both |
| `::: SetOptimize: gifsicle is not installed` | Warning only — the GIF was written unoptimized; WebP is unaffected |
| `::: Highlight: not on screen, nothing selected` | Warning only — the text had not arrived, or it wraps across two rows; `Wait` for it, or highlight a shorter part of it |
| `::: Set…: skipped for <output>` | Warning only — that renderer has no such option |
| Variable is empty in the recording | It was expanded by the recording script — use single quotes in `Type` |
| Setup commands are in the GIF | Move them above `Show`, or into `RunOffRecord` |
| Last frame flashes by | No `Sleep` before `Render` |
