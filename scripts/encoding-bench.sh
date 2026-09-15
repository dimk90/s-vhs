#!/bin/bash
#
# Reproduce the measurements in doc/ENCODING.md.
#
# Renders the stress clip when it is missing, encodes every configuration the
# comparison covers, prints comparison tables and writes
# the sample bundle used for the manual browser and player pass. Everything
# lands in the work directory; the repository is only read.
#
# Quality is PSNR and SSIM in RGB against the decoded GIF frames, aligned by
# frame index. Timing is measured separately; a good pixel score cannot
# establish correct playback. Lossless RGB also gets a frame-hash check.
#
# Usage: scripts/encoding-bench.sh [--timing|--presets] [work-dir]
#
# --timing runs the timing tables alone and --presets the preset ladders;
# neither needs an encoder but libx264. --timing is how another ffmpeg build
# is checked, the version floor included:
#
#   PATH=/opt/ffmpeg-5.1/bin:$PATH scripts/encoding-bench.sh --timing work-dir
#

set -uo pipefail

readonly _BENCH_DEFAULT_WORK_DIR='/tmp/s-vhs-encoding-bench'

# one decode pass over the GIF, keeping every delay and its variable timing
_BENCH_DECODE=(-ignore_loop 1 -min_delay 0)

# 4:2:0 needs even dimensions; examples/logo.gif is 899px wide
readonly _BENCH_PAD='pad=ceil(iw/2)*2:ceil(ih/2)*2:0:0'

# treat the rendered GIF as sRGB; matrix/range conversion keeps its transfer.
# bt601 names the same matrix as bt470bg and smpte170m, and is the only one of
# the three swscale accepts before ffmpeg 8
readonly _BENCH_COLOR='scale=out_color_matrix=bt601:out_range=tv:flags=full_chroma_int+accurate_rnd,format=yuv420p,setparams=colorspace=smpte170m:color_primaries=bt709:color_trc=iec61966-2-1:range=tv'

# fix RGB reconstruction rather than silently using swscale's fast path
readonly _BENCH_RGB='scale=flags=full_chroma_int+accurate_rnd,format=rgb24'

# one tenth of a GIF tick; allow probe rounding, not a lost/shifted GIF frame
readonly _BENCH_TIMING_TOLERANCE='0.001'

# Reads reference and encoded PTS/duration CSV files. Prints indexed timing
# errors, the final sample duration/end, and a verdict including the container
# duration. With require_match=1, fails if any error exceeds tolerance.
# Literal awk: field references belong to awk, not the shell
# shellcheck disable=SC2016
readonly _BENCH_TIMING_COMPARE='
    NR == FNR { pts[FNR] = $1; duration[FNR] = $2; count = FNR; end = $1 + $2; next }
    {
        pts_error = $1 - pts[FNR]; if (pts_error < 0) pts_error = -pts_error
        duration_error = $2 - duration[FNR]; if (duration_error < 0) duration_error = -duration_error
        if (pts_error > max_pts) max_pts = pts_error
        if (duration_error > max_duration) max_duration = duration_error
        last = $2; encoded_end = $1 + $2
    }
    END {
        container_error = container - end; if (container_error < 0) container_error = -container_error
        matches = FNR == count && max_pts <= tolerance && max_duration <= tolerance && container_error <= tolerance
        if (FNR == count) printf "%9.3f %9.3f ", max_pts * 1000, max_duration * 1000
        else printf "%9s %9s ", "n/a", "n/a"
        verdict = FNR != count ? "RESAMPLED" : (matches ? "PASS" : "DIFF")
        printf "%8.3f %8.3f %8.3f %s", last, encoded_end, container, verdict
        if (require_match && !matches) exit 1
    }
'


## Main


