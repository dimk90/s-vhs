# Encoding Measurements

Measurements behind the selected MP4 and WebM contracts (WebM from section 9
on). Raster transcodes receive one shared `agg` GIF, so decoded
GIF pixels are the reference for encoder damage. This does not measure colour
or detail already lost when rendering the cast to GIF.

## Reproducing the numbers

```bash
scripts/encoding-bench.sh [--timing|--presets|--webm|--webm-timing|--webm-holds] [work-dir]
# default work dir: /tmp/s-vhs-encoding-bench
```

The script records `scripts/stress.rec.sh` if the work directory has no stress
GIF, then regenerates the encodes, timing fixtures and playback bundle.
`--timing` runs the timing tables alone, which need no encoder but `libx264`;
that is how another `ffmpeg` build is measured, by putting it first on `PATH`.
Put only `ffmpeg` there: frame `duration_time` reaches `ffprobe` in 6.1, so an
older probe reports no durations at all, and holding the probe constant keeps
the encoder the only variable.

`--webm` runs the WebM matrix, the quality, speed, chroma and screen-content
ladders, the GOP, seeking, geometry, timing and held-frame checks, then
writes `playback-webm/index.html` and `playback-webm-holds/index.html`. It
needs `libx264` for the reference, plus `libvpx-vp9`, `libaom-av1` and
`libsvtav1`. `--webm-holds` runs the held-frame table and its bundle alone,
with `libx264` and `libaom-av1`.
`--webm-timing` needs only VP9 and libaom; it skips SVT rows when unavailable.
Its libaom candidates must meet the timing bound; a failing older build stops
at the first rejected input. The full run includes both containers.
Use a persistent work directory to retain the exact GIF and reports across
reboots; re-recordings are not byte-comparable. Encoder logs are saved beside
each output. Capture the table output separately, for example:

```bash
scripts/encoding-bench.sh --webm "$HOME/s-vhs-bench" >"$HOME/webm.log" 2>&1
```

The MP4 tables use ffmpeg n8.1.2, x264 core 165 r3222 b35605a, x265 4.2 and
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
  duration-weighted scores or measurements confined to glyphs. Section 15
  shows the damage this missed and adds one held-frame check. Large flat
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

## 8. Optimization presets

What `SetOptimize` can buy on the contract pipeline: the same crf 18, `-bf 0`,
`-profile:v high` and colour conversion, with x264 given more search time.
The codec column measures each preset against a lossless 4:2:0 round trip of
the same input, separating a preset's own coding damage from the conversion
damage every row shares. Section 1's preset rows are superseded: they ran with
B-frames on and implicit colour, where `veryslow`'s gain comes largely from
B-frame adaptivity.

This ladder ran on a re-recorded stress clip (222 frames, 449 781 B), so its
byte counts are not comparable with the tables above; section 3's matching
row was 342 271 B.

| Preset       | `stress` bytes | vs medium | Time  | PSNR vs GIF | PSNR vs 4:2:0 |
| ------------ | -------------- | --------- | ----- | ----------- | ------------- |
| medium       | 346 425        | 100 %     | 1.0 s | 38.94       | 52.65         |
| slow         | 348 016        | 100 %     | 1.3 s | 38.95       | 52.90         |
| slower       | 339 996        | 98 %      | 1.5 s | 38.96       | 53.22         |
| **veryslow** | **310 505**    | **90 %**  | 1.9 s | **38.94**   | **52.66**     |
| placebo      | 309 805        | 89 %      | 8.6 s | 38.96       | 53.04         |

| Preset       | `logo` bytes | vs medium | Time  | PSNR vs GIF | PSNR vs 4:2:0 |
| ------------ | ------------ | --------- | ----- | ----------- | ------------- |
| medium       | 29 305       | 100 %     | 0.4 s | 47.62       | 51.32         |
| slow         | 28 200       | 96 %      | 0.4 s | 47.95       | 52.06         |
| slower       | 26 853       | 92 %      | 0.5 s | 47.93       | 52.05         |
| **veryslow** | **23 380**   | **80 %**  | 0.6 s | **48.00**   | **52.19**     |
| placebo      | 22 583       | 77 %      | 3.0 s | 48.07       | 52.38         |

- **`veryslow` saves 10 % on stress and 20 % on the logo** without spending
  quality: its codec score is 0.01 dB above `medium` on stress and 0.87 dB
  above it on the logo. Equal CRF still does not guarantee equal
  reconstruction, and these are two clips, not a corpus: a third, short
  recording came out 13 % smaller at 0.13 dB *below* its unoptimized encode.
  The claim is the same quality target and no systematic loss, not identical
  pixels.

