#!/bin/bash
#
# s-vhs — shared helpers for agg + asciinema + tmux demo recordings.
# Meant to be sourced by a recording script; executing it only scaffolds one:
# `s-vhs.sh new demo.rec.sh`.
#
# Requires:  bash 3.2+ — the version macOS still ships as /bin/bash.
# Homepage:  https://github.com/dimk90/s-vhs
# License:   MIT
# Copyright: (c) 2026 Dmitry Makarov
#

# Stop on an unhandled command failure (-e), use of an unset variable (-u),
# or failure within a pipeline (-o pipefail), so the EXIT trap can clean up.
set -euo pipefail


## Version


svhs_version() {
    printf '%s\n' '0.1.0'
}


## Settings / Defaults


# A shared named socket isolates recordings from the user's default tmux server
_SVHS_TMUX_SOCKET='s-vhs'

# The PID of the recording script keeps parallel recordings from colliding on
# the default name; SetSession pins a fixed one when it should be attachable
_SVHS_SESSION="s-vhs-$$"
_SVHS_OUTPUTS=()

# Terminal geometry is in cells, not pixels
_SVHS_COLS=100
_SVHS_ROWS=40

# Empty families let agg use its built-in default fonts.
# The plain family is rendered through agg's text-font slot,
# which keeps the bundled Symbols Nerd Font and emoji fallbacks
_SVHS_FONT_FAMILY=''

# The exact one replaces the whole chain - no fallbacks to other fonts
_SVHS_FONT_FAMILY_EXACT=''

# Font size define output resolution ~ COLS*ROWS*FONT_SIZE
_SVHS_FONT_SIZE=28
_SVHS_LINE_HEIGHT=1.2

# Headless recording cannot inspect the host theme; pin rendering instead
_SVHS_THEME='dracula'

# Shell run inside the tmux session. s-vhs assembles the isolation flags and
# injects the prompt itself, so the shell has to be one it knows;
# bash is the safe default - present everywhere
_SVHS_SHELL='bash'

# Prompt of the recorded shell: a bundled theme, a literal prompt, or 'native'
# for the user's own rc files. See SetPrompt
_SVHS_PROMPT='arrow'
_SVHS_PROMPT_MODE='theme'

# Bundled themes, rendered per shell by _svhs_theme_prompt
_SVHS_PROMPT_THEMES='arrow plain path powerline'

# Glyphs the themes draw with, spelled as bytes to keep this file ASCII:
# U+276F, the arrow, and U+E0B0, the powerline separator - a private-use glyph
# agg draws from the Nerd Font it bundles
_SVHS_PROMPT_ARROW=$'\xe2\x9d\xaf'
_SVHS_POWERLINE_SEPARATOR=$'\xee\x82\xb0'

# NAME=VALUE pairs exported into the recorded shell by Env
_SVHS_ENV=()

# Delays are in seconds
_SVHS_TYPING_SPEED=0.07
_SVHS_KEY_DELAY=0.0

# How often tmux is polled, and how long the recorder may take to attach
_SVHS_POLL_INTERVAL=0.2
_SVHS_ATTACH_TIMEOUT=5

# The recorder flushes every event, so a write lands within milliseconds and
# is polled far more tightly than tmux
_SVHS_WRITE_POLL_INTERVAL=0.01
_SVHS_WRITE_TIMEOUT=5

# The recorded shell's command line and the environment it needs, assembled
# by Start from the configured shell and prompt
_SVHS_SHELL_COMMAND=()
_SVHS_SHELL_ENV=()

# Session and recorder lifecycle state
_SVHS_STARTED=0
_SVHS_CAST=''
_SVHS_TEMP_CAST=''
_SVHS_REC_PID=''
_SVHS_RECORDED=''


## Template


_SVHS_TEMPLATE=$(cat <<TEMPLATE
#!/usr/bin/env bash

# shellcheck disable=SC1090
source <(curl -fsSL https://dimk90.github.io/s-vhs/v$(svhs_version)) && wait "\$!" || exit 1

SetOutput 'demo.gif'

# SetCols 100
# SetRows 40
# SetFontSize 28
# SetFontFamily 'JetBrains Mono'
# SetTheme 'dracula'
# SetTypingSpeed 0.07
# SetShell 'bash'
# SetPrompt 'arrow'

Start
Show

Type 'echo "Hello from s-vhs"'
Enter
Sleep 3

Render
TEMPLATE
)


SetOutput() {
    #
    # Add a cast or GIF output for the recording.
    #
    # Parameters:
    #   $1 - output - path ending in .cast or .gif.
    #
    # Example:
    #   SetOutput 'demo.gif' || exit 1
    #
    local output="${1-}"

    _svhs_require_configuration_phase 'SetOutput' || return 1

    case "$output" in
        *.cast|*.gif) ;;
        '')
            printf 'SetOutput: output path must not be empty\n' >&2
            return 1
            ;;
        *)
            printf 'SetOutput: unsupported output extension: %s\n' "$output" >&2
            return 1
            ;;
    esac

    _SVHS_OUTPUTS+=("$output")
}


SetSession() {
    #
    # Set the tmux session name used for the recording.
    #
    # Parameters:
    #   $1 - session - non-empty tmux session name.
    #
    # Example:
    #   SetSession 'demo' || exit 1
    #
    local session="${1-}"

    _svhs_require_configuration_phase 'SetSession' || return 1

    if [[ -z $session ]]; then
        printf 'SetSession: session name must not be empty\n' >&2
        return 1
    fi

    _SVHS_SESSION="$session"
}


