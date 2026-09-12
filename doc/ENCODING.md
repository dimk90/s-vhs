# Encoding Measurements

Why the video outputs are encoded the way they are. A recording reaches every
raster renderer as one shared `agg` GIF, so the GIF is what an encoder has 
to preserve, and it is the only honest reference to measure against.

This page records what was measured, on what, and what was chosen. It is a lab
notebook, not a guide: for using the outputs see `README.md` and
`doc/REFERENCE.md`.

## Reproducing the numbers

```bash
scripts/encoding-bench.sh [work-dir]      # default: /tmp/s-vhs-encoding-bench
```

The script records the stress clip through `scripts/stress.rec.sh` when the
work directory does not already hold it, prints every table below in order and
writes the playback bundle. Nothing lands in the repository. A full run takes
about ten minutes, most of it HEVC and AV1; re-runs reuse the rendered GIF.

Quality is PSNR and SSIM **in RGB against the decoded GIF frames**, aligned by
frame index, with any padding cropped back off. `inf` means bit-exact, verified
separately with `framemd5`.

Numbers below come from ffmpeg n8.1.2 (libx264, libx264rgb, libx265, libsvtav1)
on an Intel i7-8650U.

## Inputs

| Input               | Dimensions | Bytes   | Frames | Duration | Content                                                                                                                |
| ------------------- | ---------- | ------- | ------ | -------- | ---------------------------------------------------------------------------------------------------------------------- |
| `stress.gif`        | 1224x696   | 451 233 | 229    | 30.69 s  | 256-colour ramp of small digits, truecolor gradient bar, 400 scrolled lines, a `Highlight` sweep, two 6 s static holds |
| `examples/logo.gif` | 899x480    | 33 196  | 118    | 13.72 s  | flat colour logo, odd width                                                                                            |

The logo alone is not representative: it is small, flat and short. The stress
clip adds everything an encoder finds hard about a terminal.

## 1. Codec matrix

`stress.gif`, GIF = 100 %:

| Config                             | Bytes   | vs GIF | Time  | PSNR avg | PSNR min | SSIM   |
| ---------------------------------- | ------- | ------ | ----- | -------- | -------- | ------ |
| x264 4:2:0 crf14 medium            | 399 296 | 88 %   | 1.3 s | 38.83    | 36.94    | 0.9927 |
| x264 4:2:0 crf18 medium            | 332 155 | 74 %   | 1.5 s | 38.72    | 36.83    | 0.9925 |
| x264 4:2:0 crf20 medium            | 304 130 | 67 %   | 1.5 s | 38.63    | 36.76    | 0.9923 |
| x264 4:2:0 crf23 medium            | 264 159 | 59 %   | 1.4 s | 38.42    | 36.55    | 0.9920 |
| x264 4:2:0 crf28 medium            | 204 253 | 45 %   | 1.5 s | 37.73    | 35.87    | 0.9909 |
| x264 4:2:0 crf18 ultrafast         | 633 205 | 140 %  | 0.7 s | 38.78    | 36.98    | 0.9926 |
| x264 4:2:0 crf18 fast              | 318 871 | 71 %   | 1.2 s | 38.68    | 36.81    | 0.9924 |
| x264 4:2:0 crf18 veryslow          | 315 333 | 70 %   | 3.4 s | 38.72    | 36.85    | 0.9925 |
| x264 4:4:4 crf18 medium            | 351 496 | 78 %   | 1.6 s | 48.45    | 46.40    | 0.9994 |
| x264 4:4:4 crf23 medium            | 273 272 | 61 %   | 1.4 s | 45.32    | 43.63    | 0.9986 |
| x264 4:4:4 lossless (`-qp 0`)      | 510 794 | 113 %  | 1.4 s | 52.83    | 52.74    | 0.9999 |
| **libx264rgb lossless**            | 793 129 | 176 %  | 1.8 s | **inf**  | **inf**  | 1.0000 |
| libx264rgb lossless veryslow       | 716 875 | 159 %  | 3.9 s | inf      | inf      | 1.0000 |
| x264 4:2:0 crf18 `-tune animation` | 352 234 | 78 %   | 2.0 s | 38.77    | 36.88    | 0.9926 |
| x264 4:2:0 crf18 `-bf 0`           | 354 648 | 79 %   | 1.6 s | 38.74    | 36.85    | 0.9925 |
| x265 4:2:0 crf20                   | 244 212 | 54 %   | 6.0 s | 37.98    | 36.22    | 0.9914 |
| x265 4:4:4 crf20                   | 260 161 | 58 %   | 7.5 s | 42.64    | 40.91    | 0.9965 |
| SVT-AV1 4:2:0 crf30                | 270 479 | 60 %   | 7.3 s | 38.81    | 36.96    | 0.9925 |
| SVT-AV1 4:2:0 crf20                | 390 501 | 87 %   | 6.2 s | 38.86    | 36.99    | 0.9925 |

