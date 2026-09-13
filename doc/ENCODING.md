# Encoding Measurements

Measurements behind the selected MP4 encoding contract. Raster transcodes
receive one shared `agg` GIF, so decoded GIF pixels are the reference for
encoder damage. This does not measure colour or detail already lost when
rendering the cast to GIF.

## Reproducing the numbers

```bash
scripts/encoding-bench.sh [--timing] [work-dir]  # default work dir:
                                                 # /tmp/s-vhs-encoding-bench
```

The script records `scripts/stress.rec.sh` if the work directory has no stress
GIF, then regenerates the encodes, timing fixtures and playback bundle.
`--timing` runs the timing tables alone, which need no encoder but `libx264`;
that is how another `ffmpeg` build is measured, by putting it first on `PATH`.
Put only `ffmpeg` there: frame `duration_time` reaches `ffprobe` in 6.1, so an
older probe reports no durations at all, and holding the probe constant keeps
the encoder the only variable.

These results use ffmpeg n8.1.2, x264 core 165 r3222 b35605a, x265 4.2 and
SVT-AV1 v4.1.0-dirty on an Intel i7-8650U. Encoding times are single wall-clock
observations, not repeated medians or portable speed guarantees.

### Measurement contracts

- **Pixels:** PSNR and SSIM in nonlinear 8-bit RGB, aligned by frame index,
  after verifying equal decoded frame counts. Padding is cropped off *after*
  RGB reconstruction. The explicit reconstruction is
  `scale=flags=full_chroma_int+accurate_rnd,format=rgb24`; the reference GIF is
  simply decoded to RGB. Frame synchronization cannot silently repeat a missing
  frame. `inf` is additionally checked with per-frame RGB `framemd5` hashes.

- **Colour assumptions:** rewrite H.264 VUI and MP4 matrix/range tags without
  re-encoding. Verify the new tags and unchanged raw YUV frame hashes before
  decoding. `setparams=range=tv` alone is insufficient for decoded `yuvj*`
  formats: their full-range interpretation survives it.

- **Timing:** separate from pixel scores. Compare every presentation timestamp
  and decoded sample duration, the last sample's end, and container duration.
  Accept at most **1 ms** error for the one-to-one VFR candidate, less than a
  GIF's 10 ms tick. A different frame count is reported as `RESAMPLED`, not an
  indexed quality/timing match. CFR results report size and duration, not
  frame-index PSNR against the unduplicated GIF.

- **Limits:** these are whole-frame, equally frame-weighted scores, not
  duration-weighted scores or measurements confined to glyphs. Large flat
  backgrounds can conceal local text damage. RGB comparison does not apply a
  display transfer function or validate colour-managed browser appearance.

## Inputs

| Input               | Dimensions | Bytes   | Frames | Duration | Content                                                                                                                          |
| ------------------- | ---------- | ------- | ------ | -------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `stress.gif`        | 1224x696   | 447 311 | 222    | 28.85 s  | Small digits in 108 xterm palette colours, quantized truecolour gradient, a burst of 400 scrolled lines, `Highlight`, long holds |
| `examples/logo.gif` | 899x480    | 33 196  | 118    | 13.72 s  | Flat colour logo, odd width, 8 s final frame                                                                                     |

These two clips are useful contrasts, not a representative corpus of all
fonts, themes, terminal applications or recording lengths.

## 1. Codec matrix

`stress.gif`, GIF = 100 %. All encodes use one GIF pass,
`-fps_mode passthrough -enc_time_base 1:100` and faststart. Colour conversion
here is ffmpeg's implicit default, not the explicitly tagged contract pipeline
in later tables. GOP, B-frames and presets are encoder defaults unless stated.
**These pixel/size comparisons are not timing-qualified deliverable files.**

