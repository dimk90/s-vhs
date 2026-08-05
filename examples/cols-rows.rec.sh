#!/usr/bin/env bash
#
# The terminal is sized in cells, not pixels: the session really is 40 columns
# by 8 rows, and the GIF resolution follows from the font size.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/cols-rows.gif"

SetCols 40
SetRows 8
SetFontSize 40
SetFontFamily "Iosevka Term"

Start

Show

# Ask the terminal itself how wide and how tall it is
Type 'tput cols'
Enter
sleep 1

Type 'tput lines'
Enter
sleep 1

Enter 3 0.5
sleep 5

Render
