#!/usr/bin/env bash
#
# WaitLine polls only the cursor's current row, ignoring the same pattern
# elsewhere in the visible pane.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/wait-line.gif"

SetCols 44
SetRows 6
SetFontSize 40
SetFontFamily 'Iosevka Term'

Start

# The first Username: moves off the cursor row. Two seconds later, the same
# text becomes an interactive prompt on the current row.
# $username belongs to the recorded shell
# shellcheck disable=SC2016
Run 'ask() { printf "Username:\n"; sleep 2; read -r -p "Username: " username; printf "Hello, %s.\n" "$username"; }; clear' 1

Show

Type 'ask'
Enter

# Ignore the earlier Username: and continue only when the prompt is current
WaitLine '^Username:$'

Type 'Ada'
Enter
Sleep 2

Render
