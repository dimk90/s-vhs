
## `[v0.7.0]`

- [x] Add MP4:
  - Scope: `.cast` -> one shared `agg` GIF -> MP4 through `ffmpeg`.
    WebM and video-specific `SetOptimize` behavior remain separate tasks.
  - [x] Compare encodings and select the output contract. Measurements, inputs
    and rejected alternatives: `doc/ENCODING.md`, reproducible with
    `scripts/encoding-bench.sh`. The selected contract to implement:
    - `libx264`, `yuv420p`, High profile, `-crf 18 -preset medium`.
    - `scale=out_color_matrix=bt601:out_range=tv:flags=full_chroma_int+accurate_rnd`,
      then `format=yuv420p`. Tag matrix `smpte170m`, primaries `bt709`,
      transfer `iec61966-2-1` (sRGB), range `tv`. Interpret the rendered GIF as
      sRGB; do not convert its transfer curve. BT.601 gains 0.96 dB with the
      benchmark's explicit RGB reconstruction; this is pipeline-specific.
    - Default keyint/scenecut, but `-bf 0` to preserve sample durations.
      Use `-fps_mode passthrough -enc_time_base 1:100` for centisecond VFR.
      Forced keyframes cost 1.2-24.1x the bytes; actual seeking is unmeasured.
    - `pad=ceil(iw/2)*2:ceil(ih/2)*2:0:0` for odd dimensions,
      `-movflags +faststart`, no audio track.
    - No lossless mode and no new setter: tested `libx264rgb -qp 0` is bit-exact
      but costs 174 % of stress GIF and fails in both tested browsers;
      WebP already covers lossless raster output.
    - Playback checked by hand: the selected 4:2:0 output plays in Chrome and
      Firefox; 4:4:4 fails in Firefox and RGB lossless in both. Colour-managed
      comparison against the source GIF (sRGB versus the BT.709 transfer tag)
      is still open, as are Safari, VLC and mobile players.
  - [x] Establish MP4 timing, geometry and setting behavior:
    - Settled behavior, to implement as written. The encoder-facing half is the
      contract in `doc/ENCODING.md`; these are the s-vhs-facing decisions it
      does not cover:
      - Decode one GIF pass with `-ignore_loop 1 -min_delay 0`, exactly as the
        WebP path already does. The timing `SetPlaybackSpeed`,
        `SetIdleTimeLimit` and `SetLastFrameDuration` produced in the shared
        GIF is preserved, never applied a second time in the encoder.
      - Pad odd dimensions by at most one pixel on the right/bottom instead of
        scaling or cropping terminal text. Report MP4 geometry as the probe
        size rounded up to even, with no padding wording in the message; a
        failed probe stays an estimate, marked `~` as for GIF and WebP.
      - Write silent video with `-movflags +faststart`. Looping is
        player-controlled, not a portable MP4-file setting: document that in
        `README.md` and `doc/REFERENCE.md`, and report `SetLoop` as skipped
        only when a script called it explicitly, the way `SetEngine` and
        `SetLastFrameDuration` are reported elsewhere, so the default `on`
        leaves a plain MP4 render silent.
      - Keep `SetOptimize` inactive for MP4 until its own roadmap item lands
        and report `SetOptimize on` as skipped, as SVG does. Every raster
        setting that reaches the shared GIF - fonts, engine, theme, framerate,
        playback speed, idle time limit, last frame duration - applies to MP4
        unchanged, while `SetPadding`, `SetPaddingX`, `SetPaddingY`,
        `SetWindowBar` and `SetCursor` keep the existing raster skip lines
        under an `MP4 output` label. Preserve existing GIF/WebP behavior and
        report SVG-only settings as skipped for MP4 too.
      - Keep `-fps_mode passthrough` rather than the deprecated `-vsync
        passthrough`, and require `ffmpeg` 6.1 or newer for MP4 output.
        Measured across static 5.1.1, 6.0.1, 6.1.2, 7.0.2 and 8.1.2 builds
        (`doc/ENCODING.md`, section 7): 5.1 is the floor for `-fps_mode`
        alone, but 5.1 and 6.0 drop the final hold to a single GIF tick, and
        `out_color_matrix` must be spelled `bt601`, since `bt470bg` selects the
        same matrix but only exists from ffmpeg 8. This is the project's first
        version requirement - the WebP path runs on far older builds - and it
        excludes Ubuntu 22.04 LTS (4.4) and Debian 12 (5.1).
      - The timing itself preserves all timestamps, sample durations and
        container ends within the 1 ms acceptance bound on two real clips and
        four synthetic fixtures (including a zero GIF delay normalized by
        FFmpeg to 100 ms). Plain passthrough with B-frames shortens stress's
        last sample to 0.04 s instead of 3 s, with a 25.89 s sample end and
        26.06 s container duration instead of 28.85 s. Automatic encoder time
        bases can also collapse timestamps and abort. CFR 100 preserves the
        grid but costs 3.35x the VFR candidate's bytes; CFR 30 rounds timing
        and can drop short frames.
  - [x] Integrate MP4 into `s-vhs.sh`:
    - Accept `.mp4` in `SetOutput`; route it through `Render` and
      `_svhs_render_raster`, reusing `_svhs_render_shared_gif` unchanged as the
      single full-recording raster render for GIF, WebP and MP4 outputs.
    - Extend `_svhs_require_dependencies` to require `agg`, `ffmpeg` and the
      selected encoder only for MP4 requests. Query FFmpeg's encoder list once
      for mixed WebP/MP4 requests, checking only the encoders actually needed;
      fail before starting tmux if a required tool or encoder is missing.
      Reject `ffmpeg` older than 6.1 for MP4 there too: older builds accept
      every option and then silently drop the recording's final hold.
    - Add `_svhs_encode_mp4` with the selected settings. Reuse progress reporting,
      quiet mode, noninteractive overwrite and `file:` output-path handling;
      propagate encoder failures even when called through `Render || exit 1`.
    - Extend `_svhs_report_geometry` and `_svhs_report_raster_skips` for MP4.
      Keep the shared GIF unmodified, retain only requested casts/GIFs, and use
      existing temporary-file cleanup on successful render and script exit.
    - Keep Bash 3.2/BSD compatibility. If the comparison justifies a new setter,
      validate it immediately and require it before `Start`, like other settings.
  - [x] Verify manually before marking the feature complete:
    - Run `bash -n s-vhs.sh` and `shellcheck s-vhs.sh`; exercise recording scripts
      under Bash 3.2 as well as the development shell.
    - Render MP4-only, several MP4 paths, GIF/WebP/MP4 together and all formats
      together. Confirm one shared full-recording GIF render regardless of output
      order, and no new renderer dependencies for cast/text-only recordings.
    - Inspect streams, dimensions, timestamps and duration with `ffprobe`; decode
      representative frames and replay outputs in the selected target players.
      Cover a single-frame recording, short frame delays, long holds, a custom
      final hold, playback speed changes and odd source dimensions.
    - Exercise missing tools/encoders, encoder-list failure, encode/write failure,
      paths containing spaces, quiet mode and skipped-setting messages. Confirm
      failures never print a success message for the failed output and temporary
      files are cleaned up on exit. `ffprobe` stays a verification tool, not a
      runtime dependency unless implementation demonstrates a concrete need.
  - [x] Update documentation with the implemented behavior:
    - Add MP4 installation instructions and an output-format row to `README.md`,
      including the required encoder, the `ffmpeg` 6.1 minimum, measured quality/compatibility trade-offs
      and player-controlled looping; do not describe lossy output as lossless.
    - Update `doc/REFERENCE.md`: `SetOutput`, `Render`, MP4 applicability for
      inherited raster settings, unsupported settings and any approved new setter.
      Update `doc/INTRO.md` to include MP4 in the shared-GIF pipeline description.
    - Add one MP4 entry under the unreleased changelog's `### New` heading.
      Tick these checkboxes only after implementation and verification; leave
      the following roadmap items untouched.

