#!/usr/bin/env bash
#
# Highlight sweeps a selection across text already on screen, the way a mouse
# drag would, and SetHighlightColors picks the colors it is painted with.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/highlight.gif"

SetCols 46
SetRows 4
SetFontSize 40
SetFontFamily 'Iosevka Term'
SetOptimize 'on'

# A tmux style: background, text color, then the attributes to draw it with
SetHighlightColors 'colour214' 'black' 'bold'

# Seconds per swept cell; a Highlight call may override it
SetHighlightSpeed 0.04

Start

Show

Type 'echo "s-vhs records what VHS cannot"'
Enter
Sleep 1

# The text is matched on the visible pane, so the echoed command line above
# the output is a match too - the one closest to the cursor wins
Highlight 'VHS cannot' 1.5

Sleep 1

Render
