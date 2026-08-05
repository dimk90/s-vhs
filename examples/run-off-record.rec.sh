#!/usr/bin/env bash
#
# RunOffRecord is Hide + Run + Show in one call: the command runs in the live
# session, and the recording continues into the same cast without it. Handy
# for the short setup steps in between — an export, a clear.
#
# Recording resumes at the end of every call, so a screen left dirty by one
# command is on camera again before the next call hides it: chain such steps
# in a single command line instead.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/run-off-record.gif"

SetCols 44
SetRows 4
SetFontSize 40
SetFontFamily "Iosevka Term"

Start
Show

# The variable is unset, so the recorded shell echoes an empty line
Type 'echo $STAGE'
Enter
sleep 2

# Off camera: set it, then wipe the screen it was typed on
RunOffRecord 'export STAGE=ready; clear' 0.5

Type 'echo $STAGE'
Enter
sleep 2

Render