- **It costs 1.9x the encoding time on stress and 1.5x on the logo**, far less
  than the 5x of the B-frame-on probe: with `-bf 0` the adaptive B-frame
  decision that dominated `veryslow` there is not made at all.

- **`placebo` is not worth it**: 1 % more on stress and 3 % more on the logo,
  for 4.5-5x the encoding time.

- **Preset order is not monotonic in size.** `slow` lands 0.5 % *above*
  `medium` on stress while scoring higher. Rate control targets quality, not
  bytes; a preset ladder is a per-clip result.

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

- **Optimization:** `SetOptimize 'on'` raises the preset to `-preset veryslow`
  and changes nothing else. The output is re-encoded, not repacked: the
  quality target holds, the bits do not.

- **No lossless MP4 mode:** tested RGB lossless costs 174 % of stress GIF and
  fails in both tested browsers; WebP already covers lossless raster output.

## 9. WebM: codec and chroma candidates

This round uses a **new stress GIF**: 1224x696, 220 frames, 28.70 s,
451 846 B (`cksum` CRC 3175447635). The unchanged logo is 899x480,
118 frames, 13.72 s, 33 196 B (CRC 126015574). The MP4 reference is re-encoded
from these same GIFs; do not compare stress byte counts with sections 1–8.
The machine is still an i7-8650U. Builds: FFmpeg n8.1.2, libvpx 1.16.0,
libaom 3.14.1, SVT-AV1 v4.1.0-dirty.

All candidates use one GIF pass, centisecond passthrough VFR and no audio.
YUV uses the explicit BT.601 limited/sRGB pipeline from the MP4 contract;
4:2:0 rows pad to even dimensions for comparison, 4:4:4/RGB do not.
VP9 uses `-b:v 0 -row-mt 1` and its default good deadline/cpu-used 1.
libaom uses `-b:v 0 -row-mt 1 -cpu-used 5`, SVT preset 6. These are
single-pass quality probes, **not matched-quality codec rankings**. In
particular, equal CRF numbers do not mean equal quality across encoders.

| Configuration                       | Stress bytes | RGB PSNR | Logo bytes | RGB PSNR |
| ----------------------------------- | -----------: | -------: | ---------: | -------: |
| Shipped H.264 contract              |      346 780 |    38.93 |     29 305 |    47.62 |
| VP9 4:2:0 CRF 28                    |      837 001 |    38.50 |     36 257 |    47.79 |
| VP9 4:2:0 CRF 32                    |      755 367 |    38.16 |     33 583 |    46.76 |
| VP9 4:4:4 CRF 32                    |      960 838 |    45.50 |     36 966 |    48.78 |
| SVT-AV1 4:2:0 CRF 32 (timing fails) |      332 316 |    38.93 |     24 086 |    49.29 |
| libaom AV1 4:2:0 CRF 24             |      136 334 |    38.96 |     17 917 |    49.68 |
| libaom AV1 4:2:0 CRF 32             |      113 661 |    38.77 |     17 099 |    49.15 |
| libaom AV1 4:4:4 CRF 32             |      131 872 |    48.80 |     17 386 |    52.93 |

libaom is the leading encoder in this build: its CRF 24 4:2:0 output costs
**39 % of the MP4 bytes** on stress and 61 % on the logo, with slightly higher
RGB PSNR on stress and 2.06 dB higher on the logo. CRF 32 cuts stress to 33 %
of MP4 bytes at 0.16 dB lower PSNR. These are percentages of MP4, not GIF.
SVT-AV1's attractive pixel scores do not qualify its shortened files for use
(section 13).

**Do not generalize the poor VP9 result to all versions.** The version probes
produced 217 026 B for stress and 18 080 B for the logo under the 7.0.2 static
build, versus 755 367/33 583 B here, with correct timing in both. Those builds
change the codec libraries as well as FFmpeg; quality was not remeasured, so
neither a regression diagnosis nor a cross-version codec ranking is established.
VP9's `-tune-content screen` produced the same sizes and scores as its default
in this round; two-pass VP9 and broader VP9 tuning remain unmeasured. libaom's
screen-content tuning does change its output (section 11).

## 10. WebM: quality and full chroma

libaom, cpu-used 5, same explicit colour pipeline. The codec PSNR column
compares against a **hash-verified codec-lossless 4:2:0 reference**, not RGB
lossless. That conversion reference scores 39.12 dB on stress and 50.12 dB
on the logo. Whole-frame scores still conceal local glyph damage.

