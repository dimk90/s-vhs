#!/bin/bash
#
# S-VHS - a scriptable terminal recorder.
# A thin wrapper around tmux + asciinema + output renderers:
# agg for GIF, agg + ffmpeg for WebP, asg for SVG.
#
# Source this file from a recording script (*.rec.sh), or execute it:
#   s-vhs.sh new demo.rec.sh   scaffold a recording script
#   s-vhs.sh watch <name>      view a live recording session
#
# Homepage:  https://github.com/dimk90/s-vhs
# License:   MIT
# Copyright: (c) 2026 Dmitry Makarov
#

# Abort on the first unhandled error, so the EXIT trap can clean up:
#   -e           exit when a command fails and nothing checks its status
#   -u           treat expansion of an unset variable as an error
#   -o pipefail  a pipeline fails when any command in it fails
set -euo pipefail


## Version


svhs_version() {
    printf '%s\n' '0.6.0'
}


## Settings / Defaults / Consts


# Named tmux socket; keeps recordings off the user's default server
_SVHS_TMUX_SOCKET='s-vhs'

# The PID keeps parallel recordings apart; SetSession pins a fixed name
_SVHS_SESSION="s-vhs-$$"

# Output paths added by SetOutput
_SVHS_OUTPUTS=()

# Recorder metadata and diagnostic output
_SVHS_TITLE=''
_SVHS_QUIET=0

# Warning color paired with its reset so styling cannot leak into later output
_SVHS_WARNING_COLOR=$'\033[33m'
_SVHS_COLOR_RESET=$'\033[0m'

# Rewinds to the start of a progress line and wipes what the last update left,
# so a shorter message cannot inherit the tail of a longer one
_SVHS_ERASE_LINE=$'\r\033[K'

# Terminal size in cells, not pixels
_SVHS_COLS=100
_SVHS_ROWS=40

# Renderer fonts, empty = their defaults. FAMILY comes before the renderer's
# own text chain and keeps the Nerd Font and emoji fallbacks; FAMILY_EXACT
# replaces the whole chain, no fallbacks; EMOJI_FONT_FAMILY replaces the emoji
# fallbacks alone
_SVHS_FONT_FAMILY=''
_SVHS_FONT_FAMILY_EXACT=''
_SVHS_EMOJI_FONT_FAMILY=''

# Extra font directories added by SetFontDir, searched by the raster renderer
_SVHS_FONT_DIRS=()

# agg's default text-font chain, appended after SetFontFamily so a missing
# preferred face falls back normally. It mirrors agg's own default, so
# re-check `agg --help` when bumping agg
_SVHS_AGG_TEXT_FONT_DEFAULTS='JetBrains Mono,Fira Code,SF Mono,Menlo,'
_SVHS_AGG_TEXT_FONT_DEFAULTS+='Consolas,DejaVu Sans Mono,Liberation Mono'

# agg bundles these fallbacks; an SVG can only name fonts on the viewer's
# system, and it picks a face per glyph. Text faces must therefore come before
# the symbol ones: 'Segoe UI Symbol' (Windows) and 'Apple Symbols' (macOS, iOS)
# cover Latin in a proportional face, so a viewer without the recording's font
# would draw the text off asg's fixed 0.6 x font-size cell, leaving the cursor
# and the cell backgrounds behind. Ordered by advance: 0.600 em first, 0.602 em
# next, Consolas (0.55 em) as the last monospace resort. The symbol tail mirrors
# asg's default --font-family, so re-check `asg --help` when bumping asg
_SVHS_SVG_FONT_FALLBACKS="'JetBrains Mono','Cascadia Mono','Noto Sans Mono',"
_SVHS_SVG_FONT_FALLBACKS+="'Liberation Mono','Roboto Mono','Menlo',"
_SVHS_SVG_FONT_FALLBACKS+="'DejaVu Sans Mono','SF Mono','Consolas',"
_SVHS_SVG_FONT_FALLBACKS+="'Symbols Nerd Font Mono','Symbols Nerd Font',"
_SVHS_SVG_FONT_FALLBACKS+="'Powerline Symbols','Apple Symbols','Segoe UI Symbol',"
_SVHS_SVG_FONT_FALLBACKS+="'Noto Sans Symbols 2','Noto Sans Symbols'"

# Emoji tail of that chain, replaced by SetEmojiFontFamily
_SVHS_SVG_EMOJI_FALLBACKS="'Apple Color Emoji','Segoe UI Emoji','Noto Color Emoji'"

# Output resolution ~ COLS x ROWS x FONT_SIZE
_SVHS_FONT_SIZE=28
_SVHS_LINE_HEIGHT=1.2

# Nominal monospace advance in em, the cell width asg is fixed at. agg takes
# its own from the primary font, so a raster width is measured by probing agg
# and only falls back to this. asg's window bar costs these fixed pixels on top of
# the grid and the padding
_SVHS_CELL_ADVANCE=0.6
_SVHS_WINDOW_BAR_WIDTH=40
_SVHS_WINDOW_BAR_HEIGHT=60

# Render theme; headless recording has no host theme to inherit
_SVHS_THEME='dracula'

# Bold text in the bright ANSI color, the way most terminals show it
_SVHS_BOLD_IS_BRIGHT='off'

# agg's frame rasterizer; only resvg draws COLRv1 emoji in color
_SVHS_ENGINE='swash'
_SVHS_ENGINE_SET=0

# Lossless gifsicle pass over the rendered GIF; it costs render time, so opt-in
_SVHS_OPTIMIZE='off'

# SVG frame around the terminal: padding in output pixels, its per-axis
# overrides - empty until set, so both follow _SVHS_PADDING - macOS-style
# window decorations, and the terminal cursor
_SVHS_PADDING=0
_SVHS_PADDING_X=''
_SVHS_PADDING_Y=''
_SVHS_WINDOW_BAR='off'
_SVHS_CURSOR='on'

# Timing applied by the renderers rather than baked into the cast
_SVHS_PLAYBACK_SPEED=1
_SVHS_FRAMERATE=30
_SVHS_IDLE_TIME_LIMIT=5
_SVHS_LOOP='on'
_SVHS_LAST_FRAME_DURATION=3
_SVHS_LAST_FRAME_DURATION_SET=0

# Recorded shell; must be one s-vhs knows how to isolate and inject
# a prompt into, and bash is present everywhere
_SVHS_SHELL='bash'

# Prompt: a bundled theme, a literal string, or 'native' (see SetPrompt)
_SVHS_PROMPT='arrow'
_SVHS_PROMPT_MODE='theme'

# Bundled themes, rendered per shell by _svhs_theme_prompt
_SVHS_PROMPT_THEMES='arrow plain path powerline'

# Theme glyphs as bytes to keep this file ASCII. agg bundles their fallbacks;
# asg names system fallbacks in the SVG
# U+276F arrow, U+E0B0 powerline separator
_SVHS_PROMPT_ARROW=$'\xe2\x9d\xaf'
_SVHS_POWERLINE_SEPARATOR=$'\xee\x82\xb0'

# NAME=VALUE pairs exported into the recorded shell by Env
_SVHS_ENV=()

# Host-shell command lines registered by Finally, run by svhs_cleanup at exit
_SVHS_FINALLY_COMMANDS=()

# Named per process so parallel recordings do not share copied text
_SVHS_COPY_BUFFER="s-vhs-copy-$$"
_SVHS_COPY_BUFFER_SET=0

# tmux style the Highlight selection is painted with, assembled by
# SetHighlightColors; empty = tmux's own mode-style, bg=yellow,fg=black
_SVHS_HIGHLIGHT_STYLE=''

# Delays in seconds; HIGHLIGHT_SPEED is per cell of a sweep, and stands apart
# from the other two because a drag reads as one motion rather than as typing
_SVHS_TYPING_SPEED=0.07
_SVHS_KEY_DELAY=0.0
_SVHS_HIGHLIGHT_SPEED=0.03

# tmux poll interval, and how long the recorder may take to attach
_SVHS_POLL_INTERVAL=0.2
_SVHS_ATTACH_TIMEOUT=5

# Viewer redraw interval; tighter than the tmux poll so a typed
# character shows up as it lands
_SVHS_WATCH_INTERVAL=0.1

# Viewer escapes: ENTER switches to the alternate screen, hides the cursor
# and disables line wrapping; RESTORE undoes all three
_SVHS_WATCH_CLEAR=$'\033[2J\033[H'
_SVHS_WATCH_ENTER=$'\033[?1049h\033[?25l\033[?7l'"$_SVHS_WATCH_CLEAR"
_SVHS_WATCH_RESTORE=$'\033[0m\033[?7h\033[?25h\033[?1049l'

# Shell readiness timeout; longer than ATTACH_TIMEOUT since a native
# configuration may load plugins on startup
_SVHS_SHELL_TIMEOUT=10

# Cast-file write polling; the recorder flushes every event, so poll tightly
_SVHS_WRITE_POLL_INTERVAL=0.01
_SVHS_WRITE_TIMEOUT=5

# Recorded shell command line and environment, assembled by Start
_SVHS_SHELL_COMMAND=()
_SVHS_SHELL_ENV=()

# agg's font selection, assembled by Start so the resolution probe and the
# render resolve the same faces
_SVHS_AGG_FONT_ARGS=()

