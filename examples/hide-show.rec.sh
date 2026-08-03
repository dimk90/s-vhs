#!/usr/bin/env bash
#
# The session and the recorder are separate: everything before Show and after
# Hide happens in the same live terminal, but never reaches the GIF.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/hide-show.gif"

SetCols 44
SetRows 4
SetFontSize 40
SetFontFamily "Iosevka Term"

# Reproducible prompt: no personal rc files
SetShell "bash --norc"

Start

# Change prompt style to green ❯
Run "PS1='\[\e[32m\]❯\[\e[0m\] '"
Run "clear"

# Off camera: export the variable and wipe the screen it was typed on
Run 'export HIDDEN=wow' 0.5
Run 'clear' 0.5

Show # Start recording

# The recorded shell expands it, not this script
Type 'echo $HIDDEN'
Key Enter
sleep 2

Hide # Stop recording, the session keeps running

Run 'echo "nobody will ever see this"' 0.5

Render
