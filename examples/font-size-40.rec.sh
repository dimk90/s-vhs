#!/usr/bin/env bash
#
# The font size is the only pixel-sized setting: it scales the whole render
# without changing the 34x2 grid the recorded shell sees.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/font-size-40.gif"

SetCols 34
SetRows 2

SetFontSize 40
SetFontFamily "Iosevka Term"

Start

Show

Type 'echo "Font size is 40"'
Sleep 4

Render