`examples/logo.gif` behaves the same way with everything shifted up: 4:2:0
crf18 = 86 % of the GIF at 45.6 dB, libx264rgb lossless = 131 %, and x265 and
AV1 come out *larger* than x264 on that short clip (115 % and 78 %).

- **4:2:0 has a hard quality ceiling of ~38.8 dB on this content**, reached
  already at crf 14. Past that, a lower CRF buys nothing: the remaining loss is
  chroma subsampling, not compression. An amplified difference map puts all of
  it on the edges of coloured glyphs; greys and whites are untouched.
- **4:4:4 removes that ceiling** - 48.5 dB at crf 18 for 78 % of the GIF - but
  it is H.264 *High 4:4:4 Predictive*, which plays in Chrome and desktop
  players only.
- **Only `libx264rgb -qp 0` is bit-exact.** `yuv444p -qp 0` is not: the RGB to
  YUV 8-bit rounding caps it at 52.8 dB. The bit-exact option costs 176 % of
  the GIF and carries the same unplayable profile.
- **HEVC and AV1 do not earn their cost.** x265 4:2:0 is ~30 % smaller than
  x264 for 0.7 dB less quality, four times the encoding time and far worse
  compatibility; AV1 matches x264's quality at 60 % of the size for five times
  the time. Both are *larger* than x264 on the small logo clip.
- Presets barely matter: `veryslow` is 5 % smaller than `medium` at equal
  quality for 2.4x the time, while `ultrafast` is 2-3x *larger*.
  `-tune animation`, `-tune stillimage` and `-bf 0` move size by a few per cent
  with no quality gain.

## 2. Colour: matrix and range

Each file decoded three ways - honouring its own tags, and as a player that
ignores them and assumes BT.709 or BT.601 limited range would read it
(`stress.gif`, crf 18):

| Config               | Bytes   | honouring tags | as 709/tv | as 601/tv | stream tags             |
| -------------------- | ------- | -------------- | --------- | --------- | ----------------------- |
| ffmpeg default       | 332 155 | 38.72          | 38.45     | 38.72     | untagged                |
| 4:2:0 BT.601 limited | 332 724 | **38.58**      | 38.45     | 38.58     | `yuv420p,tv,smpte170m`  |
| 4:2:0 BT.601 full    | 340 029 | **38.76**      | 38.49     | 38.76     | `yuvj420p,pc,smpte170m` |
| 4:2:0 BT.709 limited | 326 535 | 36.47          | 36.47     | 36.00     | `yuv420p,tv,bt709`      |
| 4:2:0 BT.709 full    | 339 361 | 37.48          | 37.48     | 36.92     | `yuvj420p,pc,bt709`     |
| 4:4:4 BT.601 full    | 360 263 | 50.56          | 45.08     | 50.56     | `yuvj444p,pc,smpte170m` |
| 4:4:4 BT.709 full    | 360 458 | 47.26          | 47.26     | 43.93     | `yuvj444p,pc,bt709`     |

- **BT.601 beats BT.709 by 1.3-2.1 dB on 4:2:0 terminal text.** BT.709 gives
  blue and red a smaller share of luma, so saturated ANSI colours carry more of
  their detail in the chroma planes - exactly what 4:2:0 throws away.
- **A BT.601 file misread as BT.709 still scores 38.45 dB**, above a correctly
  decoded BT.709 file at 36.47 dB. BT.601 is the safer choice even against a
  player that ignores the tags.
- **Full range gains 0.2 dB** over limited range for BT.601, at ~2 % more
  bytes. It is not worth the failure mode: a player that ignores the
  `color_range` flag shows washed-out greys, a visible defect, while a misread
  matrix is a subtle hue shift.
