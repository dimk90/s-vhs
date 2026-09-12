#!/bin/bash
#
# Reproduce the measurements in doc/ENCODING.md.
#
# Renders the stress clip when it is missing, encodes every configuration the
# comparison covers, prints one table per section of that document and writes
# the sample bundle used for the manual browser and player pass. Everything
# lands in the work directory; the repository is only read.
#
# Quality is PSNR and SSIM in RGB against the decoded GIF frames, aligned by
# frame index - the GIF is the encoder's input, so it is the only honest
# reference. A PSNR of `inf` means bit-exact.
#
# Usage: scripts/encoding-bench.sh [work-dir]
#

set -uo pipefail

readonly _BENCH_DEFAULT_WORK_DIR='/tmp/s-vhs-encoding-bench'

# one decode pass over the GIF, keeping every delay and its variable timing
_BENCH_DECODE=(-ignore_loop 1 -min_delay 0)

# 4:2:0 needs even dimensions; examples/logo.gif is 899px wide
readonly _BENCH_PAD='pad=ceil(iw/2)*2:ceil(ih/2)*2:0:0'

# the chosen colour pipeline: BT.601, limited range, tagged to match
readonly _BENCH_COLOR='scale=out_color_matrix=bt470bg:out_range=tv:flags=full_chroma_int+accurate_rnd,format=yuv420p,setparams=colorspace=smpte170m:color_primaries=bt709:color_trc=bt709:range=tv'

# how a player that ignores the tags reads the file
readonly _BENCH_AS_709='setparams=colorspace=bt709:range=tv,'
readonly _BENCH_AS_601='setparams=colorspace=smpte170m:range=tv,'


## Main


main() {
    local work_dir="${1:-$_BENCH_DEFAULT_WORK_DIR}"
    local repo_dir stress logo

    repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
    stress="$work_dir/stress.gif"
    logo="$repo_dir/examples/logo.gif"

    _bench_require_tools || exit 1
    mkdir -p "$work_dir" || exit 1
    _bench_render_stress_clip "$repo_dir" "$work_dir" || exit 1

    _bench_report_inputs "$stress" "$logo"
    _bench_report_codec_matrix "$stress" "$work_dir"
    _bench_report_codec_matrix "$logo" "$work_dir"
    _bench_report_colour_grid "$stress" "$work_dir"
    _bench_report_frame_policy "$stress" "$work_dir"
    _bench_report_quality_ladder "$stress" "$work_dir"
    _bench_report_quality_ladder "$logo" "$work_dir"
    _bench_write_sample_bundle "$stress" "$work_dir"
}


## Internal
#
# Bash cannot hide these from a caller; the `_bench_` prefix only marks them
# private and keeps them out of the way of a sourcing shell.