| CRF | Stress bytes | vs GIF PSNR | vs 4:2:0 PSNR | Logo bytes | vs GIF PSNR | vs 4:2:0 PSNR |
| --- | -----------: | ----------: | ------------: | ---------: | ----------: | ------------: |
| 24  |      136 334 |       38.96 |         52.78 |     17 917 |       49.68 |         59.23 |
| 28  |      120 717 |       38.88 |         51.11 |     17 299 |       49.37 |         57.17 |
| 32  |      113 661 |       38.77 |         49.42 |     17 099 |       49.15 |         55.81 |
| 36  |      100 816 |       38.63 |         47.93 |     16 346 |       48.97 |         54.54 |
| 40  |       92 867 |       38.38 |         46.19 |     16 423 |       48.48 |         53.12 |

Full chroma removes the dominant subsampling damage without removing RGB/YUV
conversion or codec damage. AV1 calls this **High profile** (profile 1), not
H.264's High profile. This build of SVT-AV1 exposes only 4:2:0 pixel formats;
the AV1 4:4:4 measurements use libaom, which actually decodes as `yuv444p`.

| CRF | Stress 4:2:0 bytes / PSNR | Stress 4:4:4 bytes / PSNR | Logo 4:2:0 bytes / PSNR | Logo 4:4:4 bytes / PSNR |
| --- | ------------------------- | ------------------------- | ----------------------- | ----------------------- |
| 24  | 136 334 / 38.96           | 160 574 / 50.70           | 17 917 / 49.68          | 18 756 / 53.32          |
| 28  | 120 717 / 38.88           | 140 772 / 49.77           | 17 299 / 49.37          | 17 776 / 53.17          |
| 32  | 113 661 / 38.77           | 131 872 / 48.80           | 17 099 / 49.15          | 17 386 / 52.93          |
| 36  | 100 816 / 38.63           | 115 484 / 47.53           | 16 346 / 48.97          | 17 048 / 52.57          |

At CRF 32, 4:4:4 costs **16 % more** on stress and 2 % on the logo, gaining
10.03/3.78 dB. Its worst-frame stress PSNR is 43.19 dB, not the 48.80 dB
average. At CRF 24 those figures improve to 46.15/50.70 dB for 22 % more
bytes than CRF 32 4:4:4. CRF 32 is the size-oriented candidate and CRF 24 the
more conservative quality candidate; neither is proved visually transparent.
**Playback, software-decoding cost and native-resolution text inspection must
settle the profile/CRF decision**, not these scores alone.

### Requested lossless modes

| Configuration                                    | Stress bytes | Logo bytes | RGB frame hashes                  |
| ------------------------------------------------ | -----------: | ---------: | --------------------------------- |
| VP9 YUV 4:4:4 lossless                           |    2 147 114 |     58 946 | Not RGB-exact; conversion remains |
| VP9 RGB lossless                                 |    3 401 803 |     92 404 | Match both GIFs                   |
| libaom YUV 4:4:4, `lossless=1`, cpu-used 5       |      673 262 |     38 535 | Not RGB-exact                     |
| libaom RGB, `lossless=1`, cpu-used 5             |    1 066 701 |     63 814 | **Differ on both GIFs**           |
| libaom RGB, `lossless=1`, cpu-used 5, no filter  |    1 077 883 |     62 364 | Match both GIFs                   |
| libaom RGB, `lossless=1`, cpu-used 6             |    1 058 802 |     65 242 | Match both GIFs                   |

The cpu-used 5 RGB probe scores 86.94/93.29 dB and rounds to SSIM 1.000000,
but fails per-frame RGB hashes. On stress, 16 of 220 frames differ, nearly all
at multiples of 8. libdav1d and libaom's own decoder return the same pixels,
so the stream itself is not lossless. Turning off the alt-ref temporal filter
(`-arnr-strength 0`, the "no filter" row), with nothing else changed, makes
cpu-used 5 bit-exact on both GIFs: in this build, the requested lossless mode
still shows filtered alt-ref frames. The benchmark reports the default
mismatch without accepting it as lossless; hashing/decoding errors still fail
the run. The matching libaom files cost 188–239 % of GIF and VP9's 278–753 %,
so lossless WebM is not the size winner here.
RGB probes carry `gbr`/full-range tags but unknown primaries/transfer; they
are pixel-exact experiments, not colour-managed playback validation.

## 11. WebM: encoding effort

libaom, CRF 32, 4:2:0. One speed sweep; seconds are single observations.
Later reruns varied substantially (for example, stress cpu-used 5 took
9–25 s), so these are not reliable throughput guarantees or repeated medians.