SetCols() {
    #
    # Set the terminal width in character cells.
    #
    # Parameters:
    #   $1 - cols - positive integer column count.
    #
    # Example:
    #   SetCols 80 || exit 1
    #
    local cols="${1-}"

    _svhs_require_configuration_phase 'SetCols' || return 1

    if ! _svhs_is_positive_integer "$cols"; then
        printf 'SetCols: expected a positive integer, got: %s\n' "$cols" >&2
        return 1
    fi

    _SVHS_COLS="$cols"
}


SetRows() {
    #
    # Set the terminal height in character cells.
    #
    # Parameters:
    #   $1 - rows - positive integer row count.
    #
    # Example:
    #   SetRows 30 || exit 1
    #
    local rows="${1-}"

    _svhs_require_configuration_phase 'SetRows' || return 1

    if ! _svhs_is_positive_integer "$rows"; then
        printf 'SetRows: expected a positive integer, got: %s\n' "$rows" >&2
        return 1
    fi

    _SVHS_ROWS="$rows"
}


SetFontFamily() {
    #
    # Set the font family used to render text, keeping the renderer's Nerd
    # Font and emoji fallbacks.
    #
    # Parameters:
    #   $1 - font_family - non-empty font family name.
    #
    # Example:
    #   SetFontFamily 'Iosevka Term' || exit 1
    #
    local font_family="${1-}"

    _svhs_require_configuration_phase 'SetFontFamily' || return 1

    if [[ -z $font_family ]]; then
        printf 'SetFontFamily: font family must not be empty\n' >&2
        return 1
    fi
    # agg rejects both font family flags at once, so catch the clash here
    # rather than after the whole recording is done
    if [[ -n $_SVHS_FONT_FAMILY_EXACT ]]; then
        printf 'SetFontFamily: cannot be combined with SetFontFamilyExact\n' >&2
        return 1
    fi

    _SVHS_FONT_FAMILY="$font_family"
}


SetFontFamilyExact() {
    #
    # Set the complete font family list, bypassing the renderer's Nerd Font
    # and emoji fallbacks; glyphs missing from the list render as tofu.
    #
    # Parameters:
    #   $1 - font_family - non-empty comma-separated family list, starting
    #        with a monospace text font.
    #
    # Example:
    #   SetFontFamilyExact 'Iosevka Term,Noto Color Emoji' || exit 1
    #
    local font_family="${1-}"

    _svhs_require_configuration_phase 'SetFontFamilyExact' || return 1

    if [[ -z $font_family ]]; then
        printf 'SetFontFamilyExact: font family must not be empty\n' >&2
        return 1
    fi
    if [[ -n $_SVHS_FONT_FAMILY ]]; then
        printf 'SetFontFamilyExact: cannot be combined with SetFontFamily\n' >&2
        return 1
    fi

    _SVHS_FONT_FAMILY_EXACT="$font_family"
}


SetFontSize() {
    #
    # Set the rendered font size in pixels.
    #
    # Parameters:
    #   $1 - font_size - positive integer pixel size.
    #
    # Example:
    #   SetFontSize 28 || exit 1
    #
    local font_size="${1-}"

    _svhs_require_configuration_phase 'SetFontSize' || return 1

    if ! _svhs_is_positive_integer "$font_size"; then
        printf 'SetFontSize: expected a positive integer, got: %s\n' "$font_size" >&2
        return 1
    fi

    _SVHS_FONT_SIZE="$font_size"
}


SetLineHeight() {
    #
    # Set the renderer's line-height multiplier.
    #
    # Parameters:
    #   $1 - line_height - positive number.
    #
    # Example:
    #   SetLineHeight 1.2 || exit 1
    #
    local line_height="${1-}"

    _svhs_require_configuration_phase 'SetLineHeight' || return 1

    if ! _svhs_is_positive_number "$line_height"; then
        printf 'SetLineHeight: expected a positive number, got: %s\n' "$line_height" >&2
        return 1
    fi

    _SVHS_LINE_HEIGHT="$line_height"
}


SetTheme() {
    #
    # Set an agg theme name or custom palette value.
    #
    # Parameters:
    #   $1 - theme - non-empty value passed to agg --theme.
    #
    # Example:
    #   SetTheme 'kanagawa' || exit 1
    #
    local theme="${1-}"

    _svhs_require_configuration_phase 'SetTheme' || return 1

    if [[ -z $theme ]]; then
        printf 'SetTheme: theme must not be empty\n' >&2
        return 1
    fi

    _SVHS_THEME="$theme"
}


SetShell() {
    #
    # Set the shell run inside the tmux session. s-vhs adds the isolation
    # flags and the prompt itself, so the shell has to be one it knows; one
    # that is not installed falls back to bash rather than failing the
    # recording.
    #
    # Parameters:
    #   $1 - shell - 'bash', 'zsh' or 'fish'.
    #
    # Example:
    #   SetShell 'fish' || exit 1
    #
    local shell="${1-}"

    _svhs_require_configuration_phase 'SetShell' || return 1

    case "$shell" in
        bash|zsh|fish) ;;
        *)
            printf 'SetShell: expected bash, zsh or fish, got: %s\n' "$shell" >&2
            return 1
            ;;
    esac

    if ! command -v "$shell" > /dev/null 2>&1; then
        printf '::: SetShell: %s is not installed, falling back to bash\n' "$shell"
        shell='bash'
    fi

    _SVHS_SHELL="$shell"
}