- [x] Update `SetOptimize` for MP4 video:
  - Scope: one lever - how much time x264 spends at the same CRF. No new
    setter, no new dependency, and no change to the shipped contract's codec,
    colour, timing or container options.
  - `High` profile is already the shipped contract; the only profile above it,
    High 4:4:4 Predictive, is rejected for compatibility (`doc/ENCODING.md`,
    section 1). Nothing left to decide there.
  - Optimization without quality loss: bit-lossless does not exist here - an
    MP4 is re-encoded, not repacked. Measured on the contract pipeline
    (`doc/ENCODING.md`, section 8), `-preset veryslow` saves 10 % on stress and
    20 % on the logo for 1.5-1.9x the encoding time, with quality tracking
    `medium` within about 0.1 dB in either direction. `placebo` costs 4.5-5x
    the time for another 1-3 %, and preset order is not monotonic in size.
    Selected: `veryslow`, every other encoder option unchanged.
  - [x] Measure presets on the shipped contract:
    - Add a preset ladder to `scripts/encoding-bench.sh`, shaped like the
      quality ladder: contract filters, `-bf 0`, `-profile:v high`, `-crf 18`,
      presets `medium slow slower veryslow placebo`, both inputs. Report
      bytes, size against `medium`, encode time, PSNR/SSIM against the GIF and
      PSNR against the lossless 4:2:0 round trip - the last column separates
      codec damage from conversion damage.
    - Record the table as a new `doc/ENCODING.md` section, before the contract.
  - [x] Decide from the table: take the slowest preset whose codec PSNR stays
    within 0.05 dB of `medium` and that saves at least 5 %. If `-bf 0` leaves
    no such preset, keep MP4 reporting `SetOptimize` as skipped and tick this
    item with the measurement as the answer.
  - [x] Integrate into `s-vhs.sh` when a preset wins:
    - `_svhs_encode_mp4` selects the preset from the setting, the way
      `_svhs_encode_webp` selects its effort arguments; every other encoder
      option stays byte-for-byte.
    - Drop the MP4 `SetOptimize` branch in `_svhs_report_raster_skips`,
      keeping the `SetLoop` line.
    - Widen the `SetOptimize` docstring: GIF and WebP keep every pixel, an MP4
      keeps the quality target, not the bits.
  - [x] Verify: `bash -n`, `shellcheck`; render one recording with the setting
    off and on and diff `ffprobe` output - frame count, timestamps, sample
    durations, container duration, `has_b_frames=0`, profile and colour tags
    must be identical, with only bytes and encode time differing. Confirm the
    codec PSNR, replay in Chrome and Firefox, and check quiet mode and a long
    recording's wall time.
  - [x] Document: the `doc/REFERENCE.md` row, the `README.md` optimization
    section - its "without a single pixel changing" claim becomes GIF/WebP
    only - the `.mp4` and `SetOptimize` bullets in
    `skills/s-vhs-recording/SKILL.md`, a contract bullet in
    `doc/ENCODING.md`, and one `### Changed` changelog line.

- [ ] Report encode position, not only elapsed time, for MP4:
  - `_svhs_report_encode_progress` prints elapsed seconds alone because
    `libwebp_anim` reports no position; `libx264` does emit `out_time`, and a
    slower optimization preset makes a silent multi-minute encode worse.
  - Read the position when the encoder reports one, keep the elapsed-only line
    as the fallback for WebP, and decide whether the rendered GIF's duration
    is known early enough to print a percentage.

- [ ] WebM output:
  - GIF to WebM conversion via `ffmpeg`.
  - Full chroma (4:4:4 chroma)?
  - Choose codec and parameters which are best fit for terminal recording content.
  - Update README output format section and install instruction for webp format.

- [ ] Update `SetOptimize` for WebM video:
  - Is there any space for optimization without quality loss?
  - `High` profile?

- [ ] Add `SUPPORT-MATRIX` to the README documentation section.

- [ ] Add note about compression efficiency:
  - use `logo` as example example.
  - SetOptimize on/off
  - Quality drop for video.
