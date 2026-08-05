#!/usr/bin/env bash
#
# Minimal s-vhs recording: type a command, run it, admire the output.
# Writes quick-start.gif next to this script.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# The script may run from any directory, so resolve the library from its path
source "$SCRIPT_DIR/../s-vhs.sh"

# Where should we write the GIF?
SetOutput "$SCRIPT_DIR/quick-start.gif"

# Set up a 60x4 terminal with a 40px font
SetCols 60
SetRows 4
SetFontSize 40
SetFontFamily 'Iosevka Term'

# Start the terminal, then the recorder
Start
Show

# Type a command in the terminal
Type "echo 'Welcome to S-VHS!"
Sleep 1 # Pause for dramatic effect...

Type " Stay awhile and listen...'"
Sleep 1

# Run the command by pressing enter
Enter

# Admire the output for a bit
Sleep 5

# Stop recording and write every requested output
Render
