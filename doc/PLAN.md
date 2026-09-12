
## `[v0.7.0]`

- [ ] Add MP4:
  - Scope: `.cast` -> one shared `agg` GIF -> MP4 through `ffmpeg`.
    WebM and video-specific `SetOptimize` behavior remain separate tasks.
  - [x] Compare encodings before choosing the output contract. Measurements,
    inputs and rejected alternatives: `doc/ENCODING.md`, reproducible with
    `scripts/encoding-bench.sh`. The contract to implement:
    - `libx264`, `yuv420p`, High profile, `-crf 18 -preset medium`.
    - `scale=out_color_matrix=bt470bg:out_range=tv:flags=full_chroma_int+accurate_rnd`,
      tagged to match: `smpte170m`, primaries and transfer `bt709`, range `tv`.
      BT.601 is worth 1.3-2.1 dB over BT.709 on 4:2:0 terminal text, and holds
      up better than BT.709 even when a player ignores the tags.
    - x264's default GOP: scenecut keyframes, B-frames on. Forcing keyframes
      costs 1.7-26x the bytes and buys no practical seek improvement.
    - `pad=ceil(iw/2)*2:ceil(ih/2)*2:0:0` for odd dimensions,
      `-movflags +faststart`, no audio track.
    - No lossless mode and no new setter: only `libx264rgb -qp 0` is bit-exact,
      it costs 176 % of the GIF and plays nowhere, and WebP already covers
      lossless raster output.
  - [ ] Establish MP4 timing, geometry and setting behavior:
    - Decode one GIF pass with `-ignore_loop 1 -min_delay 0`; preserve the
      timing already produced by `SetPlaybackSpeed`, `SetIdleTimeLimit` and
      `SetLastFrameDuration`, rather than applying those settings twice.
    - Compare variable-frame-rate timestamp preservation with constant-frame-rate
      output for player compatibility, size and timing accuracy. Verify the final
      frame's duration explicitly; do not blindly reuse WebP's `fps=100` workaround.
      Define an acceptable rounding tolerance before selecting the frame policy.
      Measured during the comparison: plain `-fps_mode passthrough` drops the
      final hold, turning a 30.69 s GIF into a 27.73 s MP4 whose last frame
      lasts 0.04 s instead of ~3 s. MP4 needs its own fix for this, as WebP did.
    - If the selected pixel format requires even dimensions, pad by at most one
      pixel on the right/bottom instead of scaling or cropping terminal text;
      include that padding in reported MP4 geometry.
    - Write silent video with `-movflags +faststart`. Looping is player-controlled,
      not a portable MP4-file setting: document this and report unsupported
      `SetLoop on` through the existing skipped-setting warning mechanism.
    - Keep `SetOptimize` inactive for MP4 until its own roadmap item lands;
      report `SetOptimize on` as skipped. Preserve existing GIF/WebP behavior
      and report SVG-only settings as skipped for MP4 too.
  - [ ] Integrate MP4 into `s-vhs.sh`:
    - Accept `.mp4` in `SetOutput`; route it through `Render` and
      `_svhs_render_raster`, reusing `_svhs_render_shared_gif` unchanged as the
      single full-recording raster render for GIF, WebP and MP4 outputs.
    - Extend `_svhs_require_dependencies` to require `agg`, `ffmpeg` and the
      selected encoder only for MP4 requests. Query FFmpeg's encoder list once
      for mixed WebP/MP4 requests, checking only the encoders actually needed;
      fail before starting tmux if a required tool or encoder is missing.
    - Add `_svhs_encode_mp4` with the selected settings. Reuse progress reporting,
      quiet mode, noninteractive overwrite and `file:` output-path handling;
      propagate encoder failures even when called through `Render || exit 1`.
    - Extend `_svhs_report_geometry` and `_svhs_report_raster_skips` for MP4.
      Keep the shared GIF unmodified, retain only requested casts/GIFs, and use
      existing temporary-file cleanup on successful render and script exit.
    - Keep Bash 3.2/BSD compatibility. If the comparison justifies a new setter,
      validate it immediately and require it before `Start`, like other settings.
  - [ ] Verify manually before marking the feature complete:
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
  - [ ] Update documentation with the implemented behavior:
    - Add MP4 installation instructions and an output-format row to `README.md`,
      including the required encoder, measured quality/compatibility trade-offs
      and player-controlled looping; do not describe lossy output as lossless.
    - Update `doc/REFERENCE.md`: `SetOutput`, `Render`, MP4 applicability for
      inherited raster settings, unsupported settings and any approved new setter.
      Update `doc/INTRO.md` to include MP4 in the shared-GIF pipeline description.
    - Add one MP4 entry under the unreleased changelog's `### New` heading.
      Tick these checkboxes only after implementation and verification; leave
      the following roadmap items untouched.

- [ ] WebM output:
  - GIF to WebM conversion via `ffmpeg`.
  - Full chroma (4:4:4 chroma)?
  - Choose codec and parameters which are best fit for terminal recording content.
  - Update README output format section and install instruction for webp format.

- [ ] Update `SetOptimize` for video:
  - Is there any space for optimization without quality loss?
  - `High` profile?
  - Measured for MP4 (`doc/ENCODING.md`): `-preset veryslow` is the only knob
    that trades time for bytes with no quality loss - 5 % smaller for 2.4x the
    encoding time. Every other lever costs quality or bytes.

- [ ] Add `SUPPORT-MATRIX` to the README documentation section.

- [ ] Add note about compression efficiency:
  - use `logo` as example example.
  - SetOptimize on/off
  - Quality drop for video.
