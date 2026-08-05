#!/usr/bin/env bash
#
# Wait polls the visible pane until a pattern shows up, so a recording keeps
# up with a slow command instead of guessing a sleep.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/wait.gif"

SetCols 44
SetRows 5
SetFontSize 40
SetFontFamily "Iosevka Term"

Start

Show

Type 'sleep 2 && echo "build succeeded"'
Enter

# Anchored: the pattern must match the output line, not the command echoed
# above it
Wait '^build succeeded'

Type 'echo "and on we go"'
Enter
Sleep 2

Render
