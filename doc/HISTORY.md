# History

Code removed from `s-vhs.sh`, kept verbatim so it can be revived instead of
rewritten from scratch. One section per removed feature, newest last.

## GIF padding (removed pre-v0.1.0)

Padding was post-processing bolted onto the finished GIF: it re-encoded a file
`agg` had already encoded, pulled in a `magick`/`ffmpeg` dependency for a
cosmetic border, and — being a second lossy pass — worked against the "always
sharp output" selling point. It also had no place in the settings model, being
an argument to `render` rather than a setting.

Planned to return as `SetPadding` ([PLAN.md](PLAN.md), v0.4.0), ideally without
a re-encode.

Removed: the `PAD_COLOR` / `PAD_FALLBACK_COLOR` defaults, the optional `padding`
argument of `render`, and the `_pad_gif` internal.

### Defaults

```bash
# Set PAD_COLOR to override automatic detection from the GIF's top-left pixel.
# PAD_FALLBACK_COLOR is used when only ffmpeg is available.
: "${PAD_COLOR:=}"
: "${PAD_FALLBACK_COLOR:=#121314}"
```

### `render` hook

```bash
    # Parameters:
    #   $1 - padding - (optional) - uniform pixel padding to add to the GIF.
    #
    # Example:
    #   render "$PADDING"
    #
    local padding="${1-}"

    ...

    if [[ -n $padding ]]; then
        _pad_gif "$padding"
    fi
```

### `_pad_gif`

```bash
_pad_gif() {
    #
    # Add uniform pixel padding around the rendered GIF (like VHS's
    # Set Padding). Prefers magick, falls back to ffmpeg, and warns when
    # neither is installed.
    #
    # Parameters:
    #   $1 - pad - padding in pixels.
    #
    # Example:
    #   _pad_gif 40
    #
    local pad="$1"

    local pad_color="${PAD_COLOR:-}"

    printf '::: adding %spx padding\n' "$pad"

    if command -v magick &> /dev/null; then
        if [[ -z $pad_color ]]; then
            pad_color="#$(magick "${GIF}[0]" -format '%[hex:p{0,0}]' info:)"
        fi
        # Coalesce first: border on frame-diffed GIFs misplaces frames.
        magick "$GIF" -coalesce -bordercolor "$pad_color" -border "$pad" \
            -layers optimize "$GIF"
    elif command -v ffmpeg &> /dev/null; then
        local tmp="${GIF%.gif}-pad.gif"
        pad_color="${pad_color:-$PAD_FALLBACK_COLOR}"
        # Regenerate the palette, otherwise ffmpeg falls back to a dithered
        # generic 256-color palette.
        ffmpeg -loglevel error -y -i "$GIF" -filter_complex \
            "pad=iw+2*${pad}:ih+2*${pad}:${pad}:${pad}:${pad_color/\#/0x},split[a][b];[a]palettegen[p];[b][p]paletteuse" \
            "$tmp"
        mv -- "$tmp" "$GIF"
    else
        printf 'warning: neither magick nor ffmpeg found; skipping %spx padding\n' "$pad" >&2
    fi
}
```

Known caveat at removal time: the `magick` path re-optimizes the GIF and can
introduce artifacts.
