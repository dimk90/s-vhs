#!/usr/bin/env bash
#
# A recording script is a shell script, so loops, variables and functions come
# for free - no tape language to extend.
#

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/../s-vhs.sh"

SetOutput "$SCRIPT_DIR/shell-power.gif"

SetCols 44
SetRows 10
SetFontSize 40
SetFontFamily "Iosevka Term"

# Reproducible prompt: no personal rc files, a green arrow
SetShell "env PS1='\[\e[32m\]❯\[\e[0m\] ' bash --norc"

# Run a command in the recorded shell and let its output settle
run() {
    Type "$1"
    Key Enter
    sleep "${2:-1}"
}

Start
Show

# "for" is redundant here - only for demo purpose
for command_line in 'uname -o' 'tput colors' 'echo $BASH_VERSION'; do
    run "$command_line"
done
sleep 1

Render
