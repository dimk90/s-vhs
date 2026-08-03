#!/usr/bin/env bash
#
# Modifiers use tmux notation: Ctrl+R is 'C-r', Alt+X is 'M-x', and
# Ctrl+Alt+Shift+P is 'C-M-S-p'.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/ctrl.gif"

SetCols 44
SetRows 3
SetFontSize 40
SetFontFamily "Iosevka Term"

# Reproducible prompt: no personal rc files, green ❯ prompt
SetShell "bash --norc"
Env PS1 '\[\e[32m\]❯\[\e[0m\] '

Start

Show

Type 'echo "whatever you want"'
sleep 1

# Throw the line away without running it
Key C-u
sleep 0.5

# Type something else
Type 'echo "something else"'
Key Enter
sleep 2

Render
