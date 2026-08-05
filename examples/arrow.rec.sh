#!/usr/bin/env bash
#
# Arrow keys move the cursor around the line, repeated as many times as asked.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/arrow.gif"

SetCols 44
SetRows 4

SetFontSize 40
SetFontFamily "Iosevka Term"

Start

Show

Type 'echo navigate around'
sleep 0.5

# Left 10 -- ten presses, an eighth of a second apart
Left 10 0.12
sleep 0.5

Right 10 0.05

Enter
sleep 2

Render
