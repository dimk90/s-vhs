#!/usr/bin/env bash
#
# SetPrompt dresses the recorded shell, SetShell picks the shell itself.
# This one records fish with the bundled powerline theme.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/prompt.gif"

SetCols 44
SetRows 5
SetFontSize 40

SetTheme 'nord'
SetLineHeight 1.3
SetFontFamily 'Iosevka Term'

# bash, zsh or fish - every theme is rendered for the shell in use
SetShell 'fish'

# Bundled prompts: arrow (the default), plain, path or powerline;
# SetPrompt 'native' would record the user's own prompt instead,
# and anything else is taken as a literal prompt
SetPrompt 'powerline'

Start
Show

# The theme follows the working directory
Type 'cd /tmp'
Key Enter; sleep 1.5

Type 'cd ~'
Key Enter; sleep 3

Render