SetPrompt() {
    #
    # Set the prompt of the recorded shell. A theme or a literal prompt also
    # keeps the shell out of the user's rc files, so the recording looks the
    # same on any machine; 'native' keeps the user's own configuration,
    # prompt and aliases included.
    #
    # Parameters:
    #   $1 - prompt - a bundled theme (arrow, plain, path, powerline), a
    #        literal prompt in the shell's own syntax, or 'native'.
    #
    # Example:
    #   SetPrompt 'powerline' || exit 1
    #   SetPrompt '' || exit 1
    #
    local prompt="${1-}"

    _svhs_require_configuration_phase 'SetPrompt' || return 1

    # an omitted argument would silently mean the empty prompt, so require it;
    # a deliberate SetPrompt '' still says so explicitly
    if [[ $# -lt 1 ]]; then
        printf 'SetPrompt: expected a theme, a literal prompt or native\n' >&2
        return 1
    fi

    if [[ $prompt == 'native' ]]; then
        _SVHS_PROMPT_MODE='native'
    elif _svhs_is_prompt_theme "$prompt"; then
        _SVHS_PROMPT_MODE='theme'
    elif [[ $prompt =~ ^[a-z][a-z0-9-]*$ ]]; then
        # a bare lowercase word is a misspelled theme far more often than a
        # wanted prompt; spelled as a prompt it carries a separator anyway
        printf 'SetPrompt: unknown theme: %s, expected one of: %s, native, or a literal prompt\n' \
            "$prompt" "$_SVHS_PROMPT_THEMES" >&2
        return 1
    else
        _SVHS_PROMPT_MODE='literal'
    fi

    _SVHS_PROMPT="$prompt"
}


SetTypingSpeed() {
    #
    # Set the default delay between typed characters in seconds.
    #
    # Parameters:
    #   $1 - typing_speed - non-negative number of seconds.
    #
    # Example:
    #   SetTypingSpeed 0.1 || exit 1
    #
    local typing_speed="${1-}"

    _svhs_require_configuration_phase 'SetTypingSpeed' || return 1

    if ! _svhs_is_nonnegative_number "$typing_speed"; then
        printf 'SetTypingSpeed: expected a non-negative number, got: %s\n' \
            "$typing_speed" >&2
        return 1
    fi

    _SVHS_TYPING_SPEED="$typing_speed"
}


SetKeyDelay() {
    #
    # Set the default pause after a key press in seconds.
    #
    # Parameters:
    #   $1 - key_delay - non-negative number of seconds.
    #
    # Example:
    #   SetKeyDelay 0.1 || exit 1
    #
    local key_delay="${1-}"

    _svhs_require_configuration_phase 'SetKeyDelay' || return 1

    if ! _svhs_is_nonnegative_number "$key_delay"; then
        printf 'SetKeyDelay: expected a non-negative number, got: %s\n' \
            "$key_delay" >&2
        return 1
    fi

    _SVHS_KEY_DELAY="$key_delay"
}


Env() {
    #
    # Export an environment variable into the recorded shell; repeatable.
    #
    # Parameters:
    #   $1 - name - environment variable name.
    #   $2 - value - value; pass '' for a set-but-empty variable.
    #
    # Example:
    #   Env 'EDITOR' 'vim' || exit 1
    #
    local name="${1-}"
    local value

    _svhs_require_configuration_phase 'Env' || return 1

    # an omitted value would silently export an empty variable, so require it;
    # a deliberate Env NO_COLOR '' still says so explicitly
    if [[ $# -lt 2 ]]; then
        printf 'Env: expected a name and a value, got: %s\n' "$*" >&2
        return 1
    fi
    value="$2"

    # tmux hands the pair to the shell as an environment entry, so any shell
    # picks it up; the name still has to be one bash, zsh and fish all accept
    if [[ ! $name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        printf 'Env: invalid environment variable name: %s\n' "$name" >&2
        return 1
    fi

    _SVHS_ENV+=("$name=$value")
}


## Session


Start() {
    #
    # Start a fresh detached tmux session with the configured geometry, shell
    # and prompt on the dedicated s-vhs server, isolated from personal tmux
    # config and without a status bar, and report how to attach to it.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   Start || exit 1
    #
    local variable
    local env_args=()

    if [[ $_SVHS_STARTED == 1 ]]; then
        printf 'Start: session has already started\n' >&2
        return 1
    fi
    # bash 3.2 (stock macOS) treats an empty array as unset, so ${#...[@]}
    # would abort under set -u before this check can report the real problem
    if [[ -z ${_SVHS_OUTPUTS[*]-} ]]; then
        printf 'Start: configure at least one output with SetOutput\n' >&2
        return 1
    fi

    _svhs_require_dependencies || return 1

    if _svhs_session_exists "$_SVHS_SESSION"; then
        printf 'Start: session already exists: %s, pick another name with SetSession\n' \
            "$_SVHS_SESSION" >&2
        return 1
    fi

    _svhs_prepare_cast || return 1

    _svhs_build_shell

    # the shell's own pairs come first, so an explicit Env PS1 still wins:
    # tmux keeps the last -e given for a name
    for variable in ${_SVHS_SHELL_ENV[@]+"${_SVHS_SHELL_ENV[@]}"} \
                    ${_SVHS_ENV[@]+"${_SVHS_ENV[@]}"}; do
        env_args+=(-e "$variable")
    done

    # bash 3.2 (stock macOS) rejects an empty array under set -u, so expand
    # env_args only when Env was called
    tmux -L "$_SVHS_TMUX_SOCKET" -f /dev/null \
        new-session -d -s "$_SVHS_SESSION"    \
                    -x "$_SVHS_COLS"          \
                    -y "$_SVHS_ROWS"          \
                    ${env_args[@]+"${env_args[@]}"} "${_SVHS_SHELL_COMMAND[@]}"
    _SVHS_STARTED=1

    # Report modified keys (C-Enter, S-Enter, C-S-<key>) instead of folding
    # them into their plain form, so a recording can drive TUIs that bind them
    tmux -L "$_SVHS_TMUX_SOCKET" set -g extended-keys on
    # Encode them as CSI u (^[[65;6u), the form modern TUIs parse, instead of
    # xterm's older modifyOtherKeys sequences
    tmux -L "$_SVHS_TMUX_SOCKET" set -g extended-keys-format csi-u
    tmux -L "$_SVHS_TMUX_SOCKET" set-option -t "$_SVHS_SESSION" status off

    # The session runs on its own socket with the status bar off and a name
    # carrying a PID, so watching a recording live takes the printed command
    printf '::: Started session %s, attach with: tmux -L %s attach -t %s\n' \
        "$_SVHS_SESSION" "$_SVHS_TMUX_SOCKET" "$_SVHS_SESSION"
}


## Input


Run() {
    #
    # Run a command in the session while no recorder is attached.
    #
    # Parameters:
    #   $1 - command_line - command line to type and execute.
    #   $2 - settle - (optional) - seconds to wait afterwards (default: 2).
    #
    # Example:
    #   Run 'cd ~/project' 1
    #
    local command_line="$1"
    local settle="${2:-2}"

    _svhs_send -l "$command_line"
    _svhs_send Enter
    sleep "$settle"
}

RunOffRecord() {
    #
    # Run a command off camera in the middle of a recording: stop the
    # recorder, run it, and resume into the same cast.
    #
    # Parameters:
    #   $1 - command_line - command line to type and execute.
    #   $2 - settle - (optional) - seconds to wait afterwards (default: 2).
    #
    # Example:
    #   RunOffRecord 'export STAGE=ready' 0.5
    #
    local command_line="$1"
    local settle="${2:-2}"

    # Before the first Show, and after a Hide, there is no recorder to stop
    if [[ -z $_SVHS_REC_PID ]]; then
        printf 'RunOffRecord: no recording is active, use Run instead\n' >&2
        return 1
    fi

    Hide || return 1
    Run "$command_line" "$settle"
    Show || return 1
}


Key() {
    #
    # Press one named key, optionally repeating it, pausing after each press.
    #
    # Parameters:
    #   $1 - key_name - tmux key name (e.g., 'Enter', 'Down').
    #   $2 - count - (optional) - number of presses (default: 1).
    #   $3 - delay - (optional) - seconds to sleep after each press
    #        (default: SetKeyDelay).
    #
    # Example:
    #   Key Down 3 0.2
    #
    local key_name="$1"
    local count="${2:-1}"
    local delay="${3:-$_SVHS_KEY_DELAY}"
    local press

    if ! _svhs_is_positive_integer "$count"; then
        printf 'Key: expected a positive integer count, got: %s\n' "$count" >&2
        return 1
    fi

    # tmux send-keys -N repeats natively, but without a delay between presses
    for ((press = 0; press < count; press++)); do
        _svhs_send "$key_name"
        sleep "$delay"
    done
}

#
# A key press is a command of its own: every named key is Key under that name
# and takes the same [count] and [delay] - `Enter 4 0.5`.
#
# A modified key stays with Key and tmux notation (`Key C-r`), and three of
# the names are spelled differently there: BSpace, IC and DC.
#
Enter()     { Key Enter ${@+"$@"}; }
Tab()       { Key Tab ${@+"$@"}; }
Space()     { Key Space ${@+"$@"}; }
Backspace() { Key BSpace ${@+"$@"}; }
Escape()    { Key Escape ${@+"$@"}; }
Up()        { Key Up ${@+"$@"}; }
Down()      { Key Down ${@+"$@"}; }
Left()      { Key Left ${@+"$@"}; }
Right()     { Key Right ${@+"$@"}; }
PageUp()    { Key PageUp ${@+"$@"}; }
PageDown()  { Key PageDown ${@+"$@"}; }
Home()      { Key Home ${@+"$@"}; }
End()       { Key End ${@+"$@"}; }
Insert()    { Key IC ${@+"$@"}; }
Delete()    { Key DC ${@+"$@"}; }
#
# bash 3.2 (stock macOS) reports "$@" as unbound under set -u when the caller
# passed nothing, so the arguments are guarded the same way an array is.
#

Type() {
    #
    # Type text one character at a time, at the configured typing speed.
    #
    # Parameters:
    #   $1 - text - text to type.
    #   $2 - delay - (optional) - seconds between keystrokes (default: SetTypingSpeed).
    #
    # Example:
    #   Type 'ls -la'
    #
    local text="$1"
    local delay="${2:-$_SVHS_TYPING_SPEED}"
    local idx

    for ((idx = 0; idx < ${#text}; idx++)); do
        _svhs_send -l "${text:idx:1}"
        sleep "$delay"
    done
}


Sleep() {
    #
    # Pause the recording, so the last frame stays on screen.
    #
    # Parameters:
    #   $1 - duration - seconds to pause; fractions allowed.
    #
    # Example:
    #   Sleep 1.5
    #
    local duration="${1-}"

    if ! _svhs_is_nonnegative_number "$duration"; then
        printf 'Sleep: expected a non-negative number, got: %s\n' "$duration" >&2
        return 1
    fi

    sleep "$duration"
}


Wait() {
    #
    # Poll the visible pane until a pattern appears, instead of guessing
    # sleeps. Return 1 on timeout.
    #
    # Parameters:
    #   $1 - pattern - grep pattern to wait for.
    #   $2 - timeout - (optional) - seconds before giving up (default: 15).
    #
    # Example:
    #   Wait 'build succeeded' 30
    #
    local pattern="$1"
    local timeout="${2:-15}"
    local deadline=$((SECONDS + timeout))

    until tmux -L "$_SVHS_TMUX_SOCKET" capture-pane \
        -p -t "$_SVHS_SESSION" | grep -q "$pattern"; do
        if ((SECONDS >= deadline)); then
            printf 'timeout waiting for: %s\n' "$pattern" >&2
            return 1
        fi
        sleep "$_SVHS_POLL_INTERVAL"
    done
}


## Recording


Show() {
    #
    # Start (or resume) recording the session; the first call records fresh,
    # later calls append to the same cast.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   Show || exit 1
    #
    local attach_command
    # asciinema rejects --overwrite next to --append, so the flags are
    # exclusive: the first segment replaces a stale cast, later ones extend it
    local write_mode='--overwrite'

    [[ -n $_SVHS_RECORDED ]] && write_mode='--append'
    printf -v attach_command 'tmux -L %q attach -t %q' \
        "$_SVHS_TMUX_SOCKET" "$_SVHS_SESSION"

    # asciinema holds the foreground for the whole segment while the script
    # keeps driving the session, so it runs in the background and its PID is
    # kept for Hide and Render to stop it
    asciinema rec --headless "$write_mode"                    \
                  --window-size "${_SVHS_COLS}x${_SVHS_ROWS}" \
                  -c "$attach_command" "$_SVHS_CAST" &
    _SVHS_REC_PID=$!
    _SVHS_RECORDED=1

    _svhs_wait_for_client || return 1
}


Hide() {
    #
    # Stop recording without disturbing the session.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   Hide || exit 1
    #
    local client
    local clean_lines
    local lines_before
    local deadline

    # A segment ends at its last event, so a pause held before Hide would be
    # dropped and its closing frame would flash by. Repainting the recorder's
    # client writes an event with the same pixels at the current time, which
    # gives that frame its duration back. refresh-client targets a client,
    # never a session
    client=$(tmux -L "$_SVHS_TMUX_SOCKET" list-clients \
        -t "$_SVHS_SESSION" -F '#{client_name}' | head -1)
    lines_before=$(wc -l < "$_SVHS_CAST")
    tmux -L "$_SVHS_TMUX_SOCKET" refresh-client -t "$client"

    # measuring the cast before the repaint reaches it would truncate the
    # repaint away again, so wait for the file to grow instead of guessing;
    # a line appears only once the event behind it is written whole
    deadline=$((SECONDS + _SVHS_WRITE_TIMEOUT))
    until [[ $(wc -l < "$_SVHS_CAST") -gt $lines_before ]]; do
        if ((SECONDS >= deadline)); then
            printf 'Hide: timeout waiting for the recorder to write\n' >&2
            return 1
        fi
        sleep "$_SVHS_WRITE_POLL_INTERVAL"
    done

    # Detaching appends terminal-reset noise to the cast; remember the clean
    # length first and truncate back to it
    clean_lines=$(wc -l < "$_SVHS_CAST")

    tmux -L "$_SVHS_TMUX_SOCKET" detach-client -s "$_SVHS_SESSION"
    wait "$_SVHS_REC_PID"

    _svhs_truncate "$_SVHS_CAST" "$clean_lines"
    _SVHS_REC_PID=''
}


## Render


Render() {
    #
    # End the recording, retain requested casts, and render requested GIFs.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   Render || exit 1
    #
    local clean_lines=''
    local output
    local font_args=()

    # As in Hide, drop the detach noise appended by the kill
    [[ -n $_SVHS_REC_PID ]] && clean_lines=$(wc -l < "$_SVHS_CAST")

    tmux -L "$_SVHS_TMUX_SOCKET" kill-session -t "$_SVHS_SESSION"

    if [[ -n $_SVHS_REC_PID ]]; then
        wait "$_SVHS_REC_PID"
        _svhs_truncate "$_SVHS_CAST" "$clean_lines"
    fi
    _SVHS_REC_PID=''

    [[ -n $_SVHS_FONT_FAMILY ]] && font_args+=(--text-font-family "$_SVHS_FONT_FAMILY")
    [[ -n $_SVHS_FONT_FAMILY_EXACT ]] && font_args+=(--font-family "$_SVHS_FONT_FAMILY_EXACT")

    for output in "${_SVHS_OUTPUTS[@]}"; do
        case "$output" in
            *.cast)
                if [[ $output != "$_SVHS_CAST" ]]; then
                    cp -- "$_SVHS_CAST" "$output"
                fi
                ;;
            *.gif)
                # bash 3.2 (stock macOS) rejects an empty array under set -u,
                # so expand font_args only when a font family was configured
                agg ${font_args[@]+"${font_args[@]}"}  \
                    --font-size "$_SVHS_FONT_SIZE"     \
                    --line-height "$_SVHS_LINE_HEIGHT" \
                    --theme "$_SVHS_THEME"             \
                    "$_SVHS_CAST" "$output"
                ;;
        esac

        printf '::: Wrote %s\n' "$output"
    done

    if [[ -n $_SVHS_TEMP_CAST ]]; then
        rm -f -- "$_SVHS_TEMP_CAST"
        _SVHS_TEMP_CAST=''
    fi
    _SVHS_CAST=''
}


## Internal
#
# Bash cannot hide functions from a sourcing script, so the _svhs_ prefix
# only marks them as implementation details and avoids name collisions with
# the recording script.


_svhs_require_configuration_phase() {
    #
    # Reject a setting change after the tmux session has started.
    #
    # Parameters:
    #   $1 - setter - public setter name used in the error message.
    #
    # Example:
    #   _svhs_require_configuration_phase 'SetRows' || exit 1
    #
    local setter="$1"

    if [[ $_SVHS_STARTED == 1 ]]; then
        printf '%s: settings cannot change after the session starts\n' "$setter" >&2
        return 1
    fi
}


_svhs_require_command() {
    #
    # Report an external dependency that is missing from PATH.
    #
    # Parameters:
    #   $1 - command_name - executable the recording needs.
    #   $2 - purpose - what it is needed for.
    #
    # Example:
    #   _svhs_require_command 'agg' 'GIF output' || return 1
    #
    local command_name="$1"
    local purpose="$2"

    if ! command -v "$command_name" > /dev/null 2>&1; then
        printf 'Start: %s is not installed, required for %s\n' \
            "$command_name" "$purpose" >&2
        return 1
    fi
}


_svhs_require_dependencies() {
    #
    # Check the tools the session and the requested outputs need, so a long
    # recording fails before it runs instead of at render time.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _svhs_require_dependencies || return 1
    #
    local output

    _svhs_require_command 'tmux' 'the recording session' || return 1
    _svhs_require_command 'asciinema' 'the recorder' || return 1

    for output in "${_SVHS_OUTPUTS[@]}"; do
        case "$output" in
            *.gif) _svhs_require_command 'agg' 'GIF output' || return 1 ;;
        esac
    done
}


_svhs_session_exists() {
    #
    # Return success when a session of exactly that name is alive on the
    # s-vhs server. tmux resolves a -t target by prefix and pattern too, so
    # has-session would report `demo` as taken by an unrelated `demo2`.
    #
    # Parameters:
    #   $1 - session - session name to look for.
    #
    # Example:
    #   _svhs_session_exists 'demo' && return 1
    #
    local session="$1"

    # a missing server means no sessions at all, hence the discarded error
    tmux -L "$_SVHS_TMUX_SOCKET" list-sessions -F '#{session_name}' 2> /dev/null \
        | grep -q -x -F -- "$session" || return 1
    return 0
}


_svhs_is_positive_integer() {
    #
    # Return success when a value is an integer greater than zero.
    #
    # Parameters:
    #   $1 - value - value to test.
    #
    # Example:
    #   _svhs_is_positive_integer '80' || exit 1
    #
    local value="$1"

    [[ $value =~ ^[1-9][0-9]*$ ]] || return 1
    return 0
}


_svhs_is_nonnegative_number() {
    #
    # Return success when a value is a decimal number greater than or equal to zero.
    #
    # Parameters:
    #   $1 - value - value to test.
    #
    # Example:
    #   _svhs_is_nonnegative_number '0.1' || exit 1
    #
    local value="$1"

    [[ $value =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]] || return 1
    return 0
}


_svhs_is_positive_number() {
    #
    # Return success when a value is a decimal number greater than zero.
    #
    # Parameters:
    #   $1 - value - value to test.
    #
    # Example:
    #   _svhs_is_positive_number '1.2' || exit 1
    #
    local value="$1"

    _svhs_is_nonnegative_number "$value" && [[ $value =~ [1-9] ]] || return 1
    return 0
}


_svhs_is_prompt_theme() {
    #
    # Return success when a value names a bundled prompt theme.
    #
    # Parameters:
    #   $1 - value - value to test.
    #
    # Example:
    #   _svhs_is_prompt_theme 'arrow' || exit 1
    #
    local value="$1"

    [[ " $_SVHS_PROMPT_THEMES " == *" $value "* ]] || return 1
    return 0
}


_svhs_theme_prompt() {
    #
    # Print the configured theme in the configured shell's own prompt syntax:
    # a PS1 or PROMPT value for bash and zsh, the body of a fish_prompt
    # function for fish. Colours are ANSI names rather than fixed hex, so a
    # theme follows the palette SetTheme renders with.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   prompt=$(_svhs_theme_prompt)
    #
    local arrow="$_SVHS_PROMPT_ARROW"
    local separator="$_SVHS_POWERLINE_SEPARATOR"
    # fish has no prompt string, so its themes are code. Every string in them
    # is double-quoted, which fish reads the same and this file can hold in
    # plain single quotes; HOME and PWD are fish's own variables, so they have
    # to reach it unexpanded
    # shellcheck disable=SC2016
    local fish_path='(string replace -- "$HOME" "~" $PWD)'
    local fish_arrow='set_color green; echo -n '"$arrow"'; set_color normal; echo -n " "'
    local fish_directory="set_color blue; echo -n $fish_path"
    local fish_segment='set_color -b blue brwhite; echo -n " "'"$fish_path"'" "'

    fish_directory+='; set_color normal; echo -n " "'
    fish_segment+='; set_color -b normal blue; echo -n '"$separator"
    fish_segment+='; set_color normal; echo -n " "'

    case "$_SVHS_SHELL" in
        bash)
            case "$_SVHS_PROMPT" in
                arrow)     printf '%s' "\[\e[32m\]$arrow\[\e[0m\] " ;;
                plain)     printf '%s' '$ ' ;;
                path)      printf '%s' "\[\e[34m\]\w\[\e[0m\] \[\e[32m\]$arrow\[\e[0m\] " ;;
                powerline) printf '%s' "\[\e[44;97m\] \w \[\e[0m\]\[\e[34m\]$separator\[\e[0m\] " ;;
            esac
            ;;
        zsh)
            case "$_SVHS_PROMPT" in
                arrow)     printf '%s' "%F{green}$arrow%f " ;;
                plain)     printf '%s' '$ ' ;;
                path)      printf '%s' "%F{blue}%~%f %F{green}$arrow%f " ;;
                powerline) printf '%s' "%K{blue}%F{15} %~ %f%k%F{blue}$separator%f " ;;
            esac
            ;;
        fish)
            case "$_SVHS_PROMPT" in
                arrow)     printf '%s' "$fish_arrow" ;;
                plain)     printf '%s' 'echo -n "\$ "' ;;
                path)      printf '%s' "$fish_directory; $fish_arrow" ;;
                powerline) printf '%s' "$fish_segment" ;;
            esac
            ;;
    esac
}


