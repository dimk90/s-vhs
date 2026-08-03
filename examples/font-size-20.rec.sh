#!/usr/bin/env bash
#
# The font size is the only pixel-sized setting: it scales the whole render
# without changing the 34x2 grid the recorded shell sees.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/font-size-20.gif"

SetCols 34
SetRows 2

SetFontSize 20
SetFontFamily "Iosevka Term"

# Reproducible prompt: no personal rc files, green ❯ prompt
SetShell "bash --norc"
Env PS1 '\[\e[32m\]❯\[\e[0m\] '

Start

Show

Type 'echo "Font size is 20"'
sleep 4

Render