| cpu-used | Stress bytes |  PSNR |    Time | Logo bytes |  PSNR |   Time |
| -------- | -----------: | ----: | ------: | ---------: | ----: | -----: |
| 6        |      148 378 | 38.67 |   7.5 s |     22 145 | 48.75 |  3.0 s |
| 5        |      113 661 | 38.77 |  11.1 s |     17 099 | 49.15 |  4.0 s |
| 4        |      167 327 | 38.89 |  22.2 s |     17 199 | 49.38 |  7.8 s |
| 3        |      162 059 | 38.90 |  43.9 s |     16 646 | 49.35 |  9.3 s |
| 2        |      142 616 | 38.92 |  96.8 s |     12 313 | 49.51 | 14.2 s |
| 1        |      143 189 | 38.95 | 143.1 s |     15 432 | 49.30 | 30.8 s |

CPU-used 5 saves about 23 % against 6 on both inputs while scoring higher,
for roughly 1.3–1.5x the time in this sweep. It is the proposed base effort.
Lower numbers do **not** guarantee smaller files: cpu-used 2 improves the
logo substantially but makes stress 25 % larger than 5. Equal CRF does not
hold reconstruction fixed. There is no selected `SetOptimize` mapping from
this table; that remains a separate task, especially if 4:4:4 becomes the
default. Good-quality usage accepts cpu-used 0..6 only: an earlier cpu-used 8
row was byte-identical to 6. CPU-used 0 was not measured.

### Screen-content tuning

libaom decides on its own whether a frame is screen content, which enables
its palette and intra block copy tools. `-aom-params tune-content=screen`
forces that decision. CRF 32, same pipeline; bytes / RGB PSNR:

| Configuration      | Stress default   | Stress screen    | Logo default    | Logo screen     |
| ------------------ | ---------------- | ---------------- | --------------- | --------------- |
| 4:2:0, cpu-used 6  | 148 378 / 38.67  | 111 483 / 38.75  | 22 145 / 48.75  | 16 514 / 49.09  |
| 4:2:0, cpu-used 5  | 113 661 / 38.77  | 110 450 / 38.77  | 17 099 / 49.15  | 16 136 / 49.12  |
| 4:2:0, cpu-used 4  | 167 327 / 38.89  | 115 881 / 38.84  | 17 199 / 49.38  | 17 157 / 49.34  |
| 4:4:4, cpu-used 5  | 131 872 / 48.80  | 124 073 / 48.76  | 17 386 / 52.93  | 17 375 / 52.93  |

- **Forcing it removes most of the effort-dependent swings.** Default stress
  sizes range from 113 661 to 167 327 B across cpu-used 4–6; tuned, from
  110 450 to 115 881 B. This fits the encoder reaching a different
  screen-content decision at different efforts; the decision itself was not
  observed.

- **At cpu-used 5 it is a small, consistent saving:** 2.8 % on stress and
  5.6 % on the logo in 4:2:0, 5.9 % and 0.1 % in 4:4:4, with average PSNR
  within 0.04 dB. The 4:4:4 stress worst frame improves from 43.19 to
  44.24 dB. These are two clips at one CRF, not a general guarantee.

- **Time:** four reruns at cpu-used 5 took 10.1–13.9 s on stress, against
  9.0–11.6 s untuned. A first observation of 80.9 s did not reproduce.

- `screen-detection-mode=2`, the detector meant for anti-aliased text, left
  cpu-used 5 and 6 byte-identical to the default and saved 4 % on stress at
  cpu-used 4. It is not proposed.

## 12. WebM: GOP, seeking and geometry

libaom, cpu-used 5, CRF 32, 4:2:0, stress. The counts are key-marked packets.
They equal the decoded keyframes in every file here, and in the H.264 files of
section 3, where they also match `ffprobe -skip_frame nokey`; that option did
not filter VP9.

| Policy            |     Bytes | vs default | Keyframes |
| ----------------- | --------: | ---------: | --------: |
| Encoder defaults  |   113 661 |      100 % |         1 |
| `-g 120`          |   209 245 |      184 % |         3 |
| `-g 60`           |   287 324 |      253 % |         5 |
| Force every 10 s  |   298 180 |      262 % |         6 |
| `-g 30`           |   448 315 |      394 % |         9 |
| Force every 5 s   |   522 530 |      460 % |        13 |
| `-g 15`           |   690 234 |      607 % |        16 |
| `-usage allintra` | 2 692 572 |     2369 % |       220 |