| Config                              | Bytes   | vs GIF | Time  | PSNR avg | PSNR min | SSIM   |
| ----------------------------------- | ------- | ------ | ----- | -------- | -------- | ------ |
| x264 4:2:0 crf14 medium             | 385 361 | 86 %   | 1.2 s | 38.87    | 36.79    | 0.9905 |
| x264 4:2:0 crf18 medium             | 320 045 | 72 %   | 1.2 s | 38.77    | 36.69    | 0.9905 |
| x264 4:2:0 crf20 medium             | 292 641 | 65 %   | 1.1 s | 38.69    | 36.61    | 0.9903 |
| x264 4:2:0 crf23 medium             | 253 295 | 57 %   | 1.7 s | 38.48    | 36.40    | 0.9901 |
| x264 4:2:0 crf28 medium             | 196 550 | 44 %   | 1.5 s | 37.78    | 35.75    | 0.9892 |
| x264 4:2:0 crf18 ultrafast          | 611 103 | 137 %  | 1.0 s | 38.79    | 36.81    | 0.9904 |
| x264 4:2:0 crf18 fast               | 306 029 | 68 %   | 1.9 s | 38.74    | 36.67    | 0.9904 |
| x264 4:2:0 crf18 veryslow           | 296 065 | 66 %   | 6.2 s | 38.76    | 36.69    | 0.9905 |
| x264 4:4:4 crf18 medium             | 337 841 | 76 %   | 2.4 s | 48.33    | 46.38    | 0.9994 |
| x264 4:4:4 crf23 medium             | 261 124 | 58 %   | 2.3 s | 45.23    | 43.43    | 0.9986 |
| x264 4:4:4 lossless (`-qp 0`)       | 499 126 | 112 %  | 2.2 s | 52.83    | 52.73    | 0.9999 |
| libx264rgb lossless                 | 778 422 | 174 %  | 2.5 s | inf      | inf      | 1.0000 |
| libx264rgb lossless veryslow        | 695 884 | 156 %  | 4.5 s | inf      | inf      | 1.0000 |
| x264 4:2:0 crf18 `-tune animation`  | 340 846 | 76 %   | 3.2 s | 38.82    | 36.74    | 0.9905 |
| x264 4:2:0 crf18 `-tune stillimage` | 332 403 | 74 %   | 1.6 s | 38.72    | 36.65    | 0.9903 |
| x264 4:2:0 crf18 `-bf 0`            | 340 641 | 76 %   | 1.4 s | 38.79    | 36.71    | 0.9905 |
| x265 4:2:0 crf20 medium             | 351 369 | 79 %   | 3.3 s | 38.41    | 36.52    | 0.9902 |
| x265 4:4:4 crf20 medium             | 382 036 | 85 %   | 4.6 s | 45.01    | 41.06    | 0.9979 |
| SVT-AV1 4:2:0 crf30 preset6         | 328 223 | 73 %   | 5.1 s | 38.84    | 36.79    | 0.9904 |
| SVT-AV1 4:2:0 crf20 preset6         | 456 335 | 102 %  | 5.1 s | 38.89    | 36.83    | 0.9905 |

- 4:2:0's conversion/subsampling damage dominates the stress clip's score at
  low CRFs. Lower CRF still reduces codec damage; it cannot restore discarded
  chroma. Neither greys nor whites are guaranteed bit-exact after conversion
  and lossy coding.

- 4:4:4 preserves substantially more coloured detail. RGB lossless is the
  bit-exact option **among the tested configurations**; YUV 4:4:4 lossless
  still includes RGB/YUV conversion error. Both use High 4:4:4 Predictive,
  unsuitable as a broadly compatible browser/hardware-decoding default, not
  intrinsically unplayable.

- On this stress recording, x265 4:2:0 is **110 % of x264 crf18's bytes** at
  0.36 dB lower PSNR; SVT-AV1 crf30 is **103 %**, at similar PSNR. These are
  percentages of x264, not of GIF. On the logo, x264 is 28 709 B, x265
  38 021 B, and AV1 25 835 B: **AV1 is 10 % smaller than x264**, while x265
  is 32 % larger. X264's case is encoding speed and compatibility, not winning
  every size comparison. Frame spacing and inferred nominal frame rate also
  change with a rerender, affecting rate control. This is a configuration
  probe, not a matched-quality rate-distortion study of the codecs.