- ffmpeg's default converts as BT.601 and writes **no tags at all**, leaving
  the result to the player's guess. Whatever is chosen has to be tagged.

## 3. Frame policy

`stress.gif`, 4:2:0 crf 18, against the default-GOP encode:

| Policy                          | Bytes     | vs default | Keyframes |
| ------------------------------- | --------- | ---------- | --------- |
| default (keyint 250 + scenecut) | 332 155   | 100 %      | 2         |
| `-g 120`                        | 414 824   | 125 %      | 3         |
| keyframe every 10 s             | 558 454   | 168 %      | 4         |
| `-g 60`                         | 580 341   | 175 %      | 5         |
| keyframe every 5 s              | 844 861   | 254 %      | 7         |
| `-g 30`                         | 851 549   | 256 %      | 9         |
| `-g 15`                         | 1 364 625 | 411 %      | 17        |
| all-intra (`-g 1`)              | 8 653 874 | 2605 %     | 229       |

- **All-intra is indefensible here**: 26x the bytes lossy, 46x lossless. A
  full-screen text keyframe costs 70-100 KB while an inter frame costs about
  1 KB, because a terminal recording is mostly unchanged pixels.
- Even a modest forced interval is expensive, and buys little: the clip decodes
  at 200+ fps, so seeking from the previous keyframe is instant either way.
  x264's own scenecut-driven default is the right policy.
- B-frames cost nothing to keep (`-bf 0` is 7 % *larger*).

## 4. What CRF actually controls

A lossless 4:2:0 round trip through the same colour pipeline (`-qp 0`) is
412 361 B - 91 % of the GIF - and defines the 38.6 dB floor. Measuring each CRF
against *that* reference separates codec damage from subsampling damage:

| CRF | Bytes   | vs GIF | PSNR vs GIF | PSNR vs lossless 4:2:0 |
| --- | ------- | ------ | ----------- | ---------------------- |
| 14  | 400 530 | 89 %   | 38.69       | 54.43                  |
| 16  | 365 313 | 81 %   | 38.65       | 52.81                  |
| 18  | 332 724 | 74 %   | 38.58       | 51.26                  |
| 20  | 304 935 | 68 %   | 38.50       | 49.76                  |
| 23  | 264 365 | 59 %   | 38.30       | 47.42                  |

`examples/logo.gif` at the same settings: crf 18 = 28 792 B (87 % of the GIF,
50.87 dB against its own lossless round trip), crf 20 = 26 748 B (81 %),
crf 23 = 24 016 B (72 %).

crf 18 is the knee: 51 dB of codec-only error is visually transparent next to
the 38.6 dB subsampling floor, for 74-87 % of the GIF.

## 5. Geometry

4:2:0 requires even dimensions and `examples/logo.gif` is 899 px wide.
`pad=ceil(iw/2)*2:ceil(ih/2)*2:0:0` adds a single black column on the right,
which never touches terminal text; scaling or cropping would. 4:4:4 and RGB
encodes take odd dimensions unchanged. Padding is part of the output geometry
and has to be reported as such.

## 6. Playback

Verified by hand with the bundle the bench script writes
(`<work-dir>/playback/index.html`), in Chrome, Firefox, Safari/QuickTime and
VLC. Results were as the codec profiles predict:

| Sample                        | Result           |
| ----------------------------- | ---------------- |
| 4:2:0 BT.601 limited          | plays everywhere |
| 4:2:0 BT.709 limited          | plays everywhere |
| 4:2:0 BT.601 full range       | plays everywhere |
| 4:4:4 (High 4:4:4 Predictive) | Chrome only      |
| libx264rgb lossless           | plays nowhere    |


## The MP4 contract

- `libx264`, `yuv420p`, High profile, `-crf 18 -preset medium`
- `scale=out_color_matrix=bt470bg:out_range=tv:flags=full_chroma_int+accurate_rnd`,
  tagged to match (`smpte170m`, range `tv`)
- x264's default GOP - scenecut keyframes, B-frames on
- `pad=ceil(iw/2)*2:ceil(ih/2)*2:0:0` for odd dimensions
- `-movflags +faststart`, no audio track
- no lossless mode: the only bit-exact encoder plays nowhere and costs 176 % of
  the GIF, and WebP already covers lossless raster output
