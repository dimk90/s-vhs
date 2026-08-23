#!/usr/bin/env bash
#
# The timing of a rendered animation is decided at render time, not while
# recording: the cast keeps its own pace and every setting below only changes
# the GIF made from it.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/playback.gif"

SetCols 48
SetRows 8
SetFontSize 40
SetFontFamily 'Iosevka Term'

# Typing and output play back in half the recorded time
SetPlaybackSpeed 2

# Smoother motion than the 30 fps default, at the cost of GIF size
SetFramerate 60

# Hold the last frame for a second instead of the default three
SetLastFrameDuration 1

# Play once and stop - this GIF freezes on its last frame
SetLoop 'off'

Start

Show

# The recorded shell prints five lines, 0.4s apart
Type 'for i in 1 2 3 4 5; do'; Enter
# $i belongs to the recorded shell
# shellcheck disable=SC2016
Type '  printf "frame %d\n" "$i"; sleep 0.4'; Enter
Type 'done'; Enter

Wait '^frame 5'
Sleep 1

Render