- `veryslow` saves 7.5 % against `medium` on stress (13 % on the logo), with
  similar but not identical quality. Presets at the same CRF do not guarantee
  identical reconstruction. The tune probes do not demonstrate a compelling
  size/quality win. `-bf 0` costs 6.4 % on stress here, but has a timing benefit
  that the old pixel-only comparison missed.

## 2. Colour: matrix, range and reconstruction

`stress.gif`, crf18 medium, **B-frames off**, centisecond VFR. `RGB` uses the
explicit reconstruction above; `auto RGB` uses only `format=rgb24`, exposing
sensitivity to ffmpeg's implicit reconstruction. Both honour the file's tags.
The last two columns genuinely reinterpret unchanged YUV samples as limited
range under the indicated matrix.

| Config                 | Bytes   | RGB   | auto RGB | as 709/tv | as 601/tv |
| ---------------------- | ------- | ----- | -------- | --------- | --------- |
| Default untagged 4:2:0 | 340 641 | 38.79 | 38.75    | 38.51     | 38.79     |
| 4:2:0 BT.601 limited   | 342 271 | 38.92 | 38.61    | 38.00     | 38.92     |
| 4:2:0 BT.601 full      | 350 491 | 39.08 | 38.79    | 27.04     | 27.04     |
| 4:2:0 BT.709 limited   | 332 991 | 37.97 | 36.48    | 37.97     | 37.33     |
| 4:2:0 BT.709 full      | 348 851 | 38.31 | 37.49    | 26.33     | 26.08     |
| 4:4:4 BT.601 full      | 375 350 | 50.82 | 50.82    | 27.30     | 27.32     |
| 4:4:4 BT.709 full      | 375 189 | 47.41 | 47.41    | 26.60     | 26.35     |

Tagged rows use matrix `smpte170m` for BT.601 or `bt709` for BT.709, range
`tv` or `pc`, primaries `bt709` and transfer `iec61966-2-1` (sRGB). This
explicitly interprets the rendered GIF as sRGB, with no transfer-curve
conversion. Full-range streams decode as `yuvj420p` or `yuvj444p`. The untagged
row reports unknown colour metadata. Rerunning the affected measurements with
sRGB transfer tagging left their numerical results unchanged; the two real
clips also retained identical decoded YUV/RGB frame hashes and timing.

- BT.601 limited beats BT.709 limited by **0.96 dB** with explicit RGB
  reconstruction, versus 2.13 dB with implicit reconstruction. The result is
  specific to this input and conversion/reconstruction pipeline, not a
  universal terminal-text advantage attributable solely to luma coefficients.

- Misreading the BT.601 limited matrix costs 0.92 dB. Its score is then only
  0.04 dB above correctly decoded BT.709: too small to justify a general
  claim that wrong tags are harmless. Tag the conversion accurately.

- BT.601 full gains 0.16 dB for 2.4 % more bytes. Misreading it as limited
  drops the score to about 27 dB. **Full interpreted as limited crushes blacks
  and clips highlights**; the reverse error produces washed-out contrast.
  Limited range remains the conservative recommendation.

- Matrix, primaries and transfer are distinct. `scale` here changes the RGB/YUV
  matrix and range; `setparams` labels the result. It does not convert a
  transfer curve. The contract therefore keeps sRGB's transfer tag and its
  shared BT.709 primaries, rather than labelling unconverted sRGB samples as
  BT.709 transfer. The playback bundle retains the old BT.709 transfer tag as
  a same-pixel comparison. Colour-managed target-player verification remains
  required; RGB-number scores cannot validate display interpretation.

## 3. GOP policy

`stress.gif`, explicit BT.601 limited pipeline, crf18 medium, **`-bf 0`** and
centisecond VFR. These sizes supersede the old B-frame-on policy table.