main() {
    #
    # Run the measurements and stop at the first failed encode or validation.
    #
    # Parameters:
    #   $1 - --timing or --presets - optional flag limiting the run to one
    #        group of tables.
    #   $2 - work_dir - optional directory for generated files.
    #
    # Example:
    #   main --timing '/tmp/s-vhs-encoding-bench'
    #
    local only=''
    local work_dir repo_dir stress logo

    case "${1-}" in
        --timing|--presets)
            only="${1#--}"
            shift
            ;;
    esac
    work_dir="${1:-$_BENCH_DEFAULT_WORK_DIR}"
    repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
    stress="$work_dir/stress.gif"
    logo="$repo_dir/examples/logo.gif"

    _bench_require_tools "$only" || exit 1
    mkdir -p "$work_dir" || exit 1
    _bench_render_stress_clip "$repo_dir" "$work_dir" || exit 1

    ffmpeg -version || exit 1
    case "$only" in
        timing)
            _bench_report_timing "$stress" "$logo" "$work_dir" || exit 1
            return 0
            ;;
        presets)
            _bench_report_preset_ladder "$stress" "$work_dir" || exit 1
            _bench_report_preset_ladder "$logo" "$work_dir" || exit 1
            return 0
            ;;
    esac
    _bench_report_inputs "$stress" "$logo" || exit 1
    _bench_report_codec_matrix "$stress" "$work_dir" || exit 1
    _bench_report_codec_matrix "$logo" "$work_dir" || exit 1
    _bench_report_colour_grid "$stress" "$work_dir" || exit 1
    _bench_report_frame_policy "$stress" "$work_dir" || exit 1
    _bench_report_quality_ladder "$stress" "$work_dir" || exit 1
    _bench_report_quality_ladder "$logo" "$work_dir" || exit 1
    _bench_report_preset_ladder "$stress" "$work_dir" || exit 1
    _bench_report_preset_ladder "$logo" "$work_dir" || exit 1
    _bench_report_timing "$stress" "$logo" "$work_dir" || exit 1
    _bench_write_sample_bundle "$stress" "$work_dir" || exit 1
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
    #   $1 - only - table group the run is limited to, empty for all of them.
    #
    # Example:
    #   _bench_require_tools '' || exit 1
    #
    local only="$1"
    local tool encoder encoders
    local missing=()
    local required=(libx264 libx264rgb libx265 libsvtav1)

    # the timing tables and the preset ladders encode H.264 alone
    [[ -n $only ]] && required=(libx264)

    for tool in ffmpeg ffprobe; do
        command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
    done
    if [[ ${#missing[@]} -ne 0 ]]; then
        printf 'encoding-bench: not installed: %s\n' "${missing[*]}" >&2
        return 1
    fi

    encoders=$(ffmpeg -hide_banner -encoders 2>&1) || return 1
    for encoder in "${required[@]}"; do
        if ! printf '%s\n' "$encoders" | grep -qw "$encoder"; then
            printf 'encoding-bench: ffmpeg lacks %s\n' "$encoder" >&2
            return 1
        fi
    done
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
    local input dimensions bytes frames duration checksum

    printf '\n=== Inputs ===\n'
    printf '%-28s %11s %9s %7s %9s\n' 'input' 'dimensions' 'bytes' 'frames' 'duration'
    for input in ${@+"$@"}; do
        dimensions=$(_bench_dimensions "$input" | tr ':' 'x') || return 1
        bytes=$(_bench_bytes "$input") || return 1
        frames=$(_bench_frame_count "$input") || return 1
        duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 \
            "${_BENCH_DECODE[@]}" "$input") || return 1
        checksum=$(cksum "$input") || return 1
        printf '%-28s %11s %9s %7s %9s\n' "$(basename "$input")" \
            "$dimensions" "$bytes" "$frames" "$duration"
        printf '  cksum (CRC, bytes, path): %s\n' "$checksum"
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
            -vf "$_BENCH_PAD" -c:v libx264 -pix_fmt yuv420p -crf "$crf" -preset medium || return 1
    done
    for preset in ultrafast fast slow veryslow; do
        _bench_codec_row "$input" "$out_dir" "x264-420-crf18-$preset" \
            -vf "$_BENCH_PAD" -c:v libx264 -pix_fmt yuv420p -crf 18 -preset "$preset" || return 1
    done
    for crf in 14 18 23; do
        _bench_codec_row "$input" "$out_dir" "x264-444-crf$crf-medium" \
            -c:v libx264 -pix_fmt yuv444p -crf "$crf" -preset medium || return 1
    done

    _bench_codec_row "$input" "$out_dir" 'x264-444-lossless' \
        -c:v libx264 -pix_fmt yuv444p -qp 0 -preset medium || return 1
    _bench_codec_row "$input" "$out_dir" 'x264rgb-lossless' \
        -c:v libx264rgb -pix_fmt rgb24 -qp 0 -preset medium || return 1
    _bench_codec_row "$input" "$out_dir" 'x264rgb-lossless-veryslow' \
        -c:v libx264rgb -pix_fmt rgb24 -qp 0 -preset veryslow || return 1
    _bench_codec_row "$input" "$out_dir" 'x264-420-crf18-animation' \
        -vf "$_BENCH_PAD" -c:v libx264 -pix_fmt yuv420p -crf 18 -preset medium -tune animation || return 1
    _bench_codec_row "$input" "$out_dir" 'x264-420-crf18-stillimage' \
        -vf "$_BENCH_PAD" -c:v libx264 -pix_fmt yuv420p -crf 18 -preset medium -tune stillimage || return 1
    _bench_codec_row "$input" "$out_dir" 'x264-420-crf18-nobframe' \
        -vf "$_BENCH_PAD" -c:v libx264 -pix_fmt yuv420p -crf 18 -preset medium -bf 0 || return 1
    _bench_codec_row "$input" "$out_dir" 'x265-420-crf20' \
        -vf "$_BENCH_PAD" -c:v libx265 -pix_fmt yuv420p -crf 20 -preset medium -tag:v hvc1 || return 1
    _bench_codec_row "$input" "$out_dir" 'x265-444-crf20' \
        -c:v libx265 -pix_fmt yuv444p -crf 20 -preset medium -tag:v hvc1 || return 1
    _bench_codec_row "$input" "$out_dir" 'svtav1-420-crf30' \
        -vf "$_BENCH_PAD" -c:v libsvtav1 -pix_fmt yuv420p -crf 30 -preset 6 || return 1
    _bench_codec_row "$input" "$out_dir" 'svtav1-420-crf20' \
        -vf "$_BENCH_PAD" -c:v libsvtav1 -pix_fmt yuv420p -crf 20 -preset 6 || return 1

    _bench_verify_rgb "$input" "$out_dir/x264rgb-lossless.mp4" || return 1
    _bench_verify_rgb "$input" "$out_dir/x264rgb-lossless-veryslow.mp4" || return 1
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
    printf '\n=== Colour: matrix x range, crf 18, bf 0 (%s) ===\n' "$(basename "$input")"
    printf '%-22s %9s %11s %11s %11s %11s  %s\n' \
        'config' 'bytes' 'PSNR/tags' 'PSNR/auto' 'PSNR/709tv' 'PSNR/601tv' 'stream tags'

    _bench_colour_row "$input" "$out_dir" 'default-untagged' yuv420p '' '' || return 1
    _bench_colour_row "$input" "$out_dir" '420-601-tv' yuv420p bt470bg tv || return 1
    _bench_colour_row "$input" "$out_dir" '420-601-pc' yuv420p bt470bg full || return 1
    _bench_colour_row "$input" "$out_dir" '420-709-tv' yuv420p bt709 tv || return 1
    _bench_colour_row "$input" "$out_dir" '420-709-pc' yuv420p bt709 full || return 1
    _bench_colour_row "$input" "$out_dir" '444-601-pc' yuv444p bt470bg full || return 1
    _bench_colour_row "$input" "$out_dir" '444-709-pc' yuv444p bt709 full || return 1
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
    printf '\n=== Frame policy: BT.601 limited, crf 18, bf 0 (%s) ===\n' "$(basename "$input")"
    printf '%-26s %10s %11s %10s\n' 'policy' 'bytes' 'vs default' 'keyframes'

    baseline=$(_bench_frame_policy_encode "$input" "$out_dir/default.mp4") || return 1
    _bench_frame_policy_row 'default (keyint+scenecut)' "$out_dir/default.mp4" "$baseline" || return 1
    for gop in 1 15 30 60 120; do
        _bench_frame_policy_encode "$input" "$out_dir/g$gop.mp4" -g "$gop" >/dev/null || return 1
        _bench_frame_policy_row "-g $gop" "$out_dir/g$gop.mp4" "$baseline" || return 1
    done
    for seconds in 5 10; do
        _bench_frame_policy_encode "$input" "$out_dir/t$seconds.mp4" \
            -force_key_frames "expr:gte(t,n_forced*$seconds)" >/dev/null || return 1
        _bench_frame_policy_row "keyframe every ${seconds}s" \
            "$out_dir/t$seconds.mp4" "$baseline" || return 1
    done
}


_bench_report_quality_ladder() {
    #
    # Print the CRF table for the chosen pipeline, measured both against the
    # GIF and against a lossless 4:2:0 round trip. The latter isolates codec
    # perturbation from conversion/subsampling, not an additive error term.
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
    local encoded bytes crf reference_psnr gif_psnr codec_psnr

    out_dir="$2/ladder-$(basename "$input" .gif)"
    reference="$out_dir/lossless-420.mp4"
    mkdir -p "$out_dir" || return 1
    _bench_encode "$input" "$reference" -vf "$_BENCH_PAD,$_BENCH_COLOR" \
        -c:v libx264 -qp 0 -preset medium -bf 0 >/dev/null || return 1

    printf '\n=== Quality ladder: 4:2:0, BT.601 limited, bf 0 (%s, GIF %s B) ===\n' \
        "$(basename "$input")" "$(_bench_bytes "$input")"
    reference_psnr=$(_bench_psnr "$input" "$reference" '') || return 1
    printf 'lossless 4:2:0 round trip: %s B (%s of the GIF), PSNR %s\n' \
        "$(_bench_bytes "$reference")" \
        "$(_bench_percent "$(_bench_bytes "$reference")" "$(_bench_bytes "$input")")" \
        "$reference_psnr"
    printf '%-8s %10s %8s %13s %15s\n' \
        'crf' 'bytes' 'vs GIF' 'PSNR vs GIF' 'PSNR vs 4:2:0'

    for crf in 14 16 18 20 23; do
        encoded="$out_dir/crf$crf.mp4"
        _bench_encode "$input" "$encoded" -vf "$_BENCH_PAD,$_BENCH_COLOR" \
            -c:v libx264 -crf "$crf" -preset medium -profile:v high -bf 0 >/dev/null || return 1
        bytes=$(_bench_bytes "$encoded") || return 1
        gif_psnr=$(_bench_psnr "$input" "$encoded" '') || return 1
        codec_psnr=$(_bench_psnr "$reference" "$encoded" '') || return 1
        printf '%-8s %10s %8s %13s %15s\n' "crf $crf" "$bytes" \
            "$(_bench_percent "$bytes" "$(_bench_bytes "$input")")" \
            "$gif_psnr" "$codec_psnr"
    done
}


_bench_report_preset_ladder() {
    #
    # Print the preset table for the shipped contract: what x264's extra
    # search time buys at a fixed CRF once B-frames are off. The column
    # against the lossless 4:2:0 round trip is the one that separates a
    # preset's own coding damage from the conversion damage every row shares.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - work_dir - directory the encodes are written to.
    #
    # Example:
    #   _bench_report_preset_ladder "$stress" "$work_dir"
    #
    local input="$1"
    local out_dir
    local reference
    local encoded bytes baseline preset elapsed gif_psnr codec_psnr

    out_dir="$2/presets-$(basename "$input" .gif)"
    reference="$out_dir/lossless-420.mp4"
    mkdir -p "$out_dir" || return 1
    _bench_encode "$input" "$reference" -vf "$_BENCH_PAD,$_BENCH_COLOR" \
        -c:v libx264 -qp 0 -preset medium -bf 0 >/dev/null || return 1

    printf '\n=== Preset ladder: 4:2:0, BT.601 limited, bf 0, crf 18 (%s, GIF %s B) ===\n' \
        "$(basename "$input")" "$(_bench_bytes "$input")"
    printf '%-10s %10s %11s %8s %13s %15s\n' \
        'preset' 'bytes' 'vs medium' 'time' 'PSNR vs GIF' 'PSNR vs 4:2:0'

    for preset in medium slow slower veryslow placebo; do
        encoded="$out_dir/$preset.mp4"
        elapsed=$(_bench_encode "$input" "$encoded" -vf "$_BENCH_PAD,$_BENCH_COLOR" \
            -c:v libx264 -crf 18 -preset "$preset" -profile:v high -bf 0) || return 1
        bytes=$(_bench_bytes "$encoded") || return 1
        [[ $preset == 'medium' ]] && baseline="$bytes"
        gif_psnr=$(_bench_psnr "$input" "$encoded" '') || return 1
        codec_psnr=$(_bench_psnr "$reference" "$encoded" '') || return 1
        printf '%-10s %10s %11s %7ss %13s %15s\n' "$preset" "$bytes" \
            "$(_bench_percent "$bytes" "$baseline")" "$elapsed" \
            "$gif_psnr" "$codec_psnr"
    done
}


_bench_write_sample_bundle() {
    #
    # Write the files the manual playback pass needs: the selected contract,
    # its alternatives, and a page for testing them without predicted results.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - work_dir - directory holding the encodes.
    #
    # Example:
    #   _bench_write_sample_bundle "$stress" "$work_dir"
    #
    local input="$1"
    local work_dir="$2"
    local out_dir="$work_dir/playback"

    mkdir -p "$out_dir" || return 1
    cp "$input" "$out_dir/source.gif" || return 1

    # use exactly the measured files, not similar-looking re-encodes
    cp "$work_dir/colour/420-601-tv.mp4" "$out_dir/a-420-bt601-tv.mp4" || return 1
    cp "$work_dir/colour/420-709-tv.mp4" "$out_dir/b-420-bt709-tv.mp4" || return 1
    cp "$work_dir/colour/420-601-pc.mp4" "$out_dir/c-420-bt601-full.mp4" || return 1
    cp "$work_dir/colour/444-601-pc.mp4" "$out_dir/d-444-bt601-full.mp4" || return 1
    cp "$work_dir/codec-$(basename "$input" .gif)/x264rgb-lossless.mp4" "$out_dir/e-rgb-lossless.mp4" || return 1
    cp "$work_dir/timing/$(basename "$input" .gif)-cfr30.mp4" "$out_dir/g-cfr30.mp4" || return 1
    cp "$work_dir/timing/$(basename "$input" .gif)-cfr100.mp4" "$out_dir/h-cfr100.mp4" || return 1

    # retain the old BT.709 transfer label as a same-pixel comparison;
    # the sRGB tag still needs colour-managed player verification
    ffmpeg -v error -nostdin -y -i "$out_dir/a-420-bt601-tv.mp4" -c:v copy \
        -bsf:v h264_metadata=transfer_characteristics=1 -color_trc bt709 \
        -movflags +faststart "$out_dir/f-420-bt601-bt709-transfer.mp4" || return 1

    cat >"$out_dir/index.html" <<'HTML' || return 1
<!doctype html><meta charset=utf-8><title>s-vhs MP4 samples</title>
<style>body{font:14px system-ui;background:#222;color:#eee;margin:2em}
figure{margin:0 0 2em}video,img{border:1px solid #555}</style>
<h1>s-vhs MP4 encoding samples — record what this setup does</h1>
<p>Shown at native resolution. Inspect small coloured glyphs, neutral greys,
colour shifts, seeking and the final hold. 4:2:0 is lossy: an RGB score is not
proof of legibility or colour-managed display accuracy.</p>
<p>Record player/browser version, OS, hardware decoding on/off, playback,
colour and timing for each file. Do not infer a result from its profile.
All samples are VFR with no B-frames except the two labelled CFR.</p>
<figure><figcaption>a - 4:2:0, BT.601 limited, sRGB transfer tag (selected contract)</figcaption><video src=a-420-bt601-tv.mp4 controls loop muted></video></figure>
<figure><figcaption>b - 4:2:0, BT.709 limited, sRGB transfer tag</figcaption><video src=b-420-bt709-tv.mp4 controls loop muted></video></figure>
<figure><figcaption>c - 4:2:0, BT.601 full, sRGB transfer tag</figcaption><video src=c-420-bt601-full.mp4 controls loop muted></video></figure>
<figure><figcaption>d - 4:4:4, BT.601 full, sRGB transfer tag</figcaption><video src=d-444-bt601-full.mp4 controls loop muted></video></figure>
<figure><figcaption>e - RGB lossless, High 4:4:4 Predictive</figcaption><video src=e-rgb-lossless.mp4 controls loop muted></video></figure>
<figure><figcaption>f - same pixels as a, old BT.709 transfer tag instead</figcaption><video src=f-420-bt601-bt709-transfer.mp4 controls loop muted></video></figure>
<figure><figcaption>g - selected colour pipeline, CFR 30, B-frames on</figcaption><video src=g-cfr30.mp4 controls loop muted></video></figure>
<figure><figcaption>h - selected colour pipeline, CFR 100, B-frames on</figcaption><video src=h-cfr100.mp4 controls loop muted></video></figure>
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

    elapsed=$(_bench_encode "$input" "$output" ${@+"$@"}) || {
        printf '%-28s %9s\n' "$name" 'FAILED'
        return 1
    }
    bytes=$(_bench_bytes "$output") || return 1
    quality=$(_bench_quality "$input" "$output") || return 1

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
    local tagged_psnr auto_psnr as_709 as_601 tags
    local filters=''
    local tagged_range="$range"
    local tagged_matrix="$matrix"

    [[ $pixel_format == 'yuv420p' ]] && filters="$_BENCH_PAD,"
    [[ $tagged_range == 'full' ]] && tagged_range='pc'
    [[ $tagged_matrix == 'bt470bg' ]] && tagged_matrix='smpte170m'

    if [[ -n $matrix ]]; then
        filters="${filters}scale=out_color_matrix=$matrix:out_range=$range:flags=full_chroma_int+accurate_rnd,format=$pixel_format,setparams=colorspace=$tagged_matrix:color_primaries=bt709:color_trc=iec61966-2-1:range=$tagged_range"
    else
        filters="${filters}format=$pixel_format"
    fi

    _bench_encode "$input" "$output" -vf "$filters" -c:v libx264 \
        -crf 18 -preset medium -bf 0 >/dev/null || return 1

    # setparams alone does not override yuvj*'s full-range interpretation;
    # change only VUI/container tags, without converting or re-encoding pixels
    _bench_retag "$output" "$out_dir/$name-as-709-tv.mp4" bt709 1 || return 1
    _bench_retag "$output" "$out_dir/$name-as-601-tv.mp4" smpte170m 6 || return 1
    tagged_psnr=$(_bench_psnr "$input" "$output" '') || return 1
    auto_psnr=$(_bench_psnr "$input" "$output" 'format=rgb24') || return 1
    as_709=$(_bench_psnr "$input" "$out_dir/$name-as-709-tv.mp4" '') || return 1
    as_601=$(_bench_psnr "$input" "$out_dir/$name-as-601-tv.mp4" '') || return 1
    tags=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=pix_fmt,color_range,color_space,color_primaries,color_transfer \
        -of csv=p=0 "$output") || return 1

    printf '%-22s %9s %11s %11s %11s %11s  %s\n' "$name" "$(_bench_bytes "$output")" \
        "$tagged_psnr" "$auto_psnr" "$as_709" "$as_601" "$tags"
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

    _bench_encode "$input" "$output" -vf "$_BENCH_PAD,$_BENCH_COLOR" -c:v libx264 \
        -crf 18 -preset medium -bf 0 ${@+"$@"} >/dev/null || return 1
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
    local bytes keyframes

    bytes=$(_bench_bytes "$encoded") || return 1
    keyframes=$(ffprobe -v error -select_streams v:0 -skip_frame nokey \
        -show_entries frame=pts_time -of csv=p=0 "$encoded" |
        awk -F, '$1 ~ /^[0-9.]+$/ { count++ } END { print count + 0 }') || return 1
    printf '%-26s %10s %11s %10s\n' "$name" "$bytes" \
        "$(_bench_percent "$bytes" "$baseline")" "$keyframes"
}


_bench_encode() {
    #
    # Encode one GIF to MP4 and print the elapsed seconds. The GIF is decoded
    # once, with a GIF-tick encoder time base. The timing table checks whether
    # the encoder/muxer actually preserves durations (B-frames may not).
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

    # keep the encoder/version diagnostics, and never accept a stale or
    # partially written file as proof that ffmpeg succeeded
    TIMEFORMAT='%R'
    if ! elapsed=$( { time ffmpeg -hide_banner -nostats -xerror -nostdin -y \
        "${_BENCH_DECODE[@]}" -i "$input" -map 0:v:0 -an \
        -fps_mode passthrough -enc_time_base 1:100 \
        ${@+"$@"} -movflags +faststart "$output" >"$output.log" 2>&1; } 2>&1 ); then
        printf 'encoding-bench: encode failed: %s (see %s.log)\n' "$output" "$output" >&2
        tail -20 "$output.log" >&2
        return 1
    fi

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
    local report ssim

    report=$(_bench_compare "$input" "$encoded" '' psnr) || return 1
    ssim=$(_bench_compare "$input" "$encoded" '' ssim) || return 1
    printf '%s %s %s' \
        "$(printf '%s' "$report" | grep -o 'average:[^ ]*' | cut -d: -f2)" \
        "$(printf '%s' "$report" | grep -o ' min:[^ ]*' | cut -d: -f2)" \
        "$(printf '%s' "$ssim" | grep -o 'All:[^ ]*' | cut -d: -f2)"
}


_bench_psnr() {
    #
    # Print average PSNR against a GIF or MP4 reference, optionally
    # decoded with an alternative RGB reconstruction filter.
    #
    # Parameters:
    #   $1 - input - reference GIF or MP4.
    #   $2 - encoded - MP4 to measure.
    #   $3 - reconstruction - RGB filter, or empty for the explicit default.
    #
    # Example:
    #   _bench_psnr "$gif" "$out" ''
    #
    _bench_compare "$1" "$2" "$3" psnr | grep -o 'average:[^ ]*' | cut -d: -f2
}


_bench_compare() {
    #
    # Compare equally many decoded frames in RGB, cropping off padding.
    # Frame-index alignment isolates pixel error; it does not validate timing.
    # Compare nonlinear RGB samples, not transfer-converted display light.
    #
    # Parameters:
    #   $1 - input - reference GIF or MP4.
    #   $2 - encoded - MP4 to measure.
    #   $3 - reconstruction - RGB filter, or empty for the explicit default.
    #   $4 - filter - psnr or ssim.
    #
    # Example:
    #   _bench_compare "$gif" "$out" '' psnr
    #
    local input="$1"
    local encoded="$2"
    local reconstruction="${3:-$_BENCH_RGB}"
    local filter="$4"
    local dimensions reference_count encoded_count report
    local reference_rgb="$_BENCH_RGB"
    local decode=()

    if [[ $input == *.gif ]]; then
        decode=("${_BENCH_DECODE[@]}")
        reference_rgb='format=rgb24'
    fi
    dimensions=$(_bench_dimensions "$input") || return 1
    reference_count=$(_bench_frame_count "$input") || return 1
    encoded_count=$(_bench_frame_count "$encoded") || return 1
    if [[ $reference_count != "$encoded_count" ]]; then
        printf 'encoding-bench: frame count mismatch: %s (%s) vs %s (%s)\n' \
            "$input" "$reference_count" "$encoded" "$encoded_count" >&2
        return 1
    fi

    if ! report=$(ffmpeg -hide_banner -nostats -xerror -nostdin \
        ${decode[@]+"${decode[@]}"} -i "$input" -i "$encoded" \
        -lavfi "[0:v]$reference_rgb,settb=1/100,setpts=N[a];[1:v]$reconstruction,crop=$dimensions:0:0,settb=1/100,setpts=N[b];[a][b]$filter=shortest=1:repeatlast=0" \
        -fps_mode passthrough -f null - 2>&1); then
        printf 'encoding-bench: comparison failed: %s\n%s\n' "$encoded" "$report" >&2
        return 1
    fi
    printf '%s\n' "$report" | grep -o "$(printf '%s' "$filter" | tr '[:lower:]' '[:upper:]') .*"
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


_bench_frame_count() {
    #
    # Count decoded frames, including a single GIF pass with short delays.
    #
    # Parameters:
    #   $1 - input - GIF or MP4 path.
    #
    # Example:
    #   count=$(_bench_frame_count "$input") || return 1
    #
    local input="$1"
    local count
    local decode=()

    [[ $input == *.gif ]] && decode=("${_BENCH_DECODE[@]}")
    count=$(ffprobe -v error ${decode[@]+"${decode[@]}"} -select_streams v:0 \
        -count_frames -show_entries stream=nb_read_frames -of csv=p=0 "$input") || return 1
    [[ $count =~ ^[1-9][0-9]*$ ]] || return 1
    printf '%s\n' "$count"
}


_bench_frame_hashes() {
    #
    # Print framemd5 pixel hashes only, ignoring timestamps and metadata.
    #
    # Parameters:
    #   $1 - input - GIF or MP4 path.
    #   $2 - filter - pixel conversion, or null to preserve decoded samples.
    #
    # Example:
    #   _bench_frame_hashes "$input" 'format=rgb24' >"$output.hashes"
    #
    local input="$1"
    local filter="$2"
    local decode=()

    [[ $input == *.gif ]] && decode=("${_BENCH_DECODE[@]}")
    ffmpeg -v error -xerror -nostdin ${decode[@]+"${decode[@]}"} -i "$input" \
        -vf "$filter" -fps_mode passthrough -f framemd5 - |
        awk -F, '!/^#/ && NF == 6 { print $6; count++ } END { if (!count) exit 1 }'
}


_bench_verify_rgb() {
    #
    # Require every decoded RGB frame to be bit-exact, independent of PSNR.
    #
    # Parameters:
    #   $1 - input - source GIF.
    #   $2 - encoded - RGB lossless MP4.
    #
    # Example:
    #   _bench_verify_rgb "$gif" "$rgb_mp4" || return 1
    #
    local input="$1"
    local encoded="$2"

    _bench_frame_hashes "$input" 'format=rgb24' >"$encoded.reference.hashes" || return 1
    _bench_frame_hashes "$encoded" 'format=rgb24' >"$encoded.hashes" || return 1
    diff -q "$encoded.reference.hashes" "$encoded.hashes" || return 1
    printf '::: RGB frame hashes match: %s\n' "$encoded"
}


_bench_retag() {
    #
    # Simulate a limited-range player assumption without changing YUV samples.
    # Rewrite both H.264 VUI and MP4 metadata; verify the tags and raw hashes.
    #
    # Parameters:
    #   $1 - input - original H.264 MP4.
    #   $2 - output - retagged MP4.
    #   $3 - matrix - ffmpeg matrix name.
    #   $4 - coefficient - H.264 matrix ID (1 for 709, 6 for 601).
    #
    # Example:
    #   _bench_retag "$full" "$limited" smpte170m 6 || return 1
    #
    local input="$1"
    local output="$2"
    local matrix="$3"
    local coefficient="$4"
    local tags

    ffmpeg -v error -xerror -nostdin -y -i "$input" -map 0:v:0 -an -c:v copy \
        -bsf:v "h264_metadata=video_full_range_flag=0:matrix_coefficients=$coefficient" \
        -colorspace "$matrix" -color_range tv -movflags +faststart "$output" || return 1
    tags=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=color_range,color_space -of csv=p=0 "$output") || return 1
    [[ $tags == "tv,$matrix" ]] || return 1
    _bench_frame_hashes "$input" null >"$output.reference.hashes" || return 1
    _bench_frame_hashes "$output" null >"$output.hashes" || return 1
    diff -q "$output.reference.hashes" "$output.hashes"
}


_bench_write_timing_fixtures() {
    #
    # Make deterministic odd-sized GIFs with short delays, long holds, a
    # changed playback speed, and a single frame with a custom final hold.
    #
    # Parameters:
    #   $1 - out_dir - directory for generated GIFs.
    #
    # Example:
    #   _bench_write_timing_fixtures "$work_dir/timing" || return 1
    #
    local out_dir="$1"

    ffmpeg -v error -nostdin -y -f lavfi -i 'testsrc=size=65x33:rate=100' \
        -frames:v 5 -vf 'settb=1/100,setpts=if(eq(N\,0)\,0\,if(eq(N\,1)\,1\,if(eq(N\,2)\,3\,if(eq(N\,3)\,603\,607))))' \
        -fps_mode passthrough -enc_time_base 1:100 -final_delay 300 "$out_dir/delays.gif" || return 1
    ffmpeg -v error -nostdin -y -f lavfi -i 'testsrc=size=65x33:rate=100' \
        -frames:v 1 -final_delay 321 "$out_dir/single.gif" || return 1
    # a zero GIF delay is normalized to 100 ms by this FFmpeg demuxer
    ffmpeg -v error -nostdin -y -f lavfi -i 'testsrc=size=65x33:rate=100' \
        -frames:v 1 -final_delay 0 "$out_dir/zero.gif" || return 1
    ffmpeg -v error -nostdin -y "${_BENCH_DECODE[@]}" -i "$out_dir/delays.gif" \
        -vf 'setpts=2*PTS' -fps_mode passthrough -enc_time_base 1:100 \
        -final_delay 600 "$out_dir/slowed.gif"
}


_bench_frame_times() {
    #
    # Print presentation-order PTS and duration pairs, rejecting missing data.
    #
    # Parameters:
    #   $1 - input - GIF or MP4.
    #
    # Example:
    #   _bench_frame_times "$input" >"$output.times" || return 1
    #
    local input="$1"
    local decode=()

    [[ $input == *.gif ]] && decode=("${_BENCH_DECODE[@]}")
    ffprobe -v error ${decode[@]+"${decode[@]}"} -select_streams v:0 \
        -show_entries frame=pts_time,duration_time -of csv=p=0 "$input" |
        awk -F, 'NF { if ($1 !~ /^[0-9.]+$/ || $2 !~ /^[0-9.]+$/) exit 1; print $1 "," $2; count++ }
            END { if (!count) exit 1 }'
}


_bench_timing_row() {
    #
    # Compare every indexed timestamp/duration and the container end time.
    # Different frame counts (CFR) deliberately have no indexed error score.
    #
    # Parameters:
    #   $1 - input - reference GIF.
    #   $2 - encoded - MP4.
    #   $3 - name - policy label.
    #   $4 - require_match - 1 to fail on a timing mismatch, otherwise 0.
    #
    # Example:
    #   _bench_timing_row "$gif" "$mp4" 'vfr-no-b' 1 || return 1
    #
    local input="$1"
    local encoded="$2"
    local name="$3"
    local require_match="$4"
    local container report frames level

    _bench_frame_times "$input" >"$encoded.reference.times" || return 1
    _bench_frame_times "$encoded" >"$encoded.times" || return 1
    container=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$encoded") || return 1
    level=$(ffprobe -v error -select_streams v:0 -show_entries stream=level -of csv=p=0 "$encoded") || return 1
    frames=$(wc -l <"$encoded.times")
    report=$(awk -F, -v container="$container" -v tolerance="$_BENCH_TIMING_TOLERANCE" \
        -v require_match="$require_match" "$_BENCH_TIMING_COMPARE" \
        "$encoded.reference.times" "$encoded.times") || {
        printf 'encoding-bench: timing failed: %s: %s\n' "$encoded" "$report" >&2
        return 1
    }
    printf '%-18s %10s %7s %5s %s\n' "$name" "$(_bench_bytes "$encoded")" "$frames" "$level" "$report"
}


_bench_report_timing() {
    #
    # Compare default timing, centisecond VFR, and CFR on real and synthetic
    # inputs. The selected no-B-frame centisecond policy must pass every check.
    #
    # Parameters:
    #   $1 - stress - stress GIF.
    #   $2 - logo - odd-width logo GIF.
    #   $3 - work_dir - directory for generated encodes and timestamp reports.
    #
    # Example:
    #   _bench_report_timing "$stress" "$logo" "$work_dir" || return 1
    #
    local stress="$1"
    local logo="$2"
    local out_dir="$3/timing"
    local input policy output filters require_match
    local options=()

    mkdir -p "$out_dir" || return 1
    _bench_write_timing_fixtures "$out_dir" || return 1
    for input in "$stress" "$logo" "$out_dir/delays.gif" "$out_dir/single.gif" "$out_dir/slowed.gif" "$out_dir/zero.gif"; do
        printf '\n=== Timing: %s (tolerance %s s) ===\n' "$(basename "$input")" "$_BENCH_TIMING_TOLERANCE"
        printf '%-18s %10s %7s %5s %9s %9s %8s %8s %8s %s\n' \
            'policy' 'bytes' 'frames' 'level' 'PTSerr/ms' 'delay/ms' 'last/s' 'end/s' 'file/s' 'indexed'
        for policy in vfr-b-auto-tb vfr-b vfr-no-b-auto-tb vfr-no-b cfr30 cfr100; do
            options=()
            filters="$_BENCH_PAD,$_BENCH_COLOR"
            require_match=0
            case "$policy" in
                vfr-b-auto-tb)    options=(-enc_time_base 0) ;;
                vfr-b)           options=() ;;
                vfr-no-b-auto-tb) options=(-bf 0 -enc_time_base 0) ;;
                vfr-no-b)        options=(-bf 0); require_match=1 ;;
                cfr30)           filters="$filters,fps=30"; options=(-enc_time_base 1:30) ;;
                cfr100)          filters="$filters,fps=100"; options=(-enc_time_base 1:100) ;;
            esac
            output="$out_dir/$(basename "$input" .gif)-$policy.mp4"
            if ! _bench_encode "$input" "$output" -vf "$filters" -c:v libx264 \
                -crf 18 -preset medium -profile:v high ${options[@]+"${options[@]}"} >/dev/null; then
                # coarse automatic time bases can collapse distinct GIF PTS;
                # this is a result of that probe, never a usable partial file
                if [[ $policy == *-auto-tb ]] && grep -q 'Non-monotonic DTS;' "$output.log"; then
                    printf '%-18s ENCODE FAILED (timestamp collision; see %s.log)\n' "$policy" "$output"
                    continue
                fi
                return 1
            fi
            _bench_timing_row "$input" "$output" "$policy" "$require_match" || return 1
        done
    done
}


main ${@+"$@"}