# Session and recorder lifecycle state
_SVHS_STARTED=0
_SVHS_CAST=''
_SVHS_TEMP_CAST=''
# Shared raster intermediate, removed after Render or on exit
_SVHS_TEMP_GIF=''
_SVHS_REC_PID=''
_SVHS_RECORDED=''


## Template


_SVHS_TEMPLATE=$(cat <<TEMPLATE
#!/usr/bin/env bash

source <(curl -fsSL https://dimk90.github.io/s-vhs/v$(svhs_version)) && wait "\$!" || exit 1

SetOutput 'demo.gif'

# SetCols 100
# SetRows 40
# SetShell 'bash'
# SetPrompt 'arrow'

# SetFontSize 28
# SetFontFamily 'JetBrains Mono'
# SetTheme 'dracula'

# SetTypingSpeed 0.07
# SetPlaybackSpeed 1
# SetFramerate 30
# SetLoop on
# SetOptimize off

# Require 'git' 'jq'

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
    # Add a cast, plain-text, GIF, animated WebP, or animated SVG output.
    #
    # Parameters:
    #   $1 - output - path ending in .cast, .txt, .gif, .webp, or .svg.
    #
    # Example:
    #   SetOutput 'demo.gif' || exit 1
    #
    local output="${1-}"

    _svhs_require_configuration_phase 'SetOutput' || return 1

    case "$output" in
        *.cast|*.txt|*.gif|*.webp|*.svg) ;;
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
    # Set preferred font families used to render text, followed by the
    # renderer's default text, Nerd Font and emoji fallbacks.
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
    if [[ -n $_SVHS_EMOJI_FONT_FAMILY ]]; then
        printf 'SetFontFamilyExact: cannot be combined with SetEmojiFontFamily\n' >&2
        return 1
    fi

    _SVHS_FONT_FAMILY_EXACT="$font_family"
}


SetEmojiFontFamily() {
    #
    # Set the families emoji are drawn with, in place of the renderer's own
    # emoji chain. The raster renderer picks the first family carrying the
    # glyph; the SVG only names them, so the viewer's system decides.
    #
    # Parameters:
    #   $1 - emoji_font_family - non-empty comma-separated family list.
    #
    # Example:
    #   SetEmojiFontFamily 'Noto Color Emoji' || exit 1
    #
    local emoji_font_family="${1-}"

    _svhs_require_configuration_phase 'SetEmojiFontFamily' || return 1

    if [[ -z $emoji_font_family ]]; then
        printf 'SetEmojiFontFamily: font family must not be empty\n' >&2
        return 1
    fi
    # an exact list already names every family, emoji ones included, and agg
    # rejects the two flags at once
    if [[ -n $_SVHS_FONT_FAMILY_EXACT ]]; then
        printf 'SetEmojiFontFamily: cannot be combined with SetFontFamilyExact\n' >&2
        return 1
    fi

    _SVHS_EMOJI_FONT_FAMILY="$emoji_font_family"
}


SetFontDir() {
    #
    # Add a directory the raster renderer searches for fonts on top of the
    # installed ones; repeatable. Fonts kept next to the recording script
    # render the same on a machine that has none of them installed.
    #
    # Parameters:
    #   $1 - font_dir - existing directory holding font files.
    #
    # Example:
    #   SetFontDir './fonts' || exit 1
    #
    local font_dir="${1-}"

    _svhs_require_configuration_phase 'SetFontDir' || return 1

    if [[ -z $font_dir ]]; then
        printf 'SetFontDir: font directory must not be empty\n' >&2
        return 1
    fi
    # agg passes over a directory that is not there, leaving a recording that
    # differs only by its font, so a mistyped path is reported here instead
    if [[ ! -d $font_dir ]]; then
        printf 'SetFontDir: not a directory: %s\n' "$font_dir" >&2
        return 1
    fi

    _SVHS_FONT_DIRS+=("$font_dir")
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
    # Set a renderer theme name or custom palette value.
    #
    # Parameters:
    #   $1 - theme - non-empty value passed to the renderer's --theme.
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


SetBoldIsBright() {
    #
    # Draw bold text in the bright ANSI color (0..7 -> 8..15), the way most
    # terminals show it, instead of the literal color it was written with.
    #
    # Parameters:
    #   $1 - bold_is_bright - 'on' or 'off'.
    #
    # Example:
    #   SetBoldIsBright 'on' || exit 1
    #
    local bold_is_bright="${1-}"

    _svhs_require_configuration_phase 'SetBoldIsBright' || return 1

    case "$bold_is_bright" in
        on|off) ;;
        *)
            printf 'SetBoldIsBright: expected on or off, got: %s\n' \
                "$bold_is_bright" >&2
            return 1
            ;;
    esac

    _SVHS_BOLD_IS_BRIGHT="$bold_is_bright"
}


SetEngine() {
    #
    # Select the backend GIF and WebP frames are rasterized with. 'resvg'
    # draws COLRv1 emoji - recent Noto Color Emoji - in color, which 'swash'
    # renders monochrome; 'swash' is the faster one and the only one font
    # hinting applies to.
    #
    # Parameters:
    #   $1 - engine - 'swash' or 'resvg'.
    #
    # Example:
    #   SetEngine 'resvg' || exit 1
    #
    local engine="${1-}"

    _svhs_require_configuration_phase 'SetEngine' || return 1

    case "$engine" in
        swash|resvg) ;;
        *)
            printf 'SetEngine: expected swash or resvg, got: %s\n' "$engine" >&2
            return 1
            ;;
    esac

    _SVHS_ENGINE="$engine"
    _SVHS_ENGINE_SET=1
}


SetOptimize() {
    #
    # Shrink the rendered animation at the cost of a slower `Render`, without
    # changing a pixel: a GIF through a lossless `gifsicle` pass, typically by
    # a fifth to a quarter, a WebP through the encoder's slowest lossless
    # effort, typically by a few per cent. Without gifsicle installed the GIF
    # is written unoptimized.
    #
    # Parameters:
    #   $1 - optimize - 'on' or 'off'.
    #
    # Example:
    #   SetOptimize 'on' || exit 1
    #
    local optimize="${1-}"

    _svhs_require_configuration_phase 'SetOptimize' || return 1

    case "$optimize" in
        on|off) ;;
        *)
            printf 'SetOptimize: expected on or off, got: %s\n' "$optimize" >&2
            return 1
            ;;
    esac

    _SVHS_OPTIMIZE="$optimize"
}


SetPadding() {
    #
    # Set the padding drawn around the terminal on both axes, in the theme's
    # background color.
    #
    # Parameters:
    #   $1 - padding - non-negative integer number of output pixels.
    #
    # Example:
    #   SetPadding 20 || exit 1
    #
    local padding="${1-}"

    _svhs_require_configuration_phase 'SetPadding' || return 1

    if ! _svhs_is_nonnegative_integer "$padding"; then
        printf 'SetPadding: expected a non-negative integer, got: %s\n' \
            "$padding" >&2
        return 1
    fi

    _SVHS_PADDING="$padding"
}


SetPaddingX() {
    #
    # Set the padding left and right of the terminal, overriding SetPadding
    # on that axis.
    #
    # Parameters:
    #   $1 - padding - non-negative integer number of output pixels.
    #
    # Example:
    #   SetPaddingX 40 || exit 1
    #
    local padding="${1-}"

    _svhs_require_configuration_phase 'SetPaddingX' || return 1

    if ! _svhs_is_nonnegative_integer "$padding"; then
        printf 'SetPaddingX: expected a non-negative integer, got: %s\n' \
            "$padding" >&2
        return 1
    fi

    _SVHS_PADDING_X="$padding"
}


SetPaddingY() {
    #
    # Set the padding above and below the terminal, overriding SetPadding on
    # that axis.
    #
    # Parameters:
    #   $1 - padding - non-negative integer number of output pixels.
    #
    # Example:
    #   SetPaddingY 10 || exit 1
    #
    local padding="${1-}"

    _svhs_require_configuration_phase 'SetPaddingY' || return 1

    if ! _svhs_is_nonnegative_integer "$padding"; then
        printf 'SetPaddingY: expected a non-negative integer, got: %s\n' \
            "$padding" >&2
        return 1
    fi

    _SVHS_PADDING_Y="$padding"
}


SetWindowBar() {
    #
    # Draw macOS-style window decorations - a bar with three buttons - above
    # the terminal.
    #
    # Parameters:
    #   $1 - window_bar - 'on' or 'off'.
    #
    # Example:
    #   SetWindowBar 'on' || exit 1
    #
    local window_bar="${1-}"

    _svhs_require_configuration_phase 'SetWindowBar' || return 1

    case "$window_bar" in
        on|off) ;;
        *)
            printf 'SetWindowBar: expected on or off, got: %s\n' "$window_bar" >&2
            return 1
            ;;
    esac

    _SVHS_WINDOW_BAR="$window_bar"
}


SetCursor() {
    #
    # Draw the terminal cursor; turning it off leaves the recorded text on
    # screen without the block trailing it.
    #
    # Parameters:
    #   $1 - cursor - 'on' or 'off'.
    #
    # Example:
    #   SetCursor 'off' || exit 1
    #
    local cursor="${1-}"

    _svhs_require_configuration_phase 'SetCursor' || return 1

    case "$cursor" in
        on|off) ;;
        *)
            printf 'SetCursor: expected on or off, got: %s\n' "$cursor" >&2
            return 1
            ;;
    esac

    _SVHS_CURSOR="$cursor"
}


