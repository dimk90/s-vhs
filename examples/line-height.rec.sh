#!/usr/bin/env bash
#
# SetLineHeight spreads the rows apart in the render; the recorded terminal is
# unaffected.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/line-height.gif"

SetCols 34
SetRows 6
SetFontSize 40
SetFontFamily "Iosevka Term"

# Roomy; the default is 1.2
SetLineHeight 1.8

# Reproducible prompt: no personal rc files, green ❯ prompt
SetShell "bash --norc"
Env PS1 '\[\e[32m\]❯\[\e[0m\] '

Start

Show

Type 'echo "stay"'
Key Enter
sleep 0.5
Type 'echo "far away!"'
Key Enter
sleep 2

Render
