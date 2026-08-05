#!/usr/bin/env bash
#
# SetOutput is repeatable: one recording, several outputs. The cast is kept at
# the requested path and stays replayable with `asciinema play`, so the GIF can
# be re-rendered from it at any size.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/multi-output.cast"
SetOutput "$SCRIPT_DIR/multi-output.gif"

SetCols 44
SetRows 4
SetFontSize 40
SetFontFamily "Iosevka Term"

Start

Show

Type 'echo "one recording, two outputs"'
Enter
Sleep 2

Render