SetPlaybackSpeed() {
    #
    # Set how fast the rendered animation plays back; the cast itself keeps
    # the timing it was recorded with.
    #
    # Parameters:
    #   $1 - playback_speed - positive multiplier; 2 plays twice as fast.
    #
    # Example:
    #   SetPlaybackSpeed 2 || exit 1
    #
    local playback_speed="${1-}"

    _svhs_require_configuration_phase 'SetPlaybackSpeed' || return 1

    if ! _svhs_is_positive_number "$playback_speed"; then
        printf 'SetPlaybackSpeed: expected a positive number, got: %s\n' \
            "$playback_speed" >&2
        return 1
    fi

    _SVHS_PLAYBACK_SPEED="$playback_speed"
}


SetFramerate() {
    #
    # Set the maximum number of rendered frames per second.
    #
    # Parameters:
    #   $1 - framerate - positive integer frames per second.
    #
    # Example:
    #   SetFramerate 60 || exit 1
    #
    local framerate="${1-}"

    _svhs_require_configuration_phase 'SetFramerate' || return 1

    if ! _svhs_is_positive_integer "$framerate"; then
        printf 'SetFramerate: expected a positive integer, got: %s\n' \
            "$framerate" >&2
        return 1
    fi

    _SVHS_FRAMERATE="$framerate"
}


SetIdleTimeLimit() {
    #
    # Cap how long a pause is played back, so a wait for a slow command does
    # not stall the animation. Applied while rendering, so the cast keeps
    # every pause at its recorded length.
    #
    # Parameters:
    #   $1 - idle_time_limit - positive number of seconds.
    #
    # Example:
    #   SetIdleTimeLimit 2 || exit 1
    #
    local idle_time_limit="${1-}"

    _svhs_require_configuration_phase 'SetIdleTimeLimit' || return 1

    if ! _svhs_is_positive_number "$idle_time_limit"; then
        printf 'SetIdleTimeLimit: expected a positive number, got: %s\n' \
            "$idle_time_limit" >&2
        return 1
    fi

    _SVHS_IDLE_TIME_LIMIT="$idle_time_limit"
}


SetLoop() {
    #
    # Repeat the rendered animation, or stop it after a single pass.
    #
    # Parameters:
    #   $1 - loop - 'on' or 'off'.
    #
    # Example:
    #   SetLoop 'off' || exit 1
    #
    local loop="${1-}"

    _svhs_require_configuration_phase 'SetLoop' || return 1

    case "$loop" in
        on|off) ;;
        *)
            printf 'SetLoop: expected on or off, got: %s\n' "$loop" >&2
            return 1
            ;;
    esac

    _SVHS_LOOP="$loop"
}


SetLastFrameDuration() {
    #
    # Set how long the last GIF or WebP frame is held before the loop restarts.
    #
    # Parameters:
    #   $1 - last_frame_duration - non-negative number of seconds.
    #
    # Example:
    #   SetLastFrameDuration 1.5 || exit 1
    #
    local last_frame_duration="${1-}"

    _svhs_require_configuration_phase 'SetLastFrameDuration' || return 1

    if ! _svhs_is_nonnegative_number "$last_frame_duration"; then
        printf 'SetLastFrameDuration: expected a non-negative number, got: %s\n' \
            "$last_frame_duration" >&2
        return 1
    fi

    _SVHS_LAST_FRAME_DURATION="$last_frame_duration"
    _SVHS_LAST_FRAME_DURATION_SET=1
}


SetTitle() {
    #
    # Set the title stored in the cast metadata and shown by players.
    #
    # Parameters:
    #   $1 - title - non-empty cast title.
    #
    # Example:
    #   SetTitle 'API demo' || exit 1
    #
    local title="${1-}"

    _svhs_require_configuration_phase 'SetTitle' || return 1

    if [[ -z $title ]]; then
        printf 'SetTitle: title must not be empty\n' >&2
        return 1
    fi

    _SVHS_TITLE="$title"
}


