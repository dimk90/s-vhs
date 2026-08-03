#!/usr/bin/env bash
#
# The font size is the only pixel-sized setting: it scales the whole render
# without changing the 34x2 grid the recorded shell sees.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/font-size-10.gif"

SetCols 34
SetRows 2

SetFontSize 10
SetFontFamily "Iosevka Term"

# Reproducible prompt: no personal rc files
SetShell "bash --norc"

Start

# Change prompt style to green ❯
Run "PS1='\[\e[32m\]❯\[\e[0m\] '"
Run "clear"

Show

Type 'echo "Font size is 10"'
sleep 4

Render
