#!/usr/bin/env bash
#
# Key presses take a repeat count and a delay after each press.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/enter.gif"

SetCols 34
SetRows 4
SetFontSize 40
SetFontFamily "Iosevka Term"

Start

Show

sleep 1

Key Enter 4 0.5
sleep 2

Render
