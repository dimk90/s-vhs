#!/usr/bin/env bash
#
# SetTheme pins the palette of the render, so a recording looks the same on
# every machine.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/theme.gif"

SetCols 50
SetRows 4
SetFontSize 40
SetFontFamily "Iosevka Term"
SetTypingSpeed 0.04

# One of the renderer's named themes; a comma-separated hex palette
# (background, foreground, then 8 or 16 colors) also works
SetTheme 'kanagawa'

# Reproducible prompt: no personal rc files, a green arrow
SetShell "env PS1='\[\e[32m\]❯\[\e[0m\] ' bash --norc"

Start
Show

Type 'printf "\e[31mred \e[32mgreen \e[34mblue\e[0m\n"'
Key Enter
sleep 3

Render
