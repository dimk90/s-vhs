#!/bin/bash
#
# Shared helpers for agg + asciinema + tmux demo recordings.
# Meant to be sourced by a recording script, not executed.
#

# Stop on an unhandled command failure (-e), use of an unset variable (-u),
# or failure within a pipeline (-o pipefail), so the EXIT trap can clean up.
set -euo pipefail


## Settings


_SVHS_SESSION='demo'
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
_SVHS_THEME='kanagawa'

# Shell to run inside the tmux session;
# Bash is safe default - present everywhere
_SVHS_SHELL='bash'

# Delays are in seconds
_SVHS_TYPING_SPEED=0.07
_SVHS_KEY_DELAY=0.0

# Session and recorder lifecycle state
_SVHS_STARTED=0
_SVHS_CAST=''
_SVHS_TEMP_CAST=''
_SVHS_REC_PID=''
_SVHS_RECORDED=''


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

    _require_configuration_phase 'SetOutput' || return 1

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

    _require_configuration_phase 'SetSession' || return 1

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

    _require_configuration_phase 'SetCols' || return 1

    if ! _is_positive_integer "$cols"; then
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

    _require_configuration_phase 'SetRows' || return 1

    if ! _is_positive_integer "$rows"; then
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

    _require_configuration_phase 'SetFontFamily' || return 1

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

    _require_configuration_phase 'SetFontFamilyExact' || return 1

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

    _require_configuration_phase 'SetFontSize' || return 1

    if ! _is_positive_integer "$font_size"; then
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

    _require_configuration_phase 'SetLineHeight' || return 1

    if ! _is_positive_number "$line_height"; then
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

    _require_configuration_phase 'SetTheme' || return 1

    if [[ -z $theme ]]; then
        printf 'SetTheme: theme must not be empty\n' >&2
        return 1
    fi

    _SVHS_THEME="$theme"
}


SetShell() {
    #
    # Set the shell command run inside the tmux session.
    #
    # Parameters:
    #   $1 - shell - non-empty shell command.
    #
    # Example:
    #   SetShell 'fish' || exit 1
    #
    local shell="${1-}"

    _require_configuration_phase 'SetShell' || return 1

    if [[ -z $shell ]]; then
        printf 'SetShell: shell command must not be empty\n' >&2
        return 1
    fi

    _SVHS_SHELL="$shell"
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

    _require_configuration_phase 'SetTypingSpeed' || return 1

    if ! _is_nonnegative_number "$typing_speed"; then
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

    _require_configuration_phase 'SetKeyDelay' || return 1

    if ! _is_nonnegative_number "$key_delay"; then
        printf 'SetKeyDelay: expected a non-negative number, got: %s\n' \
            "$key_delay" >&2
        return 1
    fi

    _SVHS_KEY_DELAY="$key_delay"
}


## Session