| Policy                          | Bytes     | vs default | Keyframes |
| ------------------------------- | --------- | ---------- | --------- |
| Default (keyint 250 + scenecut) | 342 271   | 100 %      | 2         |
| `-g 120`                        | 421 029   | 123 %      | 3         |
| Keyframe every 10 s             | 560 366   | 164 %      | 4         |
| `-g 60`                         | 588 067   | 172 %      | 5         |
| Keyframe every 5 s              | 760 801   | 222 %      | 7         |
| `-g 30`                         | 854 259   | 250 %      | 9         |
| `-g 15`                         | 1 314 584 | 384 %      | 16        |
| All-intra (`-g 1`)              | 8 246 150 | 2409 %     | 222       |

All-intra costs 24.1x the default here. Even modest forced intervals cost
substantially more. Retain default keyint/scenecut unless actual seek-latency
measurements justify the extra bytes. No end-to-end seeking benchmark was
performed; decoding throughput alone cannot establish instant seeking on
long recordings, slower devices or network playback.

## 4. What CRF controls

Same explicit BT.601 limited, no-B-frame pipeline. A codec-lossless 4:2:0
round trip is 401 865 B and scores **39.10 dB** against stress. This is a
conversion reference, not bit-exact RGB and not a compatible High-profile
lossless-output proposal. RGB error against it estimates the additional codec
perturbation; it is not an additive decomposition of the GIF error.

| CRF | Bytes   | vs GIF | PSNR vs GIF | PSNR vs lossless 4:2:0 |
| --- | ------- | ------ | ----------- | ---------------------- |
| 14  | 418 442 | 94 %   | 39.02       | 55.84                  |
| 16  | 378 123 | 85 %   | 38.98       | 54.19                  |
| 18  | 342 271 | 77 %   | 38.92       | 52.77                  |
| 20  | 310 707 | 69 %   | 38.85       | 51.25                  |
| 23  | 265 806 | 59 %   | 38.66       | 48.90                  |

The logo's lossless round trip is 29 876 B at 50.12 dB. At crf18 it is
29 305 B (88 % of GIF), 47.62 dB against GIF and 51.32 dB against the round
trip. Crf20 is 25 556 B (77 %), crf23 is 23 195 B (70 %).

CRF 18 is a conservative working default, not a demonstrated universal knee
or proof of visual transparency. CRF 20 is a credible size trade-off to judge
on native-resolution text crops and a broader corpus before changing defaults.

## 5. Timing and geometry

Plain passthrough is not sufficient. With B-frames, the stress encode has all
222 frames and correct PTS with a 1/100 encoder time base, but its last
decoded sample lasts 0.04 s instead of 3 s. The last sample ends at 25.89 s;
the container reports 26.06 s rather than the GIF's 28.85 s. Some interior
sample-duration fields differ too; correct interior PTS can still preserve
visible holds, which is why both PTS
and durations are reported rather than inferring playback from either alone.

`stress.gif`, explicit colour pipeline, crf18 medium:

| Timing policy                     | Bytes       | Frames  | Max PTS error | Last sample | Last sample end | Container duration |
| --------------------------------- | ----------- | ------- | ------------- | ----------- | --------------- | ------------------ |
| VFR, B-frames, 1/100 time base    | 321 512     | 222     | 0 ms          | 0.04 s      | 25.89 s         | 26.06 s            |
| **VFR, `-bf 0`, 1/100 time base** | **342 271** | **222** | **0 ms**      | **3.00 s**  | **28.85 s**     | **28.85 s**        |
| CFR 30, B-frames                  | 512 424     | 866     | not indexed   | 1/30 s      | 28.867 s        | 28.867 s           |
| CFR 100, B-frames                 | 1 147 950   | 2885    | not indexed   | 0.01 s      | 28.85 s         | 28.85 s            |

