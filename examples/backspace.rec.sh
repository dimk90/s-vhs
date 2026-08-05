#!/usr/bin/env bash
#
# Backspace is a tmux key name (BSpace), and takes the same repeat count as
# every other key.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/backspace.gif"

SetCols 44
SetRows 4
SetFontSize 40
SetFontFamily "Iosevka Term"

Start

Show

Type 'echo delete anything...' 0.05
sleep 0.5

# Backspace 18 -- back to 'echo '
Key BSpace 18 0.05
sleep 0.5

Type 'nothing'
Key Enter
sleep 2

Render