_svhs_fish_quote() {
    #
    # Print a value as a fish single-quoted string. Inside those, fish reads
    # only \' and \\ as escapes, so escaping the two keeps a literal prompt
    # from closing the string or starting an escape of its own.
    #
    # Parameters:
    #   $1 - value - value to quote.
    #
    # Example:
    #   quoted=$(_svhs_fish_quote "$prompt")
    #
    local value="$1"
    local escaped="${value//\\/\\\\}"

    printf "'%s'" "${escaped//\'/\\\'}"
}


_svhs_prompt_body() {
    #
    # Print the configured prompt in the shell's own syntax: a theme rendered
    # for it, or a literal prompt as the recording script gave it.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   prompt=$(_svhs_prompt_body)
    #
    if [[ $_SVHS_PROMPT_MODE == 'theme' ]]; then
        _svhs_theme_prompt
        return 0
    fi

    # bash and zsh read a literal as their own prompt syntax; fish has no
    # prompt string at all, so its function prints the literal verbatim
    case "$_SVHS_SHELL" in
        fish) printf "printf '%%s' %s" "$(_svhs_fish_quote "$_SVHS_PROMPT")" ;;
        *)    printf '%s' "$_SVHS_PROMPT" ;;
    esac
}


_svhs_build_shell() {
    #
    # Assemble the recorded shell's command line in _SVHS_SHELL_COMMAND and
    # the environment it needs in _SVHS_SHELL_ENV. The shell always keeps its
    # history to itself, so a recording never lands in the user's history and
    # no autosuggestion puts an earlier command of theirs on screen, while
    # recall within the recording still works. Unless the prompt is native,
    # the shell also skips the user's rc files and takes the configured
    # prompt - fish on its command line, the others through the environment.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _svhs_build_shell
    #
    local isolated=1

    [[ $_SVHS_PROMPT_MODE == 'native' ]] && isolated=0

    case "$_SVHS_SHELL" in
        bash)
            # bash and zsh both read and write the user's history through
            # HISTFILE, and leave it alone when it names no file
            _SVHS_SHELL_COMMAND=(bash)
            _SVHS_SHELL_ENV=('HISTFILE=')
            if [[ $isolated == 1 ]]; then
                _SVHS_SHELL_COMMAND+=(--norc --noprofile)
                _SVHS_SHELL_ENV+=("PS1=$(_svhs_prompt_body)")
            fi
            ;;
        zsh)
            _SVHS_SHELL_COMMAND=(zsh)
            _SVHS_SHELL_ENV=('HISTFILE=')
            if [[ $isolated == 1 ]]; then
                _SVHS_SHELL_COMMAND+=(--no-rcs)
                _SVHS_SHELL_ENV+=("PROMPT=$(_svhs_prompt_body)")
            fi
            ;;
        fish)
            # fish has no prompt string and no HISTFILE: its prompt is a
            # function, and --private gives the session a history of its own
            _SVHS_SHELL_COMMAND=(fish --private)
            _SVHS_SHELL_ENV=()
            if [[ $isolated == 1 ]]; then
                _SVHS_SHELL_COMMAND+=(--no-config                     \
                    -C 'function fish_greeting; end'                  \
                    -C "function fish_prompt; $(_svhs_prompt_body); end")
            fi
            ;;
    esac
}


