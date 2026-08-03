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

# Reproducible prompt: no personal rc files
SetShell "bash --norc"

Start

# Change prompt style to green ❯
Run "PS1='\[\e[32m\]❯\[\e[0m\] '"
Run "clear"

Show

sleep 1

Key Enter 4 0.5
sleep 2

Render