Start() {
    #
    # Start a fresh detached tmux session with the configured geometry and
    # shell, isolated from personal tmux config and without a status bar.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   Start || exit 1
    #
    if [[ $_SVHS_STARTED == 1 ]]; then
        printf 'Start: session has already started\n' >&2
        return 1
    fi
    if ((${#_SVHS_OUTPUTS[@]} == 0)); then
        printf 'Start: configure at least one output with SetOutput\n' >&2
        return 1
    fi

    _prepare_cast || return 1

    tmux -f /dev/null new-session -d -s "$_SVHS_SESSION" \
        -x "$_SVHS_COLS" -y "$_SVHS_ROWS" "$_SVHS_SHELL"
    _SVHS_STARTED=1

    tmux set -g extended-keys on # TODO: add comment with descriptions
    tmux set -g extended-keys-format csi-u # TODO: add comment with descriptions
    tmux set-option -t "$_SVHS_SESSION" status off
}


## Input


RunOffRecord() {
    #
    # Run a command in the session while no recorder is attached.
    #
    # Parameters:
    #   $1 - command_line - command line to type and execute.
    #   $2 - settle - (optional) - seconds to wait afterwards (default: 2).
    #
    # Example: # TODO: more intuitive example
    #   RunOffRecord 'pi --no-extensions' 5
    #
    local command_line="$1"
    local settle="${2:-2}"

    _send -l "$command_line"
    _send Enter
    sleep "$settle"
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

    if ! _is_positive_integer "$count"; then
        printf 'Key: expected a positive integer count, got: %s\n' "$count" >&2
        return 1
    fi

    # tmux send-keys -N repeats natively, but without a delay between presses
    for ((press = 0; press < count; press++)); do
        _send "$key_name"
        sleep "$delay"
    done
}


Type() {
    #
    # Type text one character at a time, like VHS's TypingSpeed.
    #
    # Parameters:
    #   $1 - text - text to type.
    #   $2 - delay - (optional) - seconds between keystrokes (default: SetTypingSpeed).
    #
    # Example: # TODO: more intuitive example
    #   Type '/context'
    #
    local text="$1"
    local delay="${2:-$_SVHS_TYPING_SPEED}"
    local idx

    for ((idx = 0; idx < ${#text}; idx++)); do
        _send -l "${text:idx:1}"
        sleep "$delay"
    done
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
    # Example: # TODO: more intuitive example
    #   Wait 'Context Usage' 30
    #
    local pattern="$1"
    local timeout="${2:-15}"
    local deadline=$((SECONDS + timeout))

    until tmux capture-pane -p -t "$_SVHS_SESSION" | grep -q "$pattern"; do
        if ((SECONDS >= deadline)); then
            printf 'timeout waiting for: %s\n' "$pattern" >&2
            return 1
        fi
        sleep 0.2 # TODO: add cont for that
    done
}


## Recording


Show() {
    #
    # Start (or resume) recording the session; the first call records fresh,
    # later calls append to the same cast (VHS Show).
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   Show || exit 1
    #
    local attach_command
    printf -v attach_command 'tmux attach -t %q' "$_SVHS_SESSION"

    # Expands to nothing on the first call; must stay unquoted so an empty
    # value adds no argument
    asciinema rec --headless --overwrite ${_SVHS_RECORDED:+--append} \
                  --window-size "${_SVHS_COLS}x${_SVHS_ROWS}"      \
                  -c "$attach_command" "$_SVHS_CAST" & # TODO: remove &?
    _SVHS_REC_PID=$!
    _SVHS_RECORDED=1
    # TODO: any better way to wait for it?
    sleep 1 # let the recorder attach
}


Hide() {
    #
    # Stop recording without disturbing the session (VHS Hide).
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   Hide || exit 1
    #
    local clean_end

    # Detaching appends terminal-reset noise to the cast; remember the clean
    # size first and truncate back to it
    clean_end=$(wc -c < "$_SVHS_CAST")

    tmux detach-client -s "$_SVHS_SESSION"
    wait "$_SVHS_REC_PID"

    truncate -s "$clean_end" -- "$_SVHS_CAST"
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
    local clean_end=''
    local output
    local font_args=()

    # As in Hide, drop the detach noise appended by the kill
    [[ -n $_SVHS_REC_PID ]] && clean_end=$(wc -c < "$_SVHS_CAST")

    tmux kill-session -t "$_SVHS_SESSION"

    if [[ -n $_SVHS_REC_PID ]]; then
        wait "$_SVHS_REC_PID"
        truncate -s "$clean_end" -- "$_SVHS_CAST"
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
                agg "${font_args[@]}"                    \
                    --font-size "$_SVHS_FONT_SIZE"       \
                    --line-height "$_SVHS_LINE_HEIGHT"   \
                    --theme "$_SVHS_THEME"               \
                    "$_SVHS_CAST" "$output"
                ;;
        esac

        printf 'Wrote %s\n' "$output"
    done

    if [[ -n $_SVHS_TEMP_CAST ]]; then
        rm -f -- "$_SVHS_TEMP_CAST"
        _SVHS_TEMP_CAST=''
    fi
    _SVHS_CAST=''
}


## Internal


_require_configuration_phase() {
    #
    # Reject a setting change after the tmux session has started.
    #
    # Parameters:
    #   $1 - setter - public setter name used in the error message.
    #
    # Example:
    #   _require_configuration_phase 'SetRows' || exit 1
    #
    local setter="$1"

    if [[ $_SVHS_STARTED == 1 ]]; then
        printf '%s: settings cannot change after the session starts\n' "$setter" >&2
        return 1
    fi
}


_is_positive_integer() {
    #
    # Return success when a value is an integer greater than zero.
    #
    # Parameters:
    #   $1 - value - value to test.
    #
    # Example:
    #   _is_positive_integer '80' || exit 1
    #
    local value="$1"

    [[ $value =~ ^[1-9][0-9]*$ ]] || return 1
    return 0
}


_is_nonnegative_number() {
    #
    # Return success when a value is a decimal number greater than or equal to zero.
    #
    # Parameters:
    #   $1 - value - value to test.
    #
    # Example:
    #   _is_nonnegative_number '0.1' || exit 1
    #
    local value="$1"

    [[ $value =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]] || return 1
    return 0
}


_is_positive_number() {
    #
    # Return success when a value is a decimal number greater than zero.
    #
    # Parameters:
    #   $1 - value - value to test.
    #
    # Example:
    #   _is_positive_number '1.2' || exit 1
    #
    local value="$1"

    _is_nonnegative_number "$value" && [[ $value =~ [1-9] ]] || return 1
    return 0
}


_prepare_cast() {
    #
    # Select a requested cast path or create a temporary renderer input.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _prepare_cast || exit 1
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


_send() {
    #
    # Send keys to the demo session (thin wrapper over tmux send-keys).
    #
    # Parameters:
    #   $@ - arguments passed through to tmux send-keys.
    #
    # Example:
    #   _send -l 'ls'
    #   _send Enter
    #
    tmux send-keys -t "$_SVHS_SESSION" "$@"
}


_cleanup() {
    #
    # Kill the demo session and recorder on exit; safe to call when neither
    # is alive, and remove an unrequested temporary cast.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _cleanup
    #
    tmux kill-session -t "$_SVHS_SESSION" 2> /dev/null || true
    if [[ -n $_SVHS_REC_PID ]] && kill -0 "$_SVHS_REC_PID" 2> /dev/null; then
        kill "$_SVHS_REC_PID" 2> /dev/null || true
    fi
    if [[ -n $_SVHS_TEMP_CAST ]]; then
        rm -f -- "$_SVHS_TEMP_CAST"
    fi
}


# Installed in the sourcing script's shell, so any exit — including a
# set -e failure mid-recording — tears down the tmux session and recorder
# instead of leaving them running in the background.
trap _cleanup EXIT
