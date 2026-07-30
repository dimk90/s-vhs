#!/usr/bin/env bash
#
# Minimal s-vhs recording: type a command, run it, admire the output.
#
# Writes demo.gif into the current directory.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# The script may run from any directory, so resolve the library from its path.
# shellcheck source=s-vhs.sh
source "$SCRIPT_DIR/../s-vhs.sh"

# Where should we write the GIF?
SetOutput 'demo.gif'

# Set up an 80x20 terminal with a 28px font.
SetCols 80
SetRows 20
SetFontSize 28

# Start the terminal, then the recorder.
start_session
record

# Type a command in the terminal.
type_text "echo 'Welcome to S-VHS!'"

# Pause for dramatic effect...
sleep 0.5

# Run the command by pressing enter.
key Enter

# Admire the output for a bit.
sleep 5

# Stop recording and write every requested output.
render