SetQuiet() {
    #
    # Suppress recorder, text converter, raster renderer and s-vhs informational
    # messages while keeping errors visible.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   SetQuiet || exit 1
    #
    _svhs_require_configuration_phase 'SetQuiet' || return 1

    _SVHS_QUIET=1
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
        _svhs_warn "SetShell: $shell is not installed, falling back to bash"
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


SetHighlightColors() {
    #
    # Set the colors Highlight paints its selection with. Each color is a tmux
    # style value: a name ('yellow'), an index ('colour208') or a hex triplet
    # ('#5f87ff').
    #
    # Parameters:
    #   $1 - background - selection background color.
    #   $2 - foreground - (optional) - color of the selected text.
    #   $3 - attributes - (optional) - comma-separated tmux style attributes
    #        the selection is drawn with, such as 'bold' or 'bold,underscore'.
    #
    # Example:
    #   SetHighlightColors 'yellow' 'black' 'bold' || exit 1
    #
    local background="${1-}"
    local foreground="${2-}"
    local attributes="${3-}"
    local style

    _svhs_require_configuration_phase 'SetHighlightColors' || return 1

    if [[ -z $background ]]; then
        printf 'SetHighlightColors: background must not be empty\n' >&2
        return 1
    fi

    # Colors and attributes are passed through to tmux, which knows its own
    # palette and attribute names; Start reports what it rejects
    style="bg=$background"
    [[ -n $foreground ]] && style+=",fg=$foreground"
    [[ -n $attributes ]] && style+=",$attributes"

    _SVHS_HIGHLIGHT_STYLE="$style"
}


SetHighlightSpeed() {
    #
    # Set the default delay Highlight sweeps one cell of its selection with.
    #
    # Parameters:
    #   $1 - highlight_speed - non-negative number of seconds.
    #
    # Example:
    #   SetHighlightSpeed 0.05 || exit 1
    #
    local highlight_speed="${1-}"

    _svhs_require_configuration_phase 'SetHighlightSpeed' || return 1

    if ! _svhs_is_nonnegative_number "$highlight_speed"; then
        printf 'SetHighlightSpeed: expected a non-negative number, got: %s\n' \
            "$highlight_speed" >&2
        return 1
    fi

    _SVHS_HIGHLIGHT_SPEED="$highlight_speed"
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


Require() {
    #
    # Fail immediately unless every named command is available on PATH.
    #
    # Parameters:
    #   $@ - command_names - one or more commands the recording needs.
    #
    # Example:
    #   Require 'git' 'jq' || exit 1
    #
    local command_name

    _svhs_require_configuration_phase 'Require' || return 1

    if [[ $# -eq 0 ]]; then
        printf 'Require: expected at least one command\n' >&2
        return 1
    fi

    for command_name in "$@"; do
        if [[ -z $command_name ]]; then
            printf 'Require: command name must not be empty\n' >&2
            return 1
        fi

        _svhs_require_command 'Require' "$command_name" 'the recording' || return 1
    done
}


## Session


Finally() {
    #
    # Register a command to run in the host shell when the script exits,
    # however it ends - success, a failed Wait, or Ctrl-C. Repeatable, and
    # the last registered runs first, so fixtures unwind in reverse creation
    # order. Legal before Start and mid-recording alike.
    #
    # Parameters:
    #   $1 - command_line - shell command line evaluated by svhs_cleanup once
    #        the session and the recorder are gone. Nothing is typed into the
    #        session - the opposite of Run and RunOffRecord.
    #
    # Example:
    #   Finally 'rm -rf "$WORK_DIR"' || exit 1
    #
    local command_line="${1-}"

    if [[ -z $command_line ]]; then
        printf 'Finally: expected a command to run at exit\n' >&2
        return 1
    fi

    _SVHS_FINALLY_COMMANDS+=("$command_line")
}


Start() {
    #
    # Start a fresh detached tmux session with the configured geometry, shell
    # and prompt on the dedicated s-vhs server, isolated from personal tmux
    # config and without a status bar, and report the S-VHS version and how
    # to attach to it. It returns once the shell's line editor starts reading,
    # so the first input cannot race its startup.
    #
    # Parameters:
    #   $1 - wait_mode - (optional) - 'no-wait' returns as soon as the shell
    #        is spawned, leaving a session whose startup can be inspected.
    #
    # Example:
    #   Start || exit 1
    #   Start 'no-wait' || exit 1
    #
    local wait_mode="${1-}"
    local variable
    local env_args=()

    case "$wait_mode" in
        ''|no-wait) ;;
        *)
            printf 'Start: expected no-wait or no argument, got: %s\n' "$wait_mode" >&2
            return 1
            ;;
    esac

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
    _svhs_build_agg_font_args

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

    _svhs_apply_highlight_style || return 1

    if [[ $wait_mode != 'no-wait' ]]; then
        _svhs_wait_for_shell || return 1
    fi

    # The session runs on its own socket with the status bar off and a name
    # carrying a PID, so watching a recording live takes the printed command
    if [[ $_SVHS_QUIET == 0 ]]; then
        printf '::: S-VHS v%s\n' "$(svhs_version)"
        printf '::: Started session %s, attach with: tmux -L %s attach -t %s\n' \
            "$_SVHS_SESSION" "$_SVHS_TMUX_SOCKET" "$_SVHS_SESSION"
        _svhs_report_geometry
    fi
}


svhs_cleanup() {
    #
    # Kill the recording session and recorder, remove an unrequested temporary
    # cast, the temporary GIF and the Copy buffer, then run Finally commands.
    # Installed as the EXIT trap while sourcing, and safe to call when neither
    # the session nor the recorder is alive. A recording registers its own
    # cleanup with Finally; this is public for the one case Finally cannot
    # cover - an EXIT trap of the recording's own, which replaces this one and
    # so has to chain it: trap 'svhs_cleanup; my_cleanup' EXIT
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   svhs_cleanup
    #
    local index

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
    if [[ -n $_SVHS_TEMP_GIF ]]; then
        rm -f -- "$_SVHS_TEMP_GIF"
    fi
    if [[ $_SVHS_COPY_BUFFER_SET == 1 ]]; then
        tmux -L "$_SVHS_TMUX_SOCKET" delete-buffer \
            -b "$_SVHS_COPY_BUFFER" 2> /dev/null || true
    fi

    # Handlers run last, and in reverse registration order: the recorded
    # process reads the fixtures they remove until the session dies, and a
    # later fixture may live inside an earlier one. A failing handler must
    # neither stop the rest nor change the script's exit status
    # bash 3.2 (stock macOS) treats an empty array as unset, so the count is
    # read only once Finally has registered a non-empty command line
    if [[ -n ${_SVHS_FINALLY_COMMANDS[*]-} ]]; then
        for ((index = ${#_SVHS_FINALLY_COMMANDS[@]} - 1; index >= 0; index--)); do
            eval "${_SVHS_FINALLY_COMMANDS[index]}" || true
        done
    fi
}


svhs_watch() {
    #
    # Watch a recording's pane live from another terminal, by repainting a
    # snapshot of it several times a second. No tmux client is attached, so
    # the viewer cannot resize the pane, send input to it, or interfere with
    # the recorder. It waits for the session to appear, returns to waiting
    # once the recording ends, and runs until interrupted with Ctrl-C.
    #
    # Parameters:
    #   $1 - session - (optional) - session name to watch; without it, the
    #        newest default s-vhs-<pid> session is picked, so the viewer can
    #        be left running across recordings.
    #
    # Example:
    #   svhs_watch 'demo'
    #
    local session="${1-}"

    if [[ $# -ge 1 && -z $session ]]; then
        printf 'svhs_watch: session name must not be empty\n' >&2
        return 1
    fi

    _svhs_require_command 'svhs_watch' 'tmux' 'the live pane viewer' || return 1

    # the viewer takes the terminal over, so its restoring EXIT trap runs in a
    # subshell of its own rather than replacing the caller's svhs_cleanup
    (
        trap 'printf "%s" "$_SVHS_WATCH_RESTORE"' EXIT
        trap 'exit 130' INT TERM

        printf '%s' "$_SVHS_WATCH_ENTER"
        _svhs_watch_loop "$session"
    )
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
Enter()     { Key Enter ${@+"$@"};    }
Tab()       { Key Tab ${@+"$@"};      }
Space()     { Key Space ${@+"$@"};    }
Backspace() { Key BSpace ${@+"$@"};   }
Escape()    { Key Escape ${@+"$@"};   }
Up()        { Key Up ${@+"$@"};       }
Down()      { Key Down ${@+"$@"};     }
Left()      { Key Left ${@+"$@"};     }
Right()     { Key Right ${@+"$@"};    }
PageUp()    { Key PageUp ${@+"$@"};   }
PageDown()  { Key PageDown ${@+"$@"}; }
Home()      { Key Home ${@+"$@"};     }
End()       { Key End ${@+"$@"};      }
Insert()    { Key IC ${@+"$@"};       }
Delete()    { Key DC ${@+"$@"};       }
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


Copy() {
    #
    # Store text in this recording's tmux buffer without touching the system
    # clipboard.
    #
    # Parameters:
    #   $1 - text - non-empty text to copy.
    #
    # Example:
    #   Copy 'pasted as one block' || exit 1
    #
    local text="${1-}"

    if [[ -z $text ]]; then
        printf 'Copy: text must not be empty\n' >&2
        return 1
    fi

    # tmux treats an argument ending in ; as a command separator
    if [[ $text == *';' ]]; then
        text="${text%;}"'\;'
    fi

    tmux -L "$_SVHS_TMUX_SOCKET" set-buffer \
        -b "$_SVHS_COPY_BUFFER" -- "$text" || return 1
    _SVHS_COPY_BUFFER_SET=1
}


Paste() {
    #
    # Paste the text stored by Copy as a bracketed paste.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   Paste || exit 1
    #
    if [[ $_SVHS_COPY_BUFFER_SET == 0 ]]; then
        printf 'Paste: no text has been copied\n' >&2
        return 1
    fi

    tmux -L "$_SVHS_TMUX_SOCKET" paste-buffer -p \
        -b "$_SVHS_COPY_BUFFER" -t "$_SVHS_SESSION"
}


Highlight() {
    #
    # Sweep a selection across text already on screen the way a mouse drag
    # would, hold it, then release it. Purely visual: nothing is copied, and
    # the pane is left exactly as it was found.
    #
    # The text is matched literally against the visible pane, so it has to sit
    # on a single row; a text that is not there is reported and skipped,
    # leaving the frame as it is. When it occurs more than once, the occurrence
    # closest to the cursor is selected.
    #
    # Parameters:
    #   $1 - text - text to select, as it appears on screen.
    #   $2 - hold - (optional) - seconds to keep the selection up (default: 1).
    #   $3 - delay - (optional) - seconds per swept cell
    #        (default: SetHighlightSpeed).
    #
    # Example:
    #   Highlight 'Welcome to s-vhs' 2
    #
    local text="${1-}"
    local hold="${2:-1}"
    local delay="${3:-$_SVHS_HIGHLIGHT_SPEED}"

    if [[ -z $text ]]; then
        printf 'Highlight: text must not be empty\n' >&2
        return 1
    fi

    if ! _svhs_is_nonnegative_number "$hold"; then
        printf 'Highlight: expected a non-negative number, got: %s\n' "$hold" >&2
        return 1
    fi

    if ! _svhs_is_nonnegative_number "$delay"; then
        printf 'Highlight: expected a non-negative delay, got: %s\n' "$delay" >&2
        return 1
    fi

    # Missing text is the recording's own timing rather than a scripting
    # error - a Wait away from working - so it must not end the run
    if ! tmux -L "$_SVHS_TMUX_SOCKET" capture-pane -p -t "$_SVHS_SESSION" |
        grep -qF -- "$text"; then
        _svhs_warn "Highlight: not on screen, nothing selected: $text"
        return 0
    fi

    _svhs_sweep_selection "$text" "$delay"
    sleep "$hold"
    _svhs_send -X cancel
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
    #   $1 - pattern - extended regular expression (grep -E) to wait for.
    #   $2 - timeout - (optional) - seconds before giving up (default: 15).
    #
    # Example:
    #   Wait 'build succeeded' 30
    #
    local pattern="$1"
    local timeout="${2:-15}"

    _svhs_wait_for_pattern 'Wait' 'screen' "$pattern" "$timeout"
}


WaitLine() {
    #
    # Poll the cursor's current row until a pattern appears, without matching
    # an earlier occurrence elsewhere in the visible pane.
    #
    # Parameters:
    #   $1 - pattern - extended regular expression (grep -E) to wait for.
    #   $2 - timeout - (optional) - seconds before giving up (default: 15).
    #
    # Example:
    #   WaitLine '^Username:$' 30
    #
    local pattern="$1"
    local timeout="${2:-15}"

    _svhs_wait_for_pattern 'WaitLine' 'line' "$pattern" "$timeout"
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
    local recorder_args=()
    # asciinema rejects --overwrite next to --append, so the flags are
    # exclusive: the first segment replaces a stale cast, later ones extend it
    local write_mode='--overwrite'

    if [[ -n $_SVHS_RECORDED ]]; then
        write_mode='--append'
    elif [[ -n $_SVHS_TITLE ]]; then
        # Metadata belongs to the cast header written by the first segment,
        # so append segments must not repeat it
        recorder_args+=(-t "$_SVHS_TITLE")
    fi
    [[ $_SVHS_QUIET == 1 ]] && recorder_args+=(-q)

    printf -v attach_command 'tmux -L %q attach -t %q' \
        "$_SVHS_TMUX_SOCKET" "$_SVHS_SESSION"

    # asciinema holds the foreground for the whole segment while the script
    # keeps driving the session, so it runs in the background and its PID is
    # kept for Hide and Render to stop it
    asciinema rec ${recorder_args[@]+"${recorder_args[@]}"}    \
                  --headless "$write_mode"                     \
                  --window-size "${_SVHS_COLS}x${_SVHS_ROWS}"  \
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
    local clean_lines

    _svhs_flush_frame 'Hide' || return 1

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
    # End the recording, retain requested casts, and render requested outputs.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   Render || exit 1
    #
    local clean_lines=''
    local output
    local asg_font_args=()
    local asg_frame_args=()
    local quiet_args=()
    local loop_args=()

    # As in Hide, the closing frame needs an event of its own - without it the
    # Sleep before Render is dropped - and the kill's noise is truncated away
    # afterwards. A finished recording is not worth discarding over its last
    # frame, so a failed flush costs that frame and nothing else
    if [[ -n $_SVHS_REC_PID ]]; then
        _svhs_flush_frame 'Render' || true
        clean_lines=$(wc -l < "$_SVHS_CAST")
    fi

    tmux -L "$_SVHS_TMUX_SOCKET" kill-session -t "$_SVHS_SESSION"

    if [[ -n $_SVHS_REC_PID ]]; then
        wait "$_SVHS_REC_PID"
        _svhs_truncate "$_SVHS_CAST" "$clean_lines"
    fi
    _SVHS_REC_PID=''

    if [[ -n $_SVHS_FONT_FAMILY_EXACT ]]; then
        asg_font_args+=(--font-family "$_SVHS_FONT_FAMILY_EXACT")
    elif [[ -n $_SVHS_FONT_FAMILY || -n $_SVHS_EMOJI_FONT_FAMILY ]]; then
        # the SVG chain is built as a whole, so it is only worth naming once one
        # of its two configurable parts was set
        asg_font_args+=(--font-family "$(_svhs_svg_font_family)")
    fi

    [[ $_SVHS_QUIET == 1 ]] && quiet_args=(-q)
    # both renderers loop on their own and spell only the opt-out
    [[ $_SVHS_LOOP == 'off' ]] && loop_args=(--no-loop)

    # SVG-only frame: an axis override is named only once it was set, so both
    # axes otherwise follow --padding, and asg spells a window bar as the
    # opt-in and the cursor as the opt-out
    [[ -n $_SVHS_PADDING_X ]] && asg_frame_args+=(--padding-x "$_SVHS_PADDING_X")
    [[ -n $_SVHS_PADDING_Y ]] && asg_frame_args+=(--padding-y "$_SVHS_PADDING_Y")
    [[ $_SVHS_WINDOW_BAR == 'on' ]] && asg_frame_args+=(--window)
    [[ $_SVHS_CURSOR == 'off' ]] && asg_frame_args+=(--no-cursor)

    # A caller's `Render || exit 1` suspends set -e for this whole function, so
    # check every output explicitly rather than announcing a failed render
    for output in "${_SVHS_OUTPUTS[@]}"; do
        case "$output" in
            *.cast)
                if [[ $output != "$_SVHS_CAST" ]]; then
                    cp -- "$_SVHS_CAST" "$output" || return 1
                fi
                ;;
            *.txt)
                asciinema convert -f txt --overwrite \
                    ${quiet_args[@]+"${quiet_args[@]}"} \
                    "$_SVHS_CAST" "$output" || return 1
                ;;
            *.gif|*.webp)
                _svhs_render_raster "$output" || return 1
                ;;
            *.svg)
                asg ${asg_font_args[@]+"${asg_font_args[@]}"}   \
                    ${asg_frame_args[@]+"${asg_frame_args[@]}"} \
                    ${loop_args[@]+"${loop_args[@]}"}           \
                    --font-size "$_SVHS_FONT_SIZE"              \
                    --line-height "$_SVHS_LINE_HEIGHT"          \
                    --theme "$_SVHS_THEME"                      \
                    --padding "$_SVHS_PADDING"                  \
                    --speed "$_SVHS_PLAYBACK_SPEED"             \
                    --fps "$_SVHS_FRAMERATE"                    \
                    --idle-time-limit "$_SVHS_IDLE_TIME_LIMIT"  \
                    "$_SVHS_CAST" "$output" || return 1
                _svhs_report_svg_skips "$output"
                ;;
        esac

        if [[ $_SVHS_QUIET == 0 ]]; then
            printf '::: Wrote %s\n' "$output"
        fi
    done

    if [[ -n $_SVHS_TEMP_CAST ]]; then
        rm -f -- "$_SVHS_TEMP_CAST"
        _SVHS_TEMP_CAST=''
    fi
    if [[ -n $_SVHS_TEMP_GIF ]]; then
        rm -f -- "$_SVHS_TEMP_GIF"
        _SVHS_TEMP_GIF=''
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
    #   $1 - caller - public command name to report the failure under.
    #   $2 - command_name - executable the recording needs.
    #   $3 - purpose - what it is needed for.
    #
    # Example:
    #   _svhs_require_command 'Start' 'agg' 'GIF output' || return 1
    #
    local caller="$1"
    local command_name="$2"
    local purpose="$3"

    if ! command -v "$command_name" > /dev/null 2>&1; then
        printf '%s: %s is not installed, required for %s\n' \
            "$caller" "$command_name" "$purpose" >&2
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
    local webp=0
    local encoders

    _svhs_require_command 'Start' 'tmux' 'the recording session' || return 1
    _svhs_require_command 'Start' 'asciinema' 'the recorder' || return 1

    for output in "${_SVHS_OUTPUTS[@]}"; do
        case "$output" in
            *.gif) _svhs_require_command 'Start' 'agg' 'GIF output' || return 1 ;;
            *.webp)
                _svhs_require_command 'Start' 'agg' 'WebP output' || return 1
                _svhs_require_command 'Start' 'ffmpeg' 'WebP output' || return 1
                webp=1
                ;;
            *.svg) _svhs_require_command 'Start' 'asg' 'SVG output' || return 1 ;;
        esac
    done

    [[ $webp == 0 ]] && return 0

    # ffmpeg builds can omit libwebp; a listing that fails at all is a broken
    # ffmpeg rather than a missing encoder, and worth a line of its own
    if ! encoders=$(ffmpeg -hide_banner -encoders 2> /dev/null); then
        printf 'Start: ffmpeg failed to list its encoders\n' >&2
        return 1
    fi
    if [[ $encoders != *' libwebp_anim '* ]]; then
        printf 'Start: ffmpeg lacks the libwebp_anim encoder, required for WebP output\n' >&2
        return 1
    fi
    return 0
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


_svhs_watch_target() {
    #
    # Print the session the viewer should follow, or nothing when none is
    # alive yet.
    #
    # Parameters:
    #   $1 - session - session name to look for; empty picks the newest
    #        default s-vhs-<pid> session.
    #
    # Example:
    #   target=$(_svhs_watch_target 'demo')
    #
    local session="$1"

    if [[ -n $session ]]; then
        _svhs_session_exists "$session" && printf '%s\n' "$session"
        return 0
    fi

    # the newest default session is the recording that just started; sorting
    # by creation time and then by name keeps the pick independent of the
    # order tmux happens to list them in, and a name says nothing about age
    tmux -L "$_SVHS_TMUX_SOCKET" list-sessions \
         -F '#{session_created} #{session_name}' 2> /dev/null \
        | grep ' s-vhs-[0-9][0-9]*$'                          \
        | sort -k1,1nr -k2,2                                  \
        | head -n 1                                           \
        | cut -d ' ' -f 2 || true
}


_svhs_watch_pane() {
    #
    # Repaint one session's visible pane until it is gone.
    #
    # Parameters:
    #   $1 - session - session name to capture.
    #
    # Example:
    #   _svhs_watch_pane 'demo'
    #
    local session="$1"
    local frame

    while :; do
        # -p writes the pane to stdout without creating a client, -e keeps its
        # ANSI attributes, 24-bit color included; a failing capture is the
        # session ending, which returns the viewer to waiting
        frame=$(tmux -L "$_SVHS_TMUX_SOCKET" capture-pane \
            -e -p -t "$session" 2> /dev/null) || return 0

        # each row is written at its own address and cleared to the end of the
        # line, and the rows below the last one are dropped, so the picture
        # never blinks the way clearing the screen per frame would
        printf '%s\n' "$frame" | awk '
            { printf "\033[%d;1H%s\033[0m\033[K", NR, $0 }
            END { printf "\033[%d;1H\033[J", NR + 1 }'

        sleep "$_SVHS_WATCH_INTERVAL"
    done
}


_svhs_watch_loop() {
    #
    # Follow recordings until interrupted: wait for a session, paint it while
    # it lives, and wait again once it ends, so a viewer left running picks up
    # the next run of a recording script.
    #
    # Parameters:
    #   $1 - session - session name to watch; empty follows default ones.
    #
    # Example:
    #   _svhs_watch_loop 'demo'
    #
    local session="$1"
    local target
    local waiting=''

    while :; do
        target=$(_svhs_watch_target "$session")

        if [[ -z $target ]]; then
            # painted once per wait, so the message does not blink while the
            # session is polled for
            if [[ -z $waiting ]]; then
                printf '%s' "$_SVHS_WATCH_CLEAR"
                if [[ $_SVHS_QUIET == 0 ]]; then
                    printf '::: Waiting for %s, Ctrl-C to exit\n' \
                        "${session:-an s-vhs session}"
                fi
                waiting=1
            fi
            sleep "$_SVHS_POLL_INTERVAL"
            continue
        fi

        # the frames themselves never clear the screen, so the wait message
        # has to go before the first one of a session is painted
        printf '%s' "$_SVHS_WATCH_CLEAR"
        waiting=''
        _svhs_watch_pane "$target"
    done
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


_svhs_is_nonnegative_integer() {
    #
    # Return success when a value is an integer greater than or equal to zero.
    #
    # Parameters:
    #   $1 - value - value to test.
    #
    # Example:
    #   _svhs_is_nonnegative_integer '20' || exit 1
    #
    local value="$1"

    [[ $value =~ ^(0|[1-9][0-9]*)$ ]] || return 1
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
            # HISTFILE, and leave it alone when it names no file. Apple's
            # Bash 3.2 also needs this variable to omit its zsh migration notice
            _SVHS_SHELL_COMMAND=(bash)
            _SVHS_SHELL_ENV=('HISTFILE=' 'BASH_SILENCE_DEPRECATION_WARNING=1')
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


_svhs_build_agg_font_args() {
    #
    # Assemble agg's font selection into _SVHS_AGG_FONT_ARGS. A configured
    # text list is followed by agg's defaults, so a missing preferred face
    # falls back normally. Settings are frozen once the session starts, so the
    # geometry probe and the render share one font selection.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _svhs_build_agg_font_args
    #
    local font_dir
    local text_font_family

    _SVHS_AGG_FONT_ARGS=()

    if [[ -n $_SVHS_FONT_FAMILY_EXACT ]]; then
        _SVHS_AGG_FONT_ARGS+=(--font-family "$_SVHS_FONT_FAMILY_EXACT")
    else
        if [[ -n $_SVHS_FONT_FAMILY ]]; then
            text_font_family="$_SVHS_FONT_FAMILY,$_SVHS_AGG_TEXT_FONT_DEFAULTS"
            _SVHS_AGG_FONT_ARGS+=(--text-font-family "$text_font_family")
        fi
        [[ -n $_SVHS_EMOJI_FONT_FAMILY ]] &&
            _SVHS_AGG_FONT_ARGS+=(--emoji-font-family "$_SVHS_EMOJI_FONT_FAMILY")
    fi

    for font_dir in ${_SVHS_FONT_DIRS[@]+"${_SVHS_FONT_DIRS[@]}"}; do
        _SVHS_AGG_FONT_ARGS+=(--font-dir "$font_dir")
    done
    return 0
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


_svhs_tty_reads_input() {
    #
    # Return success when a terminal is in the mode a shell's line editor sets
    # while it waits for input: noncanonical, with kernel echo off. It asks
    # the terminal driver, not the screen, so it holds for every prompt -
    # themed, literal, colored or empty.
    #
    # Parameters:
    #   $1 - tty - terminal device to inspect.
    #
    # Example:
    #   _svhs_tty_reads_input '/dev/pts/3' || return 1
    #
    local tty="$1"
    local modes

    # stty spells a disabled flag as -flag and wraps the list over several
    # lines in both userlands; folding it into one padded line makes a flag
    # match on whole words, so -echoprt cannot pass for -echo.
    # stderr is redirected before the terminal, so a pane that vanished
    # between the two silences the failing redirection as well
    modes=$(stty -a 2> /dev/null < "$tty" | tr -s '[:space:]' ' ') || return 1
    modes=" $modes "

    [[ $modes == *' -icanon '* && $modes == *' -echo '* ]] || return 1
    return 0
}


_svhs_wait_for_pattern() {
    #
    # Poll either the whole visible pane or its cursor row for an ERE match.
    #
    # Parameters:
    #   $1 - caller - public command name used in the timeout error.
    #   $2 - scope - 'screen' or 'line'.
    #   $3 - pattern - extended regular expression (grep -E) to wait for.
    #   $4 - timeout - seconds before giving up.
    #
    # Example:
    #   _svhs_wait_for_pattern 'WaitLine' 'line' '^Username:$' 30
    #
    local caller="$1"
    local scope="$2"
    local pattern="$3"
    local timeout="$4"
    local deadline=$((SECONDS + timeout))
    local capture_args=()

    # The current row can sit above blank rows at the pane's bottom, so line
    # scope follows the cursor instead of piping the full capture through tail
    if [[ $scope == 'line' ]]; then
        capture_args=(-S '#{cursor_y}' -E '#{cursor_y}')
    fi

    until tmux -L "$_SVHS_TMUX_SOCKET" capture-pane \
        -p ${capture_args[@]+"${capture_args[@]}"} \
        -t "$_SVHS_SESSION" | grep -qE -- "$pattern"; do
        if ((SECONDS >= deadline)); then
            printf '%s: timeout waiting for: %s\n' "$caller" "$pattern" >&2
            return 1
        fi
        sleep "$_SVHS_POLL_INTERVAL"
    done
}


_svhs_wait_for_shell() {
    #
    # Wait until the session's shell is ready to accept input. A fresh pane
    # starts in canonical, echoing mode, so input sent before the shell's line
    # editor takes over is echoed by the terminal driver as well: the command
    # appears twice and the opening frames differ from run to run.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _svhs_wait_for_shell || return 1
    #
    local deadline=$((SECONDS + _SVHS_SHELL_TIMEOUT))
    local pane
    local tty
    local foreground

    while :; do
        # the session holds a single pane and dies together with the shell,
        # so a failing query means the shell is gone
        pane=$(tmux -L "$_SVHS_TMUX_SOCKET" display-message -p -t "$_SVHS_SESSION" \
            '#{pane_tty} #{pane_current_command}' 2> /dev/null) || {
            printf 'Start: the shell exited during startup\n' >&2
            return 1
        }
        tty="${pane% *}"
        foreground="${pane#* }"

        # a program started by a native configuration can hold the terminal in
        # that very mode, so the shell itself has to be in the foreground too
        if [[ $foreground == "$_SVHS_SHELL" ]] && _svhs_tty_reads_input "$tty"; then
            return 0
        fi

        if ((SECONDS >= deadline)); then
            printf 'Start: %s is not ready for input after %s seconds\n' \
                "$_SVHS_SHELL" "$_SVHS_SHELL_TIMEOUT" >&2
            return 1
        fi
        sleep "$_SVHS_POLL_INTERVAL"
    done
}


_svhs_flush_frame() {
    #
    # Give the frame on screen the time held since the last output, by writing
    # it into the cast as an event of its own. A cast ends at its last event,
    # so a pause held before the recorder stops would otherwise be dropped and
    # that frame would flash by.
    #
    # Parameters:
    #   $1 - caller - public command name to report the failure under.
    #
    # Example:
    #   _svhs_flush_frame 'Hide' || return 1
    #
    local caller="$1"
    local client
    local lines_before
    local deadline

    # Repainting the recorder's client writes an event with the same pixels at
    # the current time. refresh-client targets a client, never a session
    client=$(tmux -L "$_SVHS_TMUX_SOCKET" list-clients \
        -t "$_SVHS_SESSION" -F '#{client_name}' 2> /dev/null | head -1)

    # a session whose shell exited takes the recorder's client with it: there
    # is nothing left to repaint, and waiting for a write would only stall
    if [[ -z $client ]]; then
        printf '%s: the recorder is no longer attached\n' "$caller" >&2
        return 1
    fi

    lines_before=$(wc -l < "$_SVHS_CAST")
    tmux -L "$_SVHS_TMUX_SOCKET" refresh-client -t "$client"

    # measuring the cast before the repaint reaches it would truncate the
    # repaint away again, so wait for the file to grow instead of guessing;
    # a line appears only once the event behind it is written whole
    deadline=$((SECONDS + _SVHS_WRITE_TIMEOUT))
    until [[ $(wc -l < "$_SVHS_CAST") -gt $lines_before ]]; do
        if ((SECONDS >= deadline)); then
            printf '%s: timeout waiting for the recorder to write\n' \
                "$caller" >&2
            return 1
        fi
        sleep "$_SVHS_WRITE_POLL_INTERVAL"
    done
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


_svhs_svg_font_list() {
    #
    # Print a comma-separated family list as CSS family names, one quoted
    # entry each. Unquoted CSS idents cannot start with a digit, and a single
    # invalid entry drops the whole stack ('0xProto Nerd Font', '3270 Nerd
    # Font').
    #
    # Parameters:
    #   $1 - families - comma-separated family names.
    #
    # Example:
    #   list=$(_svhs_svg_font_list 'Noto Color Emoji,Twemoji')
    #
    local families="$1"

    # the spaces around a separator belong to neither name, so they are cut
    # rather than quoted into one
    printf "'%s'" "$(printf '%s' "$families" | sed "s/^ *//; s/ *\$//; s/ *, */','/g")"
}


_svhs_svg_font_family() {
    #
    # Print the font-family list for the SVG: the configured text font, the
    # built-in text and symbol fallbacks, the emoji chain - the configured one
    # when SetEmojiFontFamily was called - and the generic monospace last.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   chain=$(_svhs_svg_font_family)
    #
    local chain=''

    [[ -n $_SVHS_FONT_FAMILY ]] && chain="$(_svhs_svg_font_list "$_SVHS_FONT_FAMILY"),"
    chain+="$_SVHS_SVG_FONT_FALLBACKS,"

    if [[ -n $_SVHS_EMOJI_FONT_FAMILY ]]; then
        chain+="$(_svhs_svg_font_list "$_SVHS_EMOJI_FONT_FAMILY"),"
    else
        chain+="$_SVHS_SVG_EMOJI_FALLBACKS,"
    fi

    printf '%smonospace' "$chain"
}


_svhs_warn() {
    #
    # Print a non-blocking warning in yellow unless quiet mode is enabled.
    #
    # Parameters:
    #   $1 - message - warning text without the informational prefix.
    #
    # Example:
    #   _svhs_warn 'SetShell: fish is not installed, falling back to bash'
    #
    local message="$1"

    [[ $_SVHS_QUIET == 1 ]] && return 0

    printf '%s::: %s%s\n' "$_SVHS_WARNING_COLOR" "$message" "$_SVHS_COLOR_RESET"
}


_svhs_report_skipped() {
    #
    # Report a setting the renderer of one output has no equivalent for. A
    # single line keeps the recording alive: the other outputs still carry it.
    #
    # Parameters:
    #   $1 - setter - public setter name whose value was ignored.
    #   $2 - output - output path it was ignored for.
    #   $3 - renderer - what does not support it.
    #
    # Example:
    #   _svhs_report_skipped 'SetEngine' 'demo.svg' 'SVG output'
    #
    local setter="$1"
    local output="$2"
    local renderer="$3"

    _svhs_warn "$setter: skipped for $output (not supported by $renderer)"
}


_svhs_report_raster_skips() {
    #
    # Report settings GIF and WebP output have no equivalent for.
    #
    # Parameters:
    #   $1 - output - GIF or WebP path that was rendered.
    #
    # Example:
    #   _svhs_report_raster_skips 'demo.webp'
    #
    local output="$1"
    local format='GIF output'

    [[ $output == *.webp ]] && format='WebP output'

    # agg draws no padding or window bar, and always draws the cursor, so
    # only a value that would have shown is worth a line
    ((_SVHS_PADDING > 0)) &&
        _svhs_report_skipped 'SetPadding' "$output" "$format"
    ((${_SVHS_PADDING_X:-0} > 0)) &&
        _svhs_report_skipped 'SetPaddingX' "$output" "$format"
    ((${_SVHS_PADDING_Y:-0} > 0)) &&
        _svhs_report_skipped 'SetPaddingY' "$output" "$format"
    [[ $_SVHS_WINDOW_BAR == 'on' ]] &&
        _svhs_report_skipped 'SetWindowBar' "$output" "$format"
    [[ $_SVHS_CURSOR == 'off' ]] &&
        _svhs_report_skipped 'SetCursor' "$output" "$format"
    return 0
}


_svhs_report_svg_skips() {
    #
    # Report the settings SVG output has no equivalent for.
    #
    # Parameters:
    #   $1 - output - SVG path that was rendered.
    #
    # Example:
    #   _svhs_report_svg_skips 'demo.svg'
    #
    local output="$1"

    [[ $_SVHS_LAST_FRAME_DURATION_SET == 1 ]] &&
        _svhs_report_skipped 'SetLastFrameDuration' "$output" 'SVG output'
    # only 'on' is worth a line: 'off' is what an SVG draws anyway
    [[ $_SVHS_BOLD_IS_BRIGHT == 'on' ]] &&
        _svhs_report_skipped 'SetBoldIsBright' "$output" 'SVG output'
    [[ $_SVHS_ENGINE_SET == 1 ]] &&
        _svhs_report_skipped 'SetEngine' "$output" 'SVG output'
    # an SVG names fonts instead of loading them, so a directory means nothing
    [[ -n ${_SVHS_FONT_DIRS[*]-} ]] &&
        _svhs_report_skipped 'SetFontDir' "$output" 'SVG output'
    [[ $_SVHS_OPTIMIZE == 'on' ]] &&
        _svhs_report_skipped 'SetOptimize' "$output" 'SVG output'
    return 0
}


_svhs_grid_width() {
    #
    # Compute the width in pixels a cell grid renders to, assuming the nominal
    # monospace advance. That is what asg draws; agg takes the advance from
    # the primary font, so there the result is only an estimate.
    #
    # Parameters:
    #   $1 - cells - cells across, including the renderer's own padding.
    #   $2 - extra - pixels added left and right together.
    #
    # Example:
    #   width=$(_svhs_grid_width 46 0)
    #
    local cells="$1"
    local extra="$2"

    # bash has no floating-point arithmetic, and the advance is a fraction
    awk -v cells="$cells" -v extra="$extra" \
        -v advance="$_SVHS_CELL_ADVANCE"    \
        -v font_size="$_SVHS_FONT_SIZE"     \
        'BEGIN { printf "%d", int(cells * advance * font_size + extra + 0.5) }'
}


_svhs_grid_height() {
    #
    # Compute the height in pixels a cell grid renders to. Both renderers take
    # a row's height from the line height alone, so this is exact.
    #
    # Parameters:
    #   $1 - cells - cells down, including the renderer's own padding.
    #   $2 - extra - pixels added above and below together.
    #
    # Example:
    #   height=$(_svhs_grid_height 5 0)
    #
    local cells="$1"
    local extra="$2"

    # bash has no floating-point arithmetic, and the line height is a fraction
    awk -v cells="$cells" -v extra="$extra"    \
        -v line_height="$_SVHS_LINE_HEIGHT"    \
        -v font_size="$_SVHS_FONT_SIZE"        \
        'BEGIN { printf "%d", int(cells * line_height * font_size + extra + 0.5) }'
}


_svhs_gif_width() {
    #
    # Measure the width agg gives this recording's GIF, by rendering a
    # throwaway single-row cast of the configured width and reading the size
    # back out of its header. agg sizes a cell by the face the system resolves
    # the font family to - a semi-extended or condensed one renders a tenth
    # wider or narrower than nominal - which no setting can predict, while a
    # single row keeps the probe at a few tens of milliseconds.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   width=$(_svhs_gif_width) || width=$(_svhs_grid_width 46 0)
    #
    local probe_cast
    local probe_gif
    local low
    local high

    probe_cast=$(mktemp) || return 1
    probe_gif="$probe_cast.gif"

    # agg rejects a cast without output events, so the probe prints one cell
    printf '{"version":3,"term":{"cols":%s,"rows":1},"timestamp":0}\n[0.0,"o","x"]\n' \
        "$_SVHS_COLS" > "$probe_cast"

    # the line height would only change the height, which is not read back,
    # but the engine picks its own faces and must match the real render
    if ! agg ${_SVHS_AGG_FONT_ARGS[@]+"${_SVHS_AGG_FONT_ARGS[@]}"} \
             --font-size "$_SVHS_FONT_SIZE"                        \
             --renderer "$_SVHS_ENGINE"                            \
             "$probe_cast" "$probe_gif" > /dev/null 2>&1; then
        rm -f -- "$probe_cast" "$probe_gif"
        return 1
    fi

    # a GIF stores its width as two little-endian bytes at offset 6
    read -r low high < <(od -An -tu1 -j6 -N2 "$probe_gif")
    rm -f -- "$probe_cast" "$probe_gif"

    printf '%d' "$((low + high * 256))"
}


_svhs_report_geometry() {
    #
    # Report the recorded grid and the size every requested renderer turns it
    # into, so a mistyped SetCols or SetFontSize shows up before the recording
    # runs rather than in the finished file.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _svhs_report_geometry
    #
    local grid="$_SVHS_COLS cols x $_SVHS_ROWS rows x ${_SVHS_FONT_SIZE}px font"
    local output
    local gif=0
    local webp=0
    local svg=0
    local padding_x="${_SVHS_PADDING_X:-$_SVHS_PADDING}"
    local padding_y="${_SVHS_PADDING_Y:-$_SVHS_PADDING}"
    local window_width=0
    local window_height=0
    local width
    local estimated=''

    for output in "${_SVHS_OUTPUTS[@]}"; do
        case "$output" in
            *.gif) gif=1 ;;
            *.webp) webp=1 ;;
            *.svg) svg=1 ;;
        esac
    done

    # a cast and a text export commit to no pixels, leaving only the grid
    if [[ $gif == 0 && $webp == 0 && $svg == 0 ]]; then
        printf '::: %s\n' "$grid"
        return 0
    fi

    # agg pads a GIF by one cell left and right and by half a row above and
    # below; a failed probe leaves the nominal advance, marked as a guess
    if [[ $gif == 1 || $webp == 1 ]]; then
        if ! width=$(_svhs_gif_width); then
            width=$(_svhs_grid_width "$((_SVHS_COLS + 2))" 0)
            estimated='~'
        fi
        if [[ $gif == 1 ]]; then
            printf '::: GIF: %s -> %s%s x %s px\n' "$grid" "$estimated" \
                "$width" "$(_svhs_grid_height "$((_SVHS_ROWS + 1))" 0)"
        fi
        if [[ $webp == 1 ]]; then
            printf '::: WebP: %s -> %s%s x %s px\n' "$grid" "$estimated" \
                "$width" "$(_svhs_grid_height "$((_SVHS_ROWS + 1))" 0)"
        fi
    fi

    if [[ $svg == 1 ]]; then
        if [[ $_SVHS_WINDOW_BAR == 'on' ]]; then
            window_width=$_SVHS_WINDOW_BAR_WIDTH
            window_height=$_SVHS_WINDOW_BAR_HEIGHT
        fi
        printf '::: SVG: %s -> %s x %s px\n' "$grid"                                \
            "$(_svhs_grid_width "$_SVHS_COLS" "$((2 * padding_x + window_width))")"  \
            "$(_svhs_grid_height "$_SVHS_ROWS" "$((2 * padding_y + window_height))")"
    fi
    return 0
}


_svhs_render_shared_gif() {
    #
    # Render one temporary GIF shared by all GIF and WebP outputs. Register
    # it in cleanup state before rendering so errors cannot leak it.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _svhs_render_shared_gif || return 1
    #
    local quiet_args=()
    local loop_args=()
    local bold_args=()

    [[ -n $_SVHS_TEMP_GIF ]] && return 0
    _SVHS_TEMP_GIF=$(mktemp) || return 1

    [[ $_SVHS_QUIET == 1 ]] && quiet_args=(-q)
    [[ $_SVHS_LOOP == 'off' ]] && loop_args=(--no-loop)
    [[ $_SVHS_BOLD_IS_BRIGHT == 'on' ]] && bold_args=(--bold-is-bright)

    # bash 3.2 rejects an empty array under set -u; expand only set arguments
    agg ${_SVHS_AGG_FONT_ARGS[@]+"${_SVHS_AGG_FONT_ARGS[@]}"} \
        ${quiet_args[@]+"${quiet_args[@]}"}                   \
        ${loop_args[@]+"${loop_args[@]}"}                     \
        ${bold_args[@]+"${bold_args[@]}"}                     \
        --font-size "$_SVHS_FONT_SIZE"                        \
        --line-height "$_SVHS_LINE_HEIGHT"                    \
        --theme "$_SVHS_THEME"                                \
        --speed "$_SVHS_PLAYBACK_SPEED"                       \
        --fps-cap "$_SVHS_FRAMERATE"                          \
        --idle-time-limit "$_SVHS_IDLE_TIME_LIMIT"            \
        --last-frame-duration "$_SVHS_LAST_FRAME_DURATION"    \
        --renderer "$_SVHS_ENGINE"                            \
        "$_SVHS_CAST" "$_SVHS_TEMP_GIF" || return 1
}


_svhs_render_raster() {
    #
    # Copy the shared GIF or convert it to lossless animated WebP, then report
    # the settings that format drops. Optimize a requested GIF in place and a
    # WebP through the encoder, leaving the shared source unchanged.
    #
    # Parameters:
    #   $1 - output - GIF or WebP path to write.
    #
    # Example:
    #   _svhs_render_raster 'demo.webp' || return 1
    #
    local output="$1"

    _svhs_render_shared_gif || return 1

    case "$output" in
        *.gif)
            # Redirection gives the output normal permissions, not mktemp's 0600
            cat -- "$_SVHS_TEMP_GIF" > "$output" || return 1
            _svhs_optimize_gif "$output" || return 1
            ;;
        *.webp)
            _svhs_encode_webp "$output" || return 1
            ;;
    esac

    _svhs_report_raster_skips "$output"
}


_svhs_optimize_gif() {
    #
    # Rewrite a rendered GIF through a lossless gifsicle pass. gifsicle is an
    # optional dependency: without it the GIF stays as the renderer wrote it,
    # which is worth a line but not a failed recording.
    #
    # Parameters:
    #   $1 - output - GIF path to optimize in place.
    #
    # Example:
    #   _svhs_optimize_gif 'demo.gif' || return 1
    #
    local output="$1"

    [[ $_SVHS_OPTIMIZE == 'off' ]] && return 0

    if ! command -v gifsicle > /dev/null 2>&1; then
        _svhs_warn "SetOptimize: gifsicle is not installed, $output left unoptimized"
        return 0
    fi

    # -w drops gifsicle's advisory warnings, such as the too-many-colors one a
    # fully antialiased render draws; a read error still prints and fails here
    gifsicle --batch -O3 -w "$output" || return 1
}


_svhs_encode_webp() {
    #
    # Encode the shared GIF as a lossless animated WebP, keeping a live line
    # up while the encoder runs.
    #
    # Parameters:
    #   $1 - output - WebP path to write.
    #
    # Example:
    #   _svhs_encode_webp 'demo.webp' || return 1
    #
    local output="$1"
    local loop=0
    local progress='/dev/null'
    local effort_args=()

    [[ $_SVHS_LOOP == 'off' ]] && loop=1

    # a lossless WebP costs minutes on a long recording, so a live line is the
    # only sign it is still working; quiet mode drops the stream at ffmpeg
    # rather than closing the pipe under it
    [[ $_SVHS_QUIET == 0 ]] && progress='pipe:1'

    # libwebp_anim guesses the last delay from preceding timestamps. Feed
    # GIF's 10ms grid to preserve every delay, including the final hold; the
    # encoder merges identical frames back into long holds. BGRA avoids chroma
    # loss, and no preset is used: even "text" overrides -lossless. The
    # encoding stays lossless either way: -compression_level is libwebp's
    # method and -quality its search effort, so SetOptimize only trades render
    # time for bytes.
    effort_args=(-compression_level 4 -quality 75)
    [[ $_SVHS_OPTIMIZE == 'on' ]] &&
        effort_args=(-compression_level 6 -quality 100)

    # pipefail makes a failed encode the status of the whole pipeline; the
    # reporter reads stdout, leaving ffmpeg's own errors on stderr
    ffmpeg -hide_banner -loglevel error -nostdin -y \
        -progress "$progress"                       \
        -ignore_loop 1 -min_delay 0                 \
        -i "$_SVHS_TEMP_GIF"                        \
        -vf fps=100                                 \
        -c:v libwebp_anim -lossless 1 -pix_fmt bgra \
        ${effort_args[@]+"${effort_args[@]}"}       \
        -loop "$loop"                               \
        "file:$output" |
        _svhs_report_encode_progress "$output" || return 1
}


_svhs_report_encode_progress() {
    #
    # Rewrite one line in place while an encode runs, and leave its last state
    # on screen once it ends. libwebp_anim holds every frame until it writes
    # the file, so ffmpeg reports no position to show - its -progress blocks
    # on stdin serve only as a heartbeat, one every half second. An empty
    # stream - quiet mode - prints nothing.
    #
    # Parameters:
    #   $1 - output - path being encoded, named in the message.
    #
    # Example:
    #   ffmpeg -progress pipe:1 … | _svhs_report_encode_progress 'demo.webp'
    #
    local output="$1"
    local key
    local value

    # SECONDS counts from the assignment, in the subshell the pipe puts this
    # reporter in; ffmpeg closes every block with progress=continue - or, for
    # the last one, progress=end
    SECONDS=0
    while IFS='=' read -r key value; do
        [[ $key == 'progress' ]] || continue
        printf '%s::: Encoding %s: %ss' "$_SVHS_ERASE_LINE" "$output" "$SECONDS"
        [[ $value == 'end' ]] && printf '\n'
    done

    return 0
}


_svhs_apply_highlight_style() {
    #
    # Apply the selection style Highlight sweeps with, and switch copy mode's
    # search styling off: Highlight searches only to put the cursor on the
    # match, and a painted match would give the whole text away before the
    # sweep reaches it.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _svhs_apply_highlight_style || return 1
    #
    local option

    for option in 'copy-mode-match-style' 'copy-mode-current-match-style'; do
        tmux -L "$_SVHS_TMUX_SOCKET" set -g "$option" 'default' || return 1
    done

    [[ -z $_SVHS_HIGHLIGHT_STYLE ]] && return 0

    tmux -L "$_SVHS_TMUX_SOCKET" set -g mode-style "$_SVHS_HIGHLIGHT_STYLE" || {
        printf 'Start: tmux rejected the SetHighlightColors style: %s\n' \
            "$_SVHS_HIGHLIGHT_STYLE" >&2
        return 1
    }
}


_svhs_sweep_selection() {
    #
    # Select the on-screen text one cell at a time, and leave the selection
    # up. Copy mode paints the selection in mode-style, which is what makes
    # the sweep visible; -H hides its position indicator, and the search is
    # only how the cursor reaches the first cell of the match.
    #
    # Parameters:
    #   $1 - text - text to select, known to be on the visible pane.
    #   $2 - delay - seconds to pause after each swept cell.
    #
    # Example:
    #   _svhs_sweep_selection 'Welcome to s-vhs' 0.03
    #
    local text="$1"
    local delay="$2"
    local cell

    tmux -L "$_SVHS_TMUX_SOCKET" copy-mode -H -t "$_SVHS_SESSION"
    _svhs_send -X search-backward-text "$text"
    _svhs_send -X begin-selection

    # The selection ends before the cursor, so the last cell needs a step of
    # its own; every character on screen is one cell wide
    for ((cell = 0; cell < ${#text}; cell++)); do
        _svhs_send -X cursor-right
        sleep "$delay"
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


# Dispatch subcommands only when this file is executed, never when sourced:
#   run directly  BASH_SOURCE[0] equals $0
#   piped         BASH_SOURCE is unset (`curl … | bash -s -- new …`)
#   sourced       $0 belongs to the caller
# $1 alone cannot tell - a sourced library inherits the caller's positional
# parameters. `new` and `watch` are deliberately the only subcommands:
# s-vhs is a library, not a CLI.
if [[ -z ${BASH_SOURCE[0]-} || ${BASH_SOURCE[0]} == "$0" ]]; then
    case "${1-}" in
        new)
            _svhs_new "${2-}" || exit 1
            ;;
        watch)
            # bash 3.2 (stock macOS) rejects $2 as unbound under set -u, so an
            # omitted session is passed as no argument rather than as ''
            svhs_watch ${2+"$2"} || exit 1
            ;;
        *)
            printf 'usage: s-vhs.sh new [path]\n' >&2
            printf '       s-vhs.sh watch [session]\n' >&2
            exit 1
            ;;
    esac
    exit 0
fi

# Any exit of the sourcing script - including a set -e failure mid-recording -
# tears down the tmux session and recorder, then runs the Finally commands.
# A no-op before Start with nothing registered
trap svhs_cleanup EXIT
