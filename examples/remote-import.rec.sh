#!/usr/bin/env bash
#
# Import a pinned s-vhs release directly from GitHub, without keeping a
# local copy. Waiting for the process substitution catches a failed download.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck disable=SC1090
source <(curl -fsSL https://dimk90.github.io/s-vhs/v0.2.0) && wait "$!" || exit 1

SetOutput "$SCRIPT_DIR/remote-import.gif"

SetCols 44
SetRows 4
SetFontSize 40
SetFontFamily 'Iosevka Term'

Start
Show

Type "printf 'Imported s-vhs %s\\n' '$(svhs_version)'"
Enter
Sleep 3

Render
