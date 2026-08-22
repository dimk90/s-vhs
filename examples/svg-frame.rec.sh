#!/usr/bin/env bash
#
# Padding, window decorations and the cursor are asg settings, so this
# recording asks for SVG output alone - with a GIF next to it, Render would
# report every one of them as skipped.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/svg-frame.svg"

SetCols 44
SetRows 4
SetFontSize 40

# An SVG names fonts instead of embedding them, and asg lays cells out on a
# fixed 0.6 x font-size grid; JetBrains Mono has exactly that advance
SetFontFamily 'JetBrains Mono'

# macOS-style bar with three buttons above the terminal
SetWindowBar 'on'

SetPadding 20
# Both axes are padded by SetPadding; SetPaddingX widens the left and right
# gap alone, SetPaddingY does the same above and below
SetPaddingX 40

# Without a cursor the frame reads like a screenshot of finished output
SetCursor 'off'

Start

Show

Type 'echo "framed, padded and calm"'
Enter
Sleep 3

Render
