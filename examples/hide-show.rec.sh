#!/usr/bin/env bash
#
# The session and the recorder are separate: everything before Show and
# between Hide and the next Show happens in the same live terminal, but never
# reaches the GIF. Every Show appends one more segment to the same recording.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/hide-show.gif"

SetCols 44
SetRows 4
SetFontSize 40
SetFontFamily "Iosevka Term"

Start

# Off camera: export the variable and wipe the screen it was typed on
Run 'export HIDDEN=wow' 0.5
Run 'clear' 0.5

Show # Start recording

# The recorded shell expands it, not this script
Type 'echo $HIDDEN'
Key Enter
sleep 2

Hide # Stop recording, the session keeps running

# Off camera again: noise nobody will ever see, and a clean screen to return to
Run 'echo "nobody will ever see this"' 0.5
Run 'clear' 0.5

Show # Resume recording, appending to the same cast

Type 'echo "back on camera"'
Key Enter
sleep 2

Render
