#!/usr/bin/env bash
#
# SetFontFamily takes a list and names the text font only, so two fallbacks
# are at work here: 'Some Fancy Font' is not installed anywhere, so the
# renderer skips it and picks Fira Code, and the powerline and devicon glyphs
# below come from the bundled Symbols Nerd Font rather than from either.
#
# Use SetFontFamilyExact instead to pin the complete list and drop the bundled
# fallbacks; the same glyphs then render as tofu.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/font-family.gif"

SetCols 44
SetRows 6
SetFontSize 40

# The first family that exists on the rendering machine wins
SetFontFamily 'Some Fancy Font, Fira Code'

# Reproducible prompt: no personal rc files, green ❯ prompt
SetShell "bash --norc"
Env PS1 '\[\e[32m\]❯\[\e[0m\] '

Start

Show

Type 'echo "    fallback to Fira Code + bundled Nerd Symbols"'
Key Enter
sleep 3

Render