_bench_require_tools() {
    #
    # Report every missing tool at once instead of failing one table in.
    #
    # Parameters:
    #   None.
    #
    # Example:
    #   _bench_require_tools || exit 1
    #
    local tool
    local missing=()

    for tool in ffmpeg ffprobe; do
        command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
    done

    [[ ${#missing[@]} -eq 0 ]] && return 0
    printf 'encoding-bench: not installed: %s\n' "${missing[*]}" >&2
    return 1
}


_bench_render_stress_clip() {
    #
    # Record the stress clip unless the work directory already holds it;
    # rendering it takes a minute, every later run reuses the GIF.
    #
    # Parameters:
    #   $1 - repo_dir - repository root.
    #   $2 - work_dir - directory the GIF is written to.
    #
    # Example:
    #   _bench_render_stress_clip "$repo_dir" "$work_dir" || exit 1
    #
    local repo_dir="$1"
    local work_dir="$2"

    [[ -s $work_dir/stress.gif ]] && return 0

    printf '::: Recording the stress clip into %s\n' "$work_dir"
    "$repo_dir/scripts/stress.rec.sh" "$work_dir" || return 1
}


_bench_report_inputs() {
    #
    # Print the input table: what each GIF costs and what it contains.
    #
    # Parameters:
    #   $@ - inputs - GIF paths.
    #
    # Example:
    #   _bench_report_inputs "$stress" "$logo"
    #
    local input

    printf '\n=== Inputs ===\n'
    printf '%-28s %11s %9s %7s %9s\n' 'input' 'dimensions' 'bytes' 'frames' 'duration'
    for input in "$@"; do
        printf '%-28s %11s %9s %7s %9s\n' "$(basename "$input")" \
            "$(_bench_dimensions "$input" | tr ':' 'x')" \
            "$(_bench_bytes "$input")" \
            "$(ffprobe -v error -select_streams v:0 -count_frames \
                -show_entries stream=nb_read_frames -of csv=p=0 \
                "${_BENCH_DECODE[@]}" "$input")" \
            "$(ffprobe -v error -show_entries format=duration -of csv=p=0 \
                "${_BENCH_DECODE[@]}" "$input")"
    done
}


_bench_report_codec_matrix() {
    #
    # Print the codec table: H.264 quality and preset sweeps, 4:4:4, the
    # lossless options, the frame policies and the HEVC/AV1 probe.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - work_dir - directory the encodes are written to.
    #
    # Example:
    #   _bench_report_codec_matrix "$stress" "$work_dir"
    #
    local input="$1"
    local out_dir
    local crf preset

    out_dir="$2/codec-$(basename "$input" .gif)"
    mkdir -p "$out_dir" || return 1
    printf '\n=== Codec matrix: %s (GIF %s B) ===\n' \
        "$(basename "$input")" "$(_bench_bytes "$input")"
    _bench_codec_header

    for crf in 14 18 20 23 28; do
        _bench_codec_row "$input" "$out_dir" "x264-420-crf$crf-medium" \
            -vf "$_BENCH_PAD" -c:v libx264 -pix_fmt yuv420p -crf "$crf" -preset medium
    done
    for preset in ultrafast fast slow veryslow; do
        _bench_codec_row "$input" "$out_dir" "x264-420-crf18-$preset" \
            -vf "$_BENCH_PAD" -c:v libx264 -pix_fmt yuv420p -crf 18 -preset "$preset"
    done
    for crf in 14 18 23; do
        _bench_codec_row "$input" "$out_dir" "x264-444-crf$crf-medium" \
            -c:v libx264 -pix_fmt yuv444p -crf "$crf" -preset medium
    done

    _bench_codec_row "$input" "$out_dir" 'x264-444-lossless' \
        -c:v libx264 -pix_fmt yuv444p -qp 0 -preset medium
    _bench_codec_row "$input" "$out_dir" 'x264rgb-lossless' \
        -c:v libx264rgb -pix_fmt rgb24 -qp 0 -preset medium
    _bench_codec_row "$input" "$out_dir" 'x264rgb-lossless-veryslow' \
        -c:v libx264rgb -pix_fmt rgb24 -qp 0 -preset veryslow
    _bench_codec_row "$input" "$out_dir" 'x264-420-crf18-animation' \
        -vf "$_BENCH_PAD" -c:v libx264 -pix_fmt yuv420p -crf 18 -preset medium -tune animation
    _bench_codec_row "$input" "$out_dir" 'x264-420-crf18-stillimage' \
        -vf "$_BENCH_PAD" -c:v libx264 -pix_fmt yuv420p -crf 18 -preset medium -tune stillimage
    _bench_codec_row "$input" "$out_dir" 'x264-420-crf18-nobframe' \
        -vf "$_BENCH_PAD" -c:v libx264 -pix_fmt yuv420p -crf 18 -preset medium -bf 0
    _bench_codec_row "$input" "$out_dir" 'x265-420-crf20' \
        -vf "$_BENCH_PAD" -c:v libx265 -pix_fmt yuv420p -crf 20 -preset medium -tag:v hvc1
    _bench_codec_row "$input" "$out_dir" 'x265-444-crf20' \
        -c:v libx265 -pix_fmt yuv444p -crf 20 -preset medium -tag:v hvc1
    _bench_codec_row "$input" "$out_dir" 'svtav1-420-crf30' \
        -vf "$_BENCH_PAD" -c:v libsvtav1 -pix_fmt yuv420p -crf 30 -preset 6
    _bench_codec_row "$input" "$out_dir" 'svtav1-420-crf20' \
        -vf "$_BENCH_PAD" -c:v libsvtav1 -pix_fmt yuv420p -crf 20 -preset 6
}


_bench_report_colour_grid() {
    #
    # Print the colour table: every matrix and range combination, each read
    # back the way its tags ask for and the way a player ignoring them would.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - work_dir - directory the encodes are written to.
    #
    # Example:
    #   _bench_report_colour_grid "$stress" "$work_dir"
    #
    local input="$1"
    local out_dir="$2/colour"

    mkdir -p "$out_dir" || return 1
    printf '\n=== Colour: matrix x range, crf 18 (%s) ===\n' "$(basename "$input")"
    printf '%-22s %9s %11s %11s %11s  %s\n' \
        'config' 'bytes' 'PSNR/tags' 'PSNR/709tv' 'PSNR/601tv' 'stream tags'

    _bench_colour_row "$input" "$out_dir" 'default-untagged' yuv420p '' ''
    _bench_colour_row "$input" "$out_dir" '420-601-tv' yuv420p bt470bg tv
    _bench_colour_row "$input" "$out_dir" '420-601-pc' yuv420p bt470bg full
    _bench_colour_row "$input" "$out_dir" '420-709-tv' yuv420p bt709 tv
    _bench_colour_row "$input" "$out_dir" '420-709-pc' yuv420p bt709 full
    _bench_colour_row "$input" "$out_dir" '444-601-pc' yuv444p bt470bg full
    _bench_colour_row "$input" "$out_dir" '444-709-pc' yuv444p bt709 full
}


_bench_report_frame_policy() {
    #
    # Print the keyframe table: what forcing keyframes costs on content that
    # is mostly unchanged pixels.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - work_dir - directory the encodes are written to.
    #
    # Example:
    #   _bench_report_frame_policy "$stress" "$work_dir"
    #
    local input="$1"
    local out_dir="$2/frame-policy"
    local baseline gop seconds

    mkdir -p "$out_dir" || return 1
    printf '\n=== Frame policy: 4:2:0 crf 18 (%s) ===\n' "$(basename "$input")"
    printf '%-26s %10s %11s %10s\n' 'policy' 'bytes' 'vs default' 'keyframes'

    baseline=$(_bench_frame_policy_encode "$input" "$out_dir/default.mp4")
    _bench_frame_policy_row 'default (keyint+scenecut)' "$out_dir/default.mp4" "$baseline"
    for gop in 1 15 30 60 120; do
        _bench_frame_policy_encode "$input" "$out_dir/g$gop.mp4" -g "$gop" >/dev/null
        _bench_frame_policy_row "-g $gop" "$out_dir/g$gop.mp4" "$baseline"
    done
    for seconds in 5 10; do
        _bench_frame_policy_encode "$input" "$out_dir/t$seconds.mp4" \
            -force_key_frames "expr:gte(t,n_forced*$seconds)" >/dev/null
        _bench_frame_policy_row "keyframe every ${seconds}s" \
            "$out_dir/t$seconds.mp4" "$baseline"
    done
}


_bench_report_quality_ladder() {
    #
    # Print the CRF table for the chosen pipeline, measured both against the
    # GIF and against a lossless 4:2:0 round trip. The second column is the
    # one CRF controls: the first is capped by chroma subsampling.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - work_dir - directory the encodes are written to.
    #
    # Example:
    #   _bench_report_quality_ladder "$stress" "$work_dir"
    #
    local input="$1"
    local out_dir
    local reference
    local encoded bytes crf

    out_dir="$2/ladder-$(basename "$input" .gif)"
    reference="$out_dir/lossless-420.mp4"
    mkdir -p "$out_dir" || return 1
    _bench_encode "$input" "$reference" -vf "$_BENCH_PAD,$_BENCH_COLOR" \
        -c:v libx264 -qp 0 -preset medium >/dev/null || return 1

    printf '\n=== Quality ladder: 4:2:0, BT.601 limited (%s, GIF %s B) ===\n' \
        "$(basename "$input")" "$(_bench_bytes "$input")"
    printf 'lossless 4:2:0 round trip: %s B (%s of the GIF)\n' \
        "$(_bench_bytes "$reference")" \
        "$(_bench_percent "$(_bench_bytes "$reference")" "$(_bench_bytes "$input")")"
    printf '%-8s %10s %8s %13s %15s\n' \
        'crf' 'bytes' 'vs GIF' 'PSNR vs GIF' 'PSNR vs 4:2:0'

    for crf in 14 16 18 20 23; do
        encoded="$out_dir/crf$crf.mp4"
        _bench_encode "$input" "$encoded" -vf "$_BENCH_PAD,$_BENCH_COLOR" \
            -c:v libx264 -crf "$crf" -preset medium -profile:v high >/dev/null || continue
        bytes=$(_bench_bytes "$encoded")
        printf '%-8s %10s %8s %13s %15s\n' "crf $crf" "$bytes" \
            "$(_bench_percent "$bytes" "$(_bench_bytes "$input")")" \
            "$(_bench_psnr "$input" "$encoded" '')" \
            "$(_bench_psnr_between "$reference" "$encoded")"
    done
}


_bench_write_sample_bundle() {
    #
    # Write the files the manual playback pass needs: the candidate contract,
    # the alternatives it was chosen over, and a page that plays them all.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - work_dir - directory holding the encodes.
    #
    # Example:
    #   _bench_write_sample_bundle "$stress" "$work_dir"
    #
    local input="$1"
    local out_dir="$2/playback"

    mkdir -p "$out_dir" || return 1
    cp "$input" "$out_dir/source.gif" || return 1

    _bench_encode "$input" "$out_dir/a-420-bt601-tv.mp4" \
        -vf "$_BENCH_PAD,$_BENCH_COLOR" -c:v libx264 -crf 18 -preset medium \
        -profile:v high >/dev/null
    _bench_encode "$input" "$out_dir/b-420-bt709-tv.mp4" \
        -vf "$_BENCH_PAD,scale=out_color_matrix=bt709:out_range=tv,format=yuv420p" \
        -c:v libx264 -crf 18 -preset medium -colorspace bt709 -color_range tv >/dev/null
    _bench_encode "$input" "$out_dir/c-420-bt601-full.mp4" \
        -vf "$_BENCH_PAD,scale=out_color_matrix=bt470bg:out_range=full,format=yuv420p,setparams=colorspace=smpte170m:range=pc" \
        -c:v libx264 -crf 18 -preset medium >/dev/null
    _bench_encode "$input" "$out_dir/d-444-bt601-full.mp4" \
        -c:v libx264 -pix_fmt yuv444p -crf 18 -preset medium >/dev/null
    _bench_encode "$input" "$out_dir/e-rgb-lossless.mp4" \
        -c:v libx264rgb -pix_fmt rgb24 -qp 0 -preset medium >/dev/null

    cat >"$out_dir/index.html" <<'HTML'
<!doctype html><meta charset=utf-8><title>s-vhs MP4 candidates</title>
<style>body{font:14px system-ui;background:#222;color:#eee;max-width:1300px;margin:2em auto}
figure{margin:0 0 2em}video,img{width:100%;border:1px solid #555}</style>
<h1>s-vhs MP4 encoding candidates</h1>
<p>Each should look like the GIF at the bottom: no washed-out greys, no colour
shift, no blurred colour text edges. Note any that fail to play at all.</p>
<figure><figcaption>a - yuv420p, BT.601, limited range (the chosen contract)</figcaption><video src=a-420-bt601-tv.mp4 controls loop muted></video></figure>
<figure><figcaption>b - yuv420p, BT.709, limited range (conventional)</figcaption><video src=b-420-bt709-tv.mp4 controls loop muted></video></figure>
<figure><figcaption>c - yuv420p, BT.601, full range</figcaption><video src=c-420-bt601-full.mp4 controls loop muted></video></figure>
<figure><figcaption>d - yuv444p (High 4:4:4 Predictive; expected: Chrome only)</figcaption><video src=d-444-bt601-full.mp4 controls loop muted></video></figure>
<figure><figcaption>e - libx264rgb lossless (expected: plays nowhere)</figcaption><video src=e-rgb-lossless.mp4 controls loop muted></video></figure>
<figure><figcaption>source GIF</figcaption><img src=source.gif></figure>
HTML

    printf '\n::: Playback bundle: %s/index.html\n' "$out_dir"
}


_bench_codec_header() {
    printf '%-28s %9s %7s %8s %9s %9s %9s\n' \
        'config' 'bytes' 'vs GIF' 'time' 'PSNRavg' 'PSNRmin' 'SSIM'
}


_bench_codec_row() {
    #
    # Encode one configuration and print its size, encoding time and quality.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - out_dir - directory the encode is written to.
    #   $3 - name - configuration name, also the file name.
    #   $@ - options - ffmpeg options placed before the output.
    #
    # Example:
    #   _bench_codec_row "$gif" "$dir" 'x264-420-crf18' -c:v libx264 -crf 18
    #
    local input="$1"
    local out_dir="$2"
    local name="$3"
    shift 3
    local output="$out_dir/$name.mp4"
    local elapsed bytes quality

    elapsed=$(_bench_encode "$input" "$output" "$@") || {
        printf '%-28s %9s\n' "$name" 'FAILED'
        return 1
    }
    bytes=$(_bench_bytes "$output")
    quality=$(_bench_quality "$input" "$output")

    # the three quality fields are split on purpose
    # shellcheck disable=SC2086
    printf '%-28s %9s %7s %7ss %9s %9s %9s\n' "$name" "$bytes" \
        "$(_bench_percent "$bytes" "$(_bench_bytes "$input")")" "$elapsed" $quality
}


_bench_colour_row() {
    #
    # Encode one matrix/range combination and print how it reads back under
    # its own tags and under the two assumptions a player may make instead.
    # An empty matrix leaves ffmpeg to its own default, which tags nothing.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - out_dir - directory the encode is written to.
    #   $3 - name - configuration name, also the file name.
    #   $4 - pixel_format - yuv420p or yuv444p.
    #   $5 - matrix - bt470bg, bt709, or empty for the ffmpeg default.
    #   $6 - range - tv, full, or empty for the ffmpeg default.
    #
    # Example:
    #   _bench_colour_row "$gif" "$dir" '420-601-tv' yuv420p bt470bg tv
    #
    local input="$1"
    local out_dir="$2"
    local name="$3"
    local pixel_format="$4"
    local matrix="$5"
    local range="$6"
    local output="$out_dir/$name.mp4"
    local filters=''
    local tagged_range="$range"
    local tagged_matrix="$matrix"

    [[ $pixel_format == 'yuv420p' ]] && filters="$_BENCH_PAD,"
    [[ $tagged_range == 'full' ]] && tagged_range='pc'
    [[ $tagged_matrix == 'bt470bg' ]] && tagged_matrix='smpte170m'

    if [[ -n $matrix ]]; then
        filters="${filters}scale=out_color_matrix=$matrix:out_range=$range:flags=full_chroma_int+accurate_rnd,format=$pixel_format,setparams=colorspace=$tagged_matrix:color_primaries=bt709:color_trc=bt709:range=$tagged_range"
    else
        filters="${filters}format=$pixel_format"
    fi

    _bench_encode "$input" "$output" -vf "$filters" -c:v libx264 \
        -crf 18 -preset medium >/dev/null || {
        printf '%-22s %9s\n' "$name" 'FAILED'
        return 1
    }

    printf '%-22s %9s %11s %11s %11s  %s\n' "$name" "$(_bench_bytes "$output")" \
        "$(_bench_psnr "$input" "$output" '')" \
        "$(_bench_psnr "$input" "$output" "$_BENCH_AS_709")" \
        "$(_bench_psnr "$input" "$output" "$_BENCH_AS_601")" \
        "$(ffprobe -v error -select_streams v:0 \
            -show_entries stream=pix_fmt,color_range,color_space \
            -of csv=p=0 "$output")"
}


_bench_frame_policy_encode() {
    #
    # Encode the frame-policy baseline configuration with extra options, and
    # print the resulting size so the caller can use it as its baseline.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - output - MP4 path to write.
    #   $@ - options - extra ffmpeg options, such as -g.
    #
    # Example:
    #   baseline=$(_bench_frame_policy_encode "$gif" "$dir/default.mp4")
    #
    local input="$1"
    local output="$2"
    shift 2

    _bench_encode "$input" "$output" -vf "$_BENCH_PAD" -c:v libx264 \
        -pix_fmt yuv420p -crf 18 -preset medium "$@" >/dev/null || return 1
    _bench_bytes "$output"
}


_bench_frame_policy_row() {
    #
    # Print one keyframe-policy row against the default-GOP baseline.
    #
    # Parameters:
    #   $1 - name - policy name.
    #   $2 - encoded - MP4 to measure.
    #   $3 - baseline - byte count of the default-GOP encode.
    #
    # Example:
    #   _bench_frame_policy_row '-g 30' "$dir/g30.mp4" "$baseline"
    #
    local name="$1"
    local encoded="$2"
    local baseline="$3"
    local bytes

    bytes=$(_bench_bytes "$encoded")
    printf '%-26s %10s %11s %10s\n' "$name" "$bytes" \
        "$(_bench_percent "$bytes" "$baseline")" \
        "$(ffprobe -v error -select_streams v:0 -skip_frame nokey \
            -show_entries frame=pts_time -of csv=p=0 "$encoded" | grep -c .)"
}


_bench_encode() {
    #
    # Encode one GIF to MP4 and print the elapsed seconds. The GIF is decoded
    # once, its variable frame timing passed through untouched.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - output - MP4 path to write.
    #   $@ - options - ffmpeg options placed before the output.
    #
    # Example:
    #   elapsed=$(_bench_encode "$gif" "$out" -c:v libx264 -crf 18) || return 1
    #
    local input="$1"
    local output="$2"
    shift 2
    local elapsed

    # the `time` builtin is the portable stopwatch; ffmpeg's own noise is
    # dropped inside the compound so only the measurement reaches stderr
    TIMEFORMAT='%R'
    elapsed=$( { time ffmpeg -hide_banner -loglevel error -nostdin -y \
        "${_BENCH_DECODE[@]}" -i "$input" -fps_mode passthrough \
        "$@" -movflags +faststart "$output" >/dev/null 2>&1; } 2>&1 )

    [[ -s $output ]] || return 1
    awk -v seconds="$elapsed" 'BEGIN { printf "%.1f", seconds }'
}


_bench_quality() {
    #
    # Print the average PSNR, the worst-frame PSNR and the SSIM of an encode
    # against its source GIF, separated by spaces.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - encoded - MP4 to measure.
    #
    # Example:
    #   quality=$(_bench_quality "$gif" "$out")
    #
    local input="$1"
    local encoded="$2"
    local report

    report=$(_bench_compare "$input" "$encoded" '' psnr)
    printf '%s %s %s' \
        "$(printf '%s' "$report" | grep -o 'average:[^ ]*' | cut -d: -f2)" \
        "$(printf '%s' "$report" | grep -o ' min:[^ ]*' | cut -d: -f2)" \
        "$(_bench_compare "$input" "$encoded" '' ssim |
            grep -o 'All:[^ ]*' | head -1 | cut -d: -f2)"
}


_bench_psnr() {
    #
    # Print the average PSNR of an encode against its source GIF, optionally
    # decoded under a forced colour assumption.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - encoded - MP4 to measure.
    #   $3 - assumption - setparams filter and trailing comma, or empty to
    #        honour the file's own tags.
    #
    # Example:
    #   _bench_psnr "$gif" "$out" "$_BENCH_AS_709"
    #
    _bench_compare "$1" "$2" "$3" psnr | grep -o 'average:[^ ]*' | cut -d: -f2
}


_bench_psnr_between() {
    #
    # Print the average PSNR between two encodes of the same recording, which
    # isolates what the codec destroyed from what the colour conversion did.
    #
    # Parameters:
    #   $1 - reference - MP4 to measure against.
    #   $2 - encoded - MP4 to measure.
    #
    # Example:
    #   _bench_psnr_between "$lossless" "$crf18"
    #
    ffmpeg -hide_banner -nostdin -i "$1" -i "$2" \
        -lavfi "[0:v]format=rgb24,settb=1/25,setpts=N[a];[1:v]format=rgb24,settb=1/25,setpts=N[b];[a][b]psnr" \
        -f null - 2>&1 | grep -o 'average:[^ ]*' | cut -d: -f2
}


_bench_compare() {
    #
    # Run one comparison filter over the decoded GIF and an encode. Both are
    # compared in RGB and aligned by frame index, since the GIF carries
    # variable frame timing that no encode reproduces exactly; padding added
    # for 4:2:0 is cropped back off first.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - encoded - MP4 to measure.
    #   $3 - assumption - setparams filter and trailing comma, or empty.
    #   $4 - filter - psnr or ssim.
    #
    # Example:
    #   _bench_compare "$gif" "$out" '' psnr
    #
    local input="$1"
    local encoded="$2"
    local assumption="$3"
    local filter="$4"
    local dimensions

    dimensions=$(_bench_dimensions "$input")
    ffmpeg -hide_banner -nostdin "${_BENCH_DECODE[@]}" -i "$input" -i "$encoded" \
        -lavfi "[0:v]format=rgb24,settb=1/25,setpts=N[a];[1:v]${assumption}format=rgb24,crop=$dimensions:0:0,settb=1/25,setpts=N[b];[a][b]$filter" \
        -f null - 2>&1 | grep -o "$(printf '%s' "$filter" | tr '[:lower:]' '[:upper:]') .*"
}


_bench_dimensions() {
    ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
        -of csv=p=0 "$1" | tr ',' ':'
}


_bench_bytes() {
    wc -c <"$1" | tr -d ' '
}


_bench_percent() {
    #
    # Print one size as a percentage of another, rounded to whole percent.
    #
    # Parameters:
    #   $1 - value - measured byte count.
    #   $2 - total - byte count it is compared against.
    #
    # Example:
    #   _bench_percent "$bytes" "$gif_bytes"
    #
    awk -v value="$1" -v total="$2" 'BEGIN { printf "%.0f%%", value * 100 / total }'
}


main ${@+"$@"}
