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

# Reproducible prompt: no personal rc files, a green arrow
SetShell "env PS1='\[\e[32m\]❯\[\e[0m\] ' bash --norc"

Start
Show

Type 'sleep 2 && echo "build succeeded"'
Key Enter

# Anchored: the pattern must match the output line, not the command echoed
# above it. Give up after 10 seconds instead of hanging forever
Wait '^build succeeded' 10

Type 'echo "and on we go"'
Key Enter
sleep 2

Render