No-B-frame VFR adds **6.5 %** over the tagged B-frame candidate on stress,
and **1.8 %** on the logo. CFR 100 preserves the centisecond grid and total
duration but costs 3.35x the no-B-frame VFR bytes on stress. CFR 30 rounds the
timeline and can drop a 10 ms frame; its end-time error is 16.7 ms on stress
and 13.3 ms on the logo. CFR's final hold is spread over duplicate frames, so
its last *sample* duration is not the total final visible hold.

Disabling B-frames alone is insufficient too: ffmpeg's default encoder time
base gives the short-delay fixture up to **8.519 ms** PTS/duration error.
On this stress recording the automatic-time-base probes, with or without
B-frames, collapse timestamps and abort under `-xerror` with non-monotonic DTS.
Their partial files are rejected. Set `-enc_time_base 1:100` explicitly.
With this and `-bf 0`, all six inputs pass the 1 ms bound, with **zero measured PTS, sample-duration and container
end error**, no duplicated or dropped frames, including 3.21/6/8 s final holds.
These are ffmpeg/probe checks, not independent player verification.

4:2:0 requires even dimensions. Padding the logo from 899x480 to **900x480**,
and synthetic fixtures from 65x33 to **66x34**, keeps original pixels at the
top left. Use `pad=ceil(iw/2)*2:ceil(ih/2)*2:0:0` before colour conversion;
report the padded geometry. Padding avoids resizing/cropping but does not
prevent 4:2:0 filtering from mixing colour at the added boundary. 4:4:4 and
RGB take the original odd dimensions.

## 6. Playback

Manual playback results reported for `<work-dir>/playback/index.html`:

| Sample | Encoding / variant                                                | Chrome        | Firefox       |
| ------ | ----------------------------------------------------------------- | ------------- | ------------- |
| `a`    | **Selected contract:** H.264 4:2:0, BT.601 limited, sRGB transfer | Plays         | Plays         |
| `b`    | H.264 4:2:0, BT.709 limited, sRGB transfer                        | Plays         | Plays         |
| `c`    | H.264 4:2:0, BT.601 full, sRGB transfer                           | Plays         | Plays         |
| `d`    | H.264 4:4:4, BT.601 full, sRGB transfer                           | Plays         | Does not play |
| `e`    | H.264 RGB lossless (`libx264rgb`)                                 | Does not play | Does not play |
| `f`    | Same pixels as `a`, BT.709 transfer tag instead                   | Plays         | Plays         |
| `g`    | Selected colour pipeline, CFR 30, B-frames on                     | Plays         | Plays         |
| `h`    | Selected colour pipeline, CFR 100, B-frames on                    | Plays         | Plays         |

The selected 4:2:0 output plays in both tested browsers. The failures of
4:4:4/RGB alternatives support excluding them from the compatibility-focused
default. RGB lossless still decodes successfully in ffmpeg/VLC and passes frame
hashes; these browser failures do not make it universally unplayable.

## 7. FFmpeg versions

Every table above comes from n8.1.2. The contract was then re-measured under
static 5.1.1, 6.0.1, 6.1.2 and 7.0.2 builds, encoding with each while probing
with one n8.1.2 `ffprobe`. This used a re-recorded stress clip (344 frames,
33.97 s), so its byte counts are not comparable with the tables above.

| Build  | `out_color_matrix=bt470bg` | Stress last sample | Logo last sample | Timing fixtures |
| ------ | -------------------------- | ------------------ | ---------------- | --------------- |
| 4.4.1  | rejected                   | no `-fps_mode`     | no `-fps_mode`   | not run         |
| 5.1.1  | rejected                   | 0.01 s             | 0.01 s           | FAIL            |
| 6.0.1  | rejected                   | 0.01 s             | 0.01 s           | FAIL            |
| 6.1.2  | rejected                   | 3.00 s             | 8.00 s           | PASS            |
| 7.0.2  | rejected                   | 3.00 s             | 8.00 s           | PASS            |
| 8.1.2  | accepted                   | 3.00 s             | 8.00 s           | PASS            |