_svhs_prepare_cast() {
    #
    # Select a requested cast path or create a temporary renderer input.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _svhs_prepare_cast || exit 1
    #
    local output
    local temporary_cast

    _SVHS_CAST=''
    for output in "${_SVHS_OUTPUTS[@]}"; do
        if [[ $output == *.cast ]]; then
            _SVHS_CAST="$output"
            break
        fi
    done

    if [[ -z $_SVHS_CAST ]]; then
        if ! temporary_cast=$(mktemp); then
            printf 'Start: failed to create a temporary cast\n' >&2
            return 1
        fi
        _SVHS_CAST="$temporary_cast"
        _SVHS_TEMP_CAST="$temporary_cast"
    fi
}


_svhs_truncate() {
    #
    # Shrink a file to its leading lines. One asciicast event is one line, so
    # counting lines keeps every event whole: an event still being written
    # carries no newline yet, is never counted, and is dropped rather than cut
    # in half the way a byte count could.
    #
    # Parameters:
    #   $1 - path - file to shrink.
    #   $2 - lines - number of leading lines to keep.
    #
    # Example:
    #   _svhs_truncate 'demo.cast' 120 || return 1
    #
    local path="$1"
    # BSD wc pads its count with spaces, which head rejects as an argument
    local lines="${2// /}"
    # written next to the cast, so the replacing move stays within one
    # filesystem and cannot fail halfway across devices
    local shortened="$path.tmp"

    head -n "$lines" < "$path" > "$shortened" && mv -- "$shortened" "$path"
}


