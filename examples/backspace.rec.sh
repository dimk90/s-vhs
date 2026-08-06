#!/usr/bin/env bash
#
# Backspace takes the same repeat count and delay as every other named key.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/backspace.gif"

SetCols 44
SetRows 4
SetFontSize 40
SetFontFamily "Iosevka Term"

Start

Show

Type 'echo delete anything...' 0.05
Sleep 0.5

# Backspace 18 -- back to 'echo '
Backspace 18 0.05
Sleep 0.5

Type 'nothing'
Enter
Sleep 2

Render
