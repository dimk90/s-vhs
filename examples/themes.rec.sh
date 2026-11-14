#!/bin/bash
#
# Record every bundled palette with the same ANSI text and color swatches.
# Run from any directory; GIF and SVG samples go into themes/.
#

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

mkdir -p "$SCRIPT_DIR/themes"

for THEME in asciinema atom-one dracula github-dark github-light gruvbox-dark \
             gruvbox-light kanagawa kanagawa-dragon kanagawa-light monokai nord \
             solarized-dark solarized-light; do
    (
        # Each recording gets fresh settings and its own cleanup trap
        # shellcheck source=s-vhs.sh
        source "$SCRIPT_DIR/../s-vhs.sh"

        SetOutput "$SCRIPT_DIR/themes/${THEME}.gif"
        SetOutput "$SCRIPT_DIR/themes/${THEME}.svg"
        SetTheme "$THEME"
        SetCols 44
        SetRows 11
        SetFontSize 40
        SetFontFamily 'Liberation Mono'
        SetTypingSpeed 0.03
        SetOptimize 'on'
        Env 'THEME' "$THEME"

        Start

        # Paint before Show so even a non-animated preview displays the palette
        # Literal variables belong to the recorded shell
        # shellcheck disable=SC2016
        Run 'clear; printf "%s\n\n Standard ANSI colors\n" "$THEME"; for color in {0..7}; do printf "\033[38;5;%sm %02d \033[0m" "$color" "$color"; done; printf "\n"; for color in {0..7}; do printf "\033[48;5;%sm    \033[0m" "$color"; done; printf "\n Bright ANSI colors\n"; for color in {8..15}; do printf "\033[38;5;%sm %02d \033[0m" "$color" "$color"; done; printf "\n"; for color in {8..15}; do printf "\033[48;5;%sm    \033[0m" "$color"; done; printf "\n"'

        Show
        Type 'printf "Same palette in GIF and SVG\n"'
        Enter 1
        Wait '^Same palette in GIF and SVG'
        Sleep 2

        Render
    )
done