_svhs_wait_for_client() {
    #
    # Wait until the recorder's tmux client is attached, so the segment is
    # captured from its first frame instead of starting with idle time.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _svhs_wait_for_client || return 1
    #
    local deadline=$((SECONDS + _SVHS_ATTACH_TIMEOUT))

    until [[ -n $(tmux -L "$_SVHS_TMUX_SOCKET" list-clients \
        -t "$_SVHS_SESSION" 2> /dev/null) ]]; do
        if ! kill -0 "$_SVHS_REC_PID" 2> /dev/null; then
            printf 'Show: the recorder exited before attaching\n' >&2
            return 1
        fi
        if ((SECONDS >= deadline)); then
            printf 'Show: timeout waiting for the recorder to attach\n' >&2
            return 1
        fi
        sleep "$_SVHS_POLL_INTERVAL"
    done
}


_svhs_send() {
    #
    # Send keys to the demo session (thin wrapper over tmux send-keys).
    #
    # Parameters:
    #   $@ - arguments passed through to tmux send-keys.
    #
    # Example:
    #   _svhs_send -l 'ls'
    #   _svhs_send Enter
    #
    local argument
    local escaped_arguments=()

    for argument in "$@"; do
        # tmux treats an argument ending in ; as a command separator
        if [[ $argument == *';' ]]; then
            argument="${argument%;}"'\;'
        fi
        escaped_arguments+=("$argument")
    done

    tmux -L "$_SVHS_TMUX_SOCKET" send-keys -t "$_SVHS_SESSION" \
        ${escaped_arguments[@]+"${escaped_arguments[@]}"}
}


