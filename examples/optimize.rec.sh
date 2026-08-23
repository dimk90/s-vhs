#!/usr/bin/env bash
#
# SetOptimize runs a lossless gifsicle pass over the rendered GIF. A long,
# scrolling recording like this build log is where it pays off most.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/optimize.gif"

SetCols 58
SetRows 10
SetFontSize 40
SetFontFamily "Iosevka Term"
SetTypingSpeed 0.04

# Needs gifsicle - without it the GIF is written unoptimized
SetOptimize 'on'

Start

Show

# The recorded shell runs the loop, printing 30 colored lines that scroll.
Type 'for i in $(seq 1 30); do'; Enter
Type '  printf "\e[3%dm==>\e[0m compiled src/module_%02d.rs\n" $((i % 6 + 1)) $i'; Enter
Type '  sleep 0.08'; Enter
Type 'done; echo done'
Sleep 1
Enter

# Anchored: the loop is slower than its sleeps, so wait for its last line
Wait '^done'
Sleep 2

Render
