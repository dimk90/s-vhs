#!/usr/bin/env bash
#
# Type the colourful S-VHS logo used at the top of the README.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

readonly LOGO_TYPING_SPEED=0.007
readonly REC_TYPING_SPEED=0.04

SetOutput "$SCRIPT_DIR/logo.gif"

SetCols 39
SetRows 11
SetFontSize 40
SetFontFamily 'Iosevka Term'
SetLineHeight 1.0
SetTypingSpeed 0

# Empty prompt: nothing but the logo may reach the screen
SetPrompt ''

readonly LOGO_COLOR=$'\e[38;2;255;255;255m'
readonly REC_COLOR=$'\e[38;2;255;75;85m'
readonly TITLE_COLOR=$'\e[38;2;238;240;245m'
readonly MUTED_COLOR=$'\e[38;2;139;148;158m'
readonly RESET_COLOR=$'\e[0m'

LOGO=(
    '███████╗    ██╗   ██╗██╗  ██╗███████╗'
    '██╔════╝    ██║   ██║██║  ██║██╔════╝'
    '███████╗ ██ ██║   ██║███████║███████╗'
    '╚════██║ ██ ╚██╗ ██╔╝██╔══██║╚════██║'
    '███████║     ╚████╔╝ ██║  ██║███████║'
    '╚══════╝      ╚═══╝  ╚═╝  ╚═╝╚══════╝'
)

Start

# No echo and no line buffering, then wipe the line that asked for it
Run 'stty -echo -icanon min 1 time 0; clear'

# cat takes over the pane and echoes raw input, so the logo can be typed
# directly; submitting this line also leaves the first blank row above it
Run 'cat'

Show

# Skip one more line
Key Enter

Type "$LOGO_COLOR"
for logo_line in "${LOGO[@]}"; do
    Type " $logo_line" $LOGO_TYPING_SPEED
    Type $'\n'
done

Type "$REC_COLOR"
Type ' ● REC' $REC_TYPING_SPEED
Type '       ' $REC_TYPING_SPEED
Type "$TITLE_COLOR"
Type 'SUPER VHS' $REC_TYPING_SPEED
Type '      ' $REC_TYPING_SPEED
Type "$MUTED_COLOR"
Type 'SP 0:00:00' $REC_TYPING_SPEED
Type "$RESET_COLOR"

Key Enter 2
sleep 6

Render
