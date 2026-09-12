#!/usr/bin/env bash
#
# Encoding stress clip: the input `scripts/encoding-bench.sh` measures against.
#
# Packs what a terminal recording throws at an encoder into half a minute -
# small coloured text, a truecolor gradient, fast scrolling, a highlight sweep
# and two long static holds. Not an example recording: it is deliberately
# ugly, and it renders at a small font size on purpose.
#
# Usage: scripts/stress.rec.sh [output-dir]
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
OUTPUT_DIR="${1:-/tmp/s-vhs-encoding-bench}"

mkdir -p "$OUTPUT_DIR" || exit 1

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../s-vhs.sh" || exit 1

SetOutput "$OUTPUT_DIR/stress.gif"
SetOutput "$OUTPUT_DIR/stress.txt"

SetCols 100
SetRows 28
SetFontSize 20
SetTypingSpeed 0.02

Start
Show

# a 256-colour ramp of small digits: the hardest case for chroma subsampling
# every loop and escape below is expanded by the recorded shell
# shellcheck disable=SC2016
Type 'for i in $(seq 16 123); do printf "\e[38;5;${i}m%4d\e[0m" "$i"; done; echo'
Enter
Sleep 3

# fine colour detail without motion: white text over a truecolor gradient
# shellcheck disable=SC2016
Type 'for i in $(seq 0 79); do'; Enter
# shellcheck disable=SC2016
Type '  printf "\e[48;2;$((i*3));$((120-i));$((255-i*3))m\e[38;2;255;255;255m%s\e[0m" x'
Enter
Type 'done; echo'; Enter
Sleep 4

# a long static hold on a busy screen
Sleep 6

# fast scrolling: every frame differs from the one before it
# shellcheck disable=SC2016
Type 'for i in $(seq 1 400); do printf "\e[3%dmline %03d\e[0m  the quick brown fox jumps over the lazy dog\n" $((i%8)) "$i"; done'
Enter
Sleep 4

Type 'printf "\e[1;33m%s\e[0m\n" "s-vhs encoding stress clip: highlight this text"'
Enter
Wait 'highlight this text' 10
Sleep 1
Highlight 'encoding stress clip' 2
Sleep 2

# the final hold, the frame whose duration every encoder gets wrong
Sleep 6

Render