_svhs_cleanup() {
    #
    # Kill the recording session and recorder on exit; safe to call when
    # neither is alive, and remove an unrequested temporary cast.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _svhs_cleanup
    #
    # An exit before Start - a failed setter, a name collision, or merely
    # sourcing the library - must leave a session of that name alone: s-vhs
    # did not create it, so it is the user's own
    if [[ $_SVHS_STARTED == 1 ]]; then
        tmux -L "$_SVHS_TMUX_SOCKET" kill-session \
            -t "$_SVHS_SESSION" 2> /dev/null || true
    fi
    if [[ -n $_SVHS_REC_PID ]] && kill -0 "$_SVHS_REC_PID" 2> /dev/null; then
        kill "$_SVHS_REC_PID" 2> /dev/null || true
    fi
    if [[ -n $_SVHS_TEMP_CAST ]]; then
        rm -f -- "$_SVHS_TEMP_CAST"
    fi
}


## CLI


_svhs_new() {
    #
    # Write an executable recording script template to a path, or print it.
    #
    # Parameters:
    #   $1 - path - (optional) - executable file to create; an existing file
    #        is never overwritten. Without it the script goes to stdout.
    #
    # Example:
    #   _svhs_new 'demo.rec.sh' || exit 1
    #   _svhs_new > 'demo.rec.sh'
    #
    local path="${1-}"

    if [[ -n $path && -e $path ]]; then
        printf 's-vhs.sh new: refusing to overwrite: %s\n' "$path" >&2
        return 1
    fi

    if [[ -z $path ]]; then
        printf '%s\n' "$_SVHS_TEMPLATE"
        return 0
    fi

    printf '%s\n' "$_SVHS_TEMPLATE" > "$path"
    chmod +x "$path"
    # stdout is the template itself in the pathless mode, so status goes to stderr
    printf 'Wrote %s\n' "$path" >&2
}


# Executed rather than sourced, so this is the scaffolding call: either as a
# file (`s-vhs.sh new demo.rec.sh`) or piped, which leaves BASH_SOURCE unset
# (`curl -fsSL … | bash -s -- new demo.rec.sh`). A sourced library, in
# contrast, is $0 of its caller. The subcommand is deliberately the only one:
# s-vhs is a library, not a CLI.
#
# Dispatch cannot look at $1 alone — a sourced script inherits the positional
# parameters of the recording script that sourced it.
if [[ -z ${BASH_SOURCE[0]-} || ${BASH_SOURCE[0]} == "$0" ]]; then
    if [[ ${1-} != 'new' ]]; then
        printf 'usage: s-vhs.sh new [path]\n' >&2
        exit 1
    fi

    _svhs_new "${2-}" || exit 1
    exit 0
fi

# Installed in the sourcing script's shell, so any exit — including a
# set -e failure mid-recording — tears down the tmux session and recorder
# instead of leaving them running in the background. The handler is a no-op
# until Start, so an exit before it, scaffolding included, tears down nothing.
trap _svhs_cleanup EXIT
