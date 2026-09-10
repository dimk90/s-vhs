
## `[v0.6.0]`

- [x] Add WebP output:
  - Convert agg's shared GIF render via FFmpeg's `libwebp_anim` encoder.
  - Use lossless BGRA, method 4 and compression effort 75 for sharp terminal text.
  - Preserve GIF frame timing, the final hold and loop control.
  - Update README output formats and installation instructions.
  - Add the feature near the beginning of the README, linking VHS issue #50.

- [ ] Update `SetOptimize` for WEBP:
  - Enable to spend more time for a bit higher compression gain (still lossless).
  - better printf format for ffmpeg status text?

- [ ] Use better examples from `pi-context-view`.

- [ ] Add `SUPPORT-MATRIX` to the README documentation section.

- [x] Switch from `BRE` to `ERE` pattern matching.


## `[v0.7.0]`

- [ ] Add MP4 & WebM output:
  - GIF to MP4/WebM conversion via `ffmpeg`? Any better way?
  - Choose coder parameter which are best fit for terminal recording content.
  - Lossless option? No P/B-frames?
  - Which codec for MP4?
  - Update README output format section and install instruction for webp format.

- [ ] Update `SetOptimize` for video:
  - What is should do for video?

- [ ] Add note about compression efficiency:
  - use `logo` as example example.
  - SetOptimize on/off
  - Quality drop for video.