The force expressions do not produce one keyframe per requested interval:
every 10 s gives keyframes at 0.00/0.19, 12.96/13.01 and 20.07/20.12 s, in
pairs on consecutive frames. These are measured counts, not a guaranteed seek
cadence. The local libaom/FFmpeg pipeline crashed with `-g 1` and `-g 2`; the
all-intra row uses the successful `-usage allintra` probe instead, which also
changes encoding mode.

### Seeking on a longer recording

libaom's default maximum keyframe interval is 9999 frames, against x264's 250,
so no clip of 250 frames or fewer can tell them apart. This probe loops stress
three times into one GIF: 660 frames, 86.10 s. It is quantized to one shared
256-colour palette, so its pixels and bytes are not comparable with stress.
The seek time is ffmpeg (libdav1d) seeking to and decoding the last frame,
single observations from two runs:

| Policy           |   Bytes | vs default | Keyframes | Longest interval    | Seek to last frame |
| ---------------- | ------: | ---------: | --------: | ------------------- | -----------------: |
| Encoder defaults | 318 903 |      100 % |         1 | 660 frames, 86.10 s |        1.37–1.43 s |
| `-g 250`         | 409 578 |      128 % |         4 | 250 frames, 33.17 s |        0.18–0.20 s |

With the default, a recording usually has a single keyframe, and every seek
decodes from the start: the cost grows with the recording's length. `-g 250`
bounds it the way the MP4 contract does, for 28 % more bytes here and no
extra keyframe on a clip of 250 frames or fewer. The selected contract takes
`-g 250`, at 8 % with its own settings (section 15).

Remuxing the default file with and without `-cues_to_front 1` gives 318 428 B
both ways: moving the seek index (Cues) to the front costs no bytes here. A
WebM player needs the Cues only to seek, while an MP4 player needs `moov`
before the first frame, so this is not an equivalent of faststart by default.
Its effect on startup over a network was not measured; muxer defaults stay.

Unlike the shipped H.264 path, **both tested WebM codecs accept odd 4:2:0
dimensions**. The unpadded logo remains 899x480: VP9 CRF 32 is 33 733 B at
46.83 dB; libaom cpu-used 5 CRF 32 is 17 259 B at 49.07 dB. Padding changes
boundary filtering and rate control, so the padded logo tables do not describe
the exact unpadded candidate. AV1 High/4:4:4 already keeps the source geometry.
The timing checks also cover unpadded 65x33 fixtures; no resizing or cropping
is needed for the selected WebM path.

## 13. WebM: timing and version floor

The same 1 ms bound applies to every PTS, decoded sample duration and container
end, with no duplicated or dropped frames. Current-build libaom cpu-used 5
passes for padded 4:2:0, native-sized 4:2:0 and native-sized 4:4:4, all at
CRF 32, and for both native-sized formats with `tune-content=screen`. VP9 also
passes. SVT-AV1 preset 6 keeps PTS but substitutes nominal sample durations
and loses the final hold:

| Input          | Frames | Reference end | Final hold | libaom / VP9 max PTS & duration error | SVT final sample | SVT file end |
| -------------- | -----: | ------------: | ---------: | ------------------------------------: | ---------------: | -----------: |
| stress         |    220 |       28.70 s |     3.00 s |                                  0 ms |          0.050 s |     25.750 s |
| logo           |    118 |       13.72 s |     8.00 s |                                  0 ms |          0.010 s |      5.730 s |
| delays         |      5 |        9.07 s |     3.00 s |                                  0 ms |          0.018 s |      6.089 s |
| single         |      1 |        3.21 s |     3.21 s |                                  0 ms |          0.010 s |      0.010 s |
| slowed         |      5 |       18.14 s |     6.00 s |                                  0 ms |          0.010 s |     12.150 s |
| zero-delay GIF |      1 |        0.10 s |     0.10 s |                                  0 ms |          0.010 s |      0.010 s |

libaom/VP9 container ends also match exactly. The zero-delay row compares
against FFmpeg's normalized GIF decode, not a hypothetical zero-length video.
SVT's `pred-struct=1:lookahead=0` does not fix its timing in this build.
libaom `-lag-in-frames 0` passes timing but changes pixels: the earlier
cpu-used 6 logo probe fell from 48.75 to 46.10 dB, and stress from 38.67 to
37.21 dB. Do not disable lookahead just because it saves bytes. No H.264
`-bf 0` option is carried into this WebM candidate.

Version runs used **only the encoder executable** from each older build on
PATH, keeping n8.1.2 `ffprobe`. Initial libaom probes used cpu-used 6, CRF 32
and padded 4:2:0:

| FFmpeg build    | Stress final sample | Stress file end | Coverage / verdict      |
| --------------- | ------------------: | --------------: | ----------------------- |
| 5.1.1 static    |             0.012 s |        25.713 s | FAIL; stopped at stress |
| 6.0.1 static    |             0.012 s |        25.710 s | FAIL; stopped at stress |
| n6.1.3-20250831 |             3.000 s |        28.700 s | PASS, all six inputs    |
| 7.0.2 static    |             3.000 s |        28.700 s | PASS, all six inputs    |
| n8.1.2          |             3.000 s |        28.700 s | PASS, all six inputs    |

The proposed floor is **FFmpeg 6.1**, as for MP4; 6.1.0 itself was not tested.
The 6.1.3 and 7.0.2 builds were additionally checked at cpu-used 5 for all six
inputs in padded 4:2:0, native-sized 4:2:0 and 4:4:4, and in both native-sized
formats with `tune-content=screen`: all pass. Their libaom versions are 3.12.1
and 3.2.0; both accept the screen tuning, which saved 3.1 % and 0.1 % on native
4:2:0 stress there. Pixel quality, compression and browser decoding were not
version-qualified. The static 5.1.1, 6.0.1 and 7.0.2 builds came from
[John Van Sickle](https://johnvansickle.com/ffmpeg/old-releases/);
[6.1.3 came from BtbN](https://github.com/BtbN/FFmpeg-Builds/releases/tag/autobuild-2025-08-31-13-00).
They contain different codec-library versions, not an isolated FFmpeg-only
experiment.

## 14. WebM: playback gate

`<work-dir>/playback-webm/index.html` contains the actual measured encodes: the
stress clip for samples a–l, the 899x480 logo for m and n. The checked bundle
was rebuilt from a re-recorded stress GIF (450 120 B, 220 frames, 28.83 s,
CRC 1147481604), so its stress sizes differ slightly from sections 9–13; the
logo samples are unchanged.

Checked on 2026-10-15 in current stable Chrome and Firefox on Windows, with
default hardware-decoding settings; exact versions were not recorded. Both
browsers gave the same result for every sample. "Dark lines lost" means the
faint text of section 15 is missing from the 4 s hold at 16.16 s.

| Sample | Encoding                                                   | Playback status                                |
| ------ | ---------------------------------------------------------- | ---------------------------------------------- |
| a      | VP9 4:2:0 CRF 32                                           | Plays, seeks, full final hold; dark lines lost |
| b      | VP9 4:4:4 CRF 32                                           | Plays, seeks, full final hold; dark lines lost |
| c      | VP9 YUV 4:4:4 lossless                                     | Plays, seeks, full final hold                  |
| d      | VP9 RGB lossless, hash-verified                            | Plays, seeks, full final hold                  |
| e      | libaom AV1 4:2:0 CRF 32, cpu-used 5                        | Plays, seeks, full final hold; dark lines lost |
| f      | libaom AV1 4:4:4 CRF 32, cpu-used 5                        | Plays, seeks, full final hold; dark lines lost |
| g      | libaom AV1 RGB lossless, cpu-used 6, hash-verified         | Plays, seeks, full final hold                  |
| h      | Shipped H.264 contract, same GIF                           | Reference; plays, seeks, full final hold       |
| i      | libaom AV1 4:2:0 CRF 24, cpu-used 5                        | Plays, seeks, full final hold; dark lines lost |
| j      | libaom AV1 4:4:4 CRF 24, cpu-used 5                        | Plays, seeks, full final hold; dark lines lost |
| k      | libaom AV1 4:2:0 CRF 32, cpu-used 5, `tune-content=screen` | Plays, seeks, full final hold; dark lines lost |
| l      | libaom AV1 4:4:4 CRF 32, cpu-used 5, `tune-content=screen` | Plays, seeks, full final hold; dark lines lost |
| m      | libaom AV1 4:2:0 CRF 32, cpu-used 5, logo at odd 899x480   | Plays, seeks, full final hold                  |
| n      | libaom AV1 4:4:4 CRF 32, cpu-used 5, logo at odd 899x480   | Plays, seeks, full final hold                  |

Both browsers decode VP9 profile 1, AV1 High profile (4:4:4) and the odd-sized
logo. The stress clip is too short to tell the keyframe policies apart, so
these seeks do not decide it. Every lossy stress sample fails one visual check
that no score had caught; section 15 measures and fixes it. Safari, mobile and
other players remain unchecked.

## 15. WebM: faint text on held frames

After its 400-line scroll, the stress clip holds one frame for 4 s, from 16.16
to 20.16 s. Every eighth line on it is ANSI black, which the theme draws as
dark grey on a dark background: faint in the GIF, but readable. Every lossy
WebM in section 14 shows that frame without those lines; the next frame, at
20.21 s, brings them back. The GIF, the MP4 and the lossless samples keep them.

The frame-averaged scores could not show this: one 4 s frame weighs as much as
any 30 ms one. CRF 32 averages 38.77 dB with and without the fix below, and
the held frame's own PSNR in 4:2:0 is only 0.6 dB below the next frame's. The
table therefore adds **dark kept**. For the pixels the GIF draws darker than
its background (its bottom-right pixel), it takes how far they stay below that
background in luma, averaged per frame, as a share of the GIF's own value. The
column is the smallest share on any frame shown for at least 1 s; 1.00 keeps
all the contrast. That frame is the 16.16 s hold in every row except the MP4,
whose lowest is 0.97 at 2.08 s.

n8.1.2 with libaom 3.14.1, cpu-used 5, `tune-content=screen`, native size, on
the re-recorded stress clip. Sizes are against the MP4 contract encoded from
the same GIF; letters name the round-2 samples:

| Configuration                          |   Bytes | vs MP4 |  PSNR | Dark kept |
| -------------------------------------- | ------: | -----: | ----: | --------: |
| MP4 contract (h)                       | 351 053 |  100 % | 38.94 |      0.97 |
| 4:2:0 CRF 32 (k)                       | 111 547 |   32 % | 38.77 |      0.18 |
| 4:2:0 CRF 32, `-arnr-strength 0`       | 108 835 |   31 % | 38.77 |      0.62 |
| 4:2:0 CRF 24, `-arnr-strength 0` (o)   | 132 781 |   38 % | 38.94 |      0.77 |
| 4:2:0 CRF 20, `-arnr-strength 0` (p)   | 140 906 |   40 % | 39.00 |      0.89 |
| 4:2:0 CRF 16, `-arnr-strength 0`       | 153 019 |   44 % | 39.04 |      0.83 |
| 4:4:4 CRF 32                           | 132 122 |   38 % | 48.79 |      0.16 |
| 4:4:4 CRF 32, `-arnr-strength 0`       | 130 925 |   37 % | 48.69 |      0.65 |
| 4:4:4 CRF 24, `-arnr-strength 0` (q)   | 154 951 |   44 % | 50.56 |      0.86 |
| 4:4:4 CRF 20, `-arnr-strength 0` (r)   | 175 094 |   50 % | 51.13 |      0.89 |

- **The alt-ref temporal filter is the main cause.** It averages frames across
  the scroll, and the faint lines do not survive the average. Turning it off
  costs no bytes at CRF 32 and more than triples the contrast kept; a lower
  CRF does the rest. Exploratory probes outside the script found no other
  fix: with the filter on, even CRF 12 kept only about two thirds, and turning
  off alt-ref frames (`-auto-alt-ref 0`), lookahead (`-lag-in-frames 0`) or the
  TPL model kept 0.2–0.35.

- **CRF is not monotonic here:** CRF 16 keeps less than CRF 20 on this frame.
  This is one frame of one clip, a threshold check rather than a smooth
  quality control.

- **Older builds agree.** With only the 6.1.3 (libaom 3.12.1) or 7.0.2
  (libaom 3.2.0) encoder on `PATH`, `--webm-holds` keeps 0.19 / 0.31 at
  CRF 32 with the filter on, and 0.90 / 0.94 with the selected contract.

### Playback round 2

`<work-dir>/playback-webm-holds/index.html` holds h and k for reference, and
samples o–r. Checked in the same browsers on the same day:

- o, p, q and r keep the dark lines visible for the whole hold in both
  browsers: 0.77 kept was enough here.
- 4:4:4 (q, r) is clearly better than 4:2:0 (o, p) on small coloured glyphs.
- r is visibly better than q. The 4:2:0 pair was not compared on its own; the
  CRF 20 choice is carried over to it.
- 4:2:0 is selected nevertheless. 4:4:4 is AV1 High profile, which hardware
  decoders generally do not support; Safari plays AV1 only through a hardware
  decoder (Apple M3 / A17 Pro and newer), so it very likely cannot play 4:4:4.
  Safari was not tested.

### Revalidating the selected contract

The exact options of the contract below, as `_BENCH_WEBM_CONTRACT`:

- **Stress:** 140 906 B, the same as p; `-g 250` adds no keyframe to 220
  frames. Main profile, `yuv420p`, colour tags unchanged.
- **Timing:** PASS with 0 ms error on all six inputs of section 13, with
  n8.1.2 and with only the n6.1.3 or 7.0.2 encoder on `PATH`.
- **Geometry:** the logo stays 899x480: 18 137 B at 49.84 dB, against the MP4
  contract's 29 305 B at 47.62 dB (62 %).
- **Keyframes** on the stress clip looped three times (660 frames, 86.49 s).
  Seek times are single ffmpeg (libdav1d) observations, not browser seeks:

| Policy                    |   Bytes | vs aom keyint | Keyframes | Longest interval    | Seek to last frame |
| ------------------------- | ------: | ------------: | --------: | ------------------- | -----------------: |
| Contract, libaom's keyint | 408 892 |         100 % |         1 | 660 frames, 86.49 s |             1.02 s |
| Contract, `-g 250`        | 443 486 |         108 % |         3 | 250 frames, 33.32 s |             0.30 s |

## The WebM contract

**Selected after the playback gate (sections 14 and 15); not yet implemented
in `s-vhs.sh`.**

- **Encoder:** `libaom-av1`, single-pass unconstrained quality:
  `-b:v 0 -row-mt 1 -cpu-used 5 -crf 20 -g 250 -arnr-strength 0
  -aom-params tune-content=screen`, default good-quality usage. At cpu-used 5,
  screen tuning saved 0.1–5.9 % at equal PSNR,
  and it keeps sizes steady across efforts (section 11). SVT-AV1 is rejected
  for timeline loss in the tested build. VP9 lost the same faint text at
  CRF 32 and was not measured with the held-frame check.
- **Profile:** native-sized 8-bit `yuv420p`, AV1 Main. 4:4:4 (High) was
  clearly better on small coloured glyphs in Chrome and Firefox, but hardware
  decoders generally lack it and Safari very likely cannot play it; Main keeps
  hardware decoding and the widest AV1 reach. The MP4 stays the most
  compatible output either way.
- **Quality:** CRF 20 with the alt-ref temporal filter off
  (`-arnr-strength 0`). It keeps 0.89 of the faint text's contrast on the
  held frame, against the MP4's 0.97 and 0.18 for the earlier CRF 32
  candidate, at 40 % of the MP4's bytes on stress and 62 % on the logo
  (section 15). CRF 20 was chosen by eye on the 4:4:4 pair and carried over
  to 4:2:0. No new public setter.
- **Input/timing:** `-ignore_loop 1 -min_delay 0`,
  `-fps_mode passthrough -enc_time_base 1:100`, no second application of
  recording speed/holds, no CFR conversion. Keep default lookahead. Frame
  count, PTS, sample durations and container end stay within 1 ms on all six
  timing inputs.
- **Keyframes:** `-g 250`, like the MP4 contract. It adds nothing up to 250
  frames; on an 86 s clip it costs 8 % and cuts an ffmpeg seek to the end
  from 1.02 to 0.30 s (section 15). Browser seeking on long recordings was
  not checked.
- **Geometry/colour:** keep original dimensions, including odd sizes. Convert
  with `scale=out_color_matrix=bt601:out_range=tv:flags=full_chroma_int+accurate_rnd`,
  then `format=yuv420p`. Preserve the sRGB transfer curve; tag matrix
  `smpte170m`, primaries `bt709`, transfer `iec61966-2-1`, range `tv`.
  Those YUV tags survive WebM probing; display interpretation remains
  unverified.
- **Container:** seekable WebM file, `-an`, no MP4 `-movflags +faststart`.
  `-cues_to_front 1` costs no bytes but its startup effect is unmeasured, so
  leave it, AV1 level selection and the other muxer defaults alone. Looping
  belongs to the player.
- **Encoding time:** much slower than the MP4 contract. The contract encoded
  the 28.8 s stress clip in 12.5 s, the MP4 in 1.3 s. Earlier candidates on
  the 28.7 s clip took 9–25 s for 4:2:0 and 11–57 s for 4:4:4 across runs,
  the H.264 contract 1–6 s. An encode can take longer than the recording.
- **Toolchain:** FFmpeg 6.1+ with `libaom-av1`. The exact contract passes
  timing and the held-frame check with the 6.1.3 (libaom 3.12.1) and 7.0.2
  (libaom 3.2.0) encoders; sizes follow the libaom version, 155 145 and
  167 359 B on stress (44 and 48 % of MP4). Implementation still needs
  geometry reporting and early missing-encoder/version errors, as for MP4.
- **Lossless/optimization:** no lossless output mode or `SetOptimize` mapping
  selected. The measured lossless files are large, and libaom at cpu-used 5
  needs `-arnr-strength 0` to be bit-exact. Keep the separate optimization
  task open.
