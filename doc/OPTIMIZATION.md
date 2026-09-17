# Output Size Optimization

`SetOptimize 'on'` trades a slower `Render` for smaller output files. It is
`off` by default and must be called before `Start`. The setting applies to
every requested output that supports it: GIF and WebP stay lossless, while
MP4 keeps its quality target rather than identical pixels.

## GIF

GIFs come out of the renderer generously encoded. `SetOptimize 'on'` runs the
rendered file through a lossless [`gifsicle`](https://github.com/kohler/gifsicle)
pass, so it shrinks without a single pixel changing:

```bash
SetOutput 'optimize.gif'
SetOptimize 'on' # <---
```

| `SetOptimize 'off'` - the default                                               | `SetOptimize 'on'`                                                        |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| <img src="../examples/optimize-off.gif" width="330px" alt="Unoptimized render"> | <img src="../examples/optimize.gif" width="330px" alt="Optimized render"> |
| 193,964 bytes                                                                   | 164,541 bytes, identical frames                                           |

How much it saves depends on the recording - long, scrolling ones gain the
most. The trade-off is an extra processing pass, not reduced quality.

### Dependency

GIF optimization needs `gifsicle`. Without it, `Render` leaves GIFs
unoptimized and reports the skipped pass rather than failing the recording.

- **macOS**
  ```bash
  brew install gifsicle
  ```

- **Linux**
  ```bash
  sudo pacman -S gifsicle
  ```

## WebP

WebP output is lossless with optimization either on or off.
`SetOptimize 'on'` switches the encoder to its slowest lossless effort,
which typically saves a few per cent for several times the encoding time.
The visible frames and timing stay the same.

No extra dependency is needed beyond the `agg` and `ffmpeg` used to render
WebP. See [WebP installation](../README.md#renderer-webp).

## MP4

`SetOptimize 'on'` switches the H.264 encoder from the `medium` preset to
`veryslow`, keeping the same quality target (`CRF 18`). The
[measured recordings](ENCODING.md#8-optimization-presets) were about 10-20 %
smaller for roughly 1.5-2 times the encoding time; savings vary by recording.

MP4 is lossy with optimization either on or off. Unlike GIF and WebP,
optimized and unoptimized MP4s do not have identical pixels: the encoder
makes different choices at the same quality target, and measured quality can
move slightly in either direction.

No extra dependency is needed beyond the `agg` and `ffmpeg` used to render
MP4. See [MP4 installation](../README.md#renderer-mp4).

## SVG

`SetOptimize` does not affect SVG; `Render` reports it as skipped when enabled.

SVG size follows screen changes rather than pixel count, so a smaller
`SetFontSize` is not the same size-saving lever it is for raster outputs.

## Cast

`SetOptimize` does not affect the `.cast` recording. Render-time settings such
as `SetFramerate` and `SetIdleTimeLimit` leave its recorded events and timing
unchanged.

## Other Ways to Reduce Size

Reduce what gets recorded or rendered before optimizing its encoding:

| Approach                             | Setting                                                                                    | Trade-off                                                                                              |
| ------------------------------------ | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------ |
| Render fewer pixels (GIF, WebP, MP4) | Choose the smallest useful `SetCols`, `SetRows` and `SetFontSize`                          | Less terminal space or smaller text; a large image scaled down in HTML is sharper but costs more bytes |
| Render fewer frames                  | Lower `SetFramerate`, for example from `30` to `15` or `10`                                | Fast typing and motion look less smooth                                                                |
| Shorten inactive gaps                | Lower `SetIdleTimeLimit`, for example from `5` to `1`                                      | Long pauses play back faster; the retained `.cast` keeps its original timing                           |
| Record less activity                 | Put setup and noisy intermediate commands between `Hide` and `Show`, or use `RunOffRecord` | Hidden activity does not appear in the recording                                                       |

> [!TIP]
> These reductions can save more than an optimization pass. Keep the highest
> values the recording actually needs, then use `SetOptimize 'on'` for additional
> savings on GIF, WebP and MP4.
