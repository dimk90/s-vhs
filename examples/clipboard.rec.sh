#!/usr/bin/env bash
#
# Copy fills a tmux buffer private to this recording and Paste inserts it as a
# bracketed paste, so the whole string lands in one frame instead of being
# typed character by character.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/clipboard.gif"

SetCols 44
SetRows 6
SetFontSize 40
SetFontFamily 'Iosevka Term'

Start

Show

# Nothing reaches the screen here: the text goes to the tmux buffer, and the
# system clipboard is left alone
Copy 'https://github.com/dimk90/s-vhs'

Type 'echo '
Sleep 0.5

Paste
Sleep 1

Enter
Sleep 2

Render
