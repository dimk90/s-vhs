#!/usr/bin/env bash
#
# Require checks the commands a recording depends on before anything starts,
# and Env hands the recorded shell the variables those commands need - here a
# git identity, so the commit below does not depend on the host's git config.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/require-env.gif"

SetCols 52
SetRows 6
SetFontSize 40
SetFontFamily 'Iosevka Term'

# Reported now, not as a "command not found" frame in the middle of the GIF
Require 'git'

Env 'GIT_AUTHOR_NAME' 'Ada Lovelace'
Env 'GIT_AUTHOR_EMAIL' 'ada@example.com'
Env 'GIT_COMMITTER_NAME' 'Ada Lovelace'
Env 'GIT_COMMITTER_EMAIL' 'ada@example.com'

Start

# Off camera: an empty repository in a throwaway directory
# mktemp runs in the recorded shell
# shellcheck disable=SC2016
Run 'cd "$(mktemp -d)" && git init -q . && clear' 1

Show

Type 'git commit -q --allow-empty -m "recorded"'
Enter; Sleep 1

Type 'git log -1 --format="%an <%ae>"'
Enter; Sleep 2.5

Render