- **`-fps_mode` needs 5.1** (added 2022-06-07). It is the newest option in the
  contract: `-enc_time_base` dates to 3.4, everything else predates 3.0. The
  deprecated `-vsync passthrough` would reach further back but is marked for
  removal, and the next result makes the extra reach moot.

- **Preserving the final hold needs 6.1.** Under 5.1.1 and 6.0.1 every
  timestamp is still exact, but the last sample collapses to one GIF tick:
  stress ends at 30.98 s instead of 33.97 s and the logo at 5.73 s instead of
  13.72 s, losing a 3 s and an 8 s hold. 6.1 is also where `ffprobe` starts
  reporting frame durations, consistent with frame durations only being
  carried end to end from that release. The tested build is a `n6.1.2-16`
  snapshot, so the boundary is the 6.1 series rather than a verified `n6.1.0`.

- **Name the matrix `bt601`, not `bt470bg`.** No build before 8 knows that
  name - `out_color_matrix` takes a string list through 6.1 and an enumeration
  in 7.0 - and 7.0.2 rejects it outright;
  `bt601` is accepted by every tested build. All three names select the same
  matrix, and `bt470bg`, `bt601` and `smpte170m` produce identical `framemd5`
  hashes on 8.1.2, so the tables above keep their values unchanged.

The minimum is therefore **FFmpeg 6.1**, which excludes Ubuntu 22.04 LTS (4.4)
and Debian 12 (5.1); Ubuntu 24.04 (6.1) and current Homebrew, Arch and Fedora
satisfy it. Only the timing acceptance checks were repeated per version: pixel
scores, GOP sizes and player playback were not.

## The MP4 contract

These are the selected settings for MP4 implementation:

- **Codec:** `libx264`, 8-bit `yuv420p`, `-profile:v high`,
  `-crf 18 -preset medium`. Output is lossy, with 4:2:0 chroma subsampling.

- **Input:** decode exactly one GIF pass with `-ignore_loop 1 -min_delay 0`.
  Preserve the decoded GIF timeline; do not apply recording speed or hold
  settings a second time in the encoder.

- **Timing:** `-bf 0 -fps_mode passthrough -enc_time_base 1:100`.
  Preserve frame count, presentation timestamps and sample durations,
  including the final hold, within 1 ms of the decoded GIF reference. No CFR
  duplication. Revalidate on supported ffmpeg versions, including zero-delay
  GIF decoding.

- **GOP:** default keyint/scenecut (maximum keyint 250), with B-frames disabled
  as above. No forced periodic keyframes or all-intra encoding.

- **Geometry:** `pad=ceil(iw/2)*2:ceil(ih/2)*2:0:0` before colour conversion.
  Pad the right/bottom by at most one black pixel each; do not resize or crop
  the source. Report the padded output dimensions.

- **Colour conversion:** interpret the rendered GIF as sRGB; preserve its
  transfer curve. Convert to BT.601 limited-range YUV with
  `scale=out_color_matrix=bt601:out_range=tv:flags=full_chroma_int+accurate_rnd`,
  followed by `format=yuv420p`. Do not spell the matrix `bt470bg`: it selects
  the same conversion but only exists from ffmpeg 8.

- **Colour tags:** matrix `smpte170m`, primaries `bt709` (shared with sRGB),
  transfer `iec61966-2-1` (sRGB), range `tv`. These are independent properties;
  using a BT.601 matrix does not require a BT.601 transfer curve or primaries.

- **Container:** MP4 with `-movflags +faststart` and `-an` (no audio track).
  Leave H.264 level selection to the encoder. Looping is player-controlled,
  not a portable MP4-file setting.

- **Toolchain:** FFmpeg **6.1** or newer. 5.1 is the floor for `-fps_mode`,
  but 5.1 and 6.0 silently drop the final hold to a single GIF tick.

- **No lossless MP4 mode:** tested RGB lossless costs 174 % of stress GIF and
  fails in both tested browsers; WebP already covers lossless raster output.
