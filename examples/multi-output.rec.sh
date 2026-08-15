#!/usr/bin/env bash
#
# SetOutput is repeatable: one recording, several outputs. The cast is kept at
# the requested path and stays replayable with `asciinema play`, so the GIF and
# the SVG can be re-rendered from it at any size.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/multi-output.cast"
SetOutput "$SCRIPT_DIR/multi-output.gif"
SetOutput "$SCRIPT_DIR/multi-output.svg"

SetCols 44
SetRows 4
SetFontSize 40
# An SVG names fonts instead of embedding them, so the viewer's system picks the
# face, while asg lays every cell out on a fixed 0.6 x font-size grid. JetBrains
# Mono is one of the few monospace fonts with exactly that advance, so its glyphs
# stay in their cells instead of drifting away from the cursor and the
# backgrounds asg draws for them.
SetFontFamily "JetBrains Mono"

Start

Show

Type 'echo "one recording, three outputs"'
Enter
Sleep 2

Render
