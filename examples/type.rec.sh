#!/usr/bin/env bash
#
# Type emulates a human at the keyboard, one character at a time.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/type.gif"

SetCols 44
SetRows 5
SetFontSize 40
SetFontFamily "Iosevka Term"

Start

Show

Type 'echo "whatever you want"'
Sleep 1

Enter
Sleep 0.5

Type 'echo "slow down"' 0.25 # Slow typing

Enter
Sleep 4

Render
