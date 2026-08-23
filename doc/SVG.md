# Animated SVG: Pitfalls and Workarounds

A `.svg` output is not a picture of the recording: it is a small program the
viewer runs. The glyphs come from fonts installed on the *reader's* machine,
while the animation comes from a CSS `@keyframes` reel. That is what buys
sharpness at any zoom, a tiny file and selectable text - and it is also why the
same file can look right on the machine that produced it and wrong in a README.

This page collects what actually bites and what to do about it.

## Ship a GIF when

* the reader must see identical pixels;
* the output is full-width box art or a TUI;
* the destination might rasterize the file;
* the font is unusual.

For everything else, including READMEs, documentation sites and blog posts,
SVG is usually the better choice.

## Fonts are named, never embedded

`asg` writes a CSS font stack into the SVG but does not embed the fonts. The
SVG therefore uses fonts installed on the reader's device. If a specified font
is unavailable, it uses a substitute with different metrics and may show
missing-glyph boxes ("tofu") instead of Nerd Font or Powerline glyphs.

**Workaround.** Record with a widely available font and keep the fallback chain
(`SetFontFamily 'JetBrains Mono'`, not `SetFontFamilyExact`). S-VHS puts text
fonts first in that chain.

Upstream: [asg#16](https://github.com/kingsword09/asg/issues/16).

## The grid uses fixed `0.6 em` cells

`asg` bases the canvas width, cursor rectangle, cell backgrounds and per-frame
step on `0.6 × font-size`, but text advances according to the viewer's font.
The two agree only when the font has an advance width of exactly `0.6 em`.
Fira Code uses `0.615 em`, Menlo and DejaVu Sans Mono use `0.602 em` and
Consolas (the generic `monospace` on Windows) uses `0.55 em`. The error
accumulates across columns, so long lines drift out of their backgrounds and
the cursor no longer aligns with its character.

Unicode block elements make the same mismatch visible inside a single line:
`asg` emits `█` as a cell-sized `<path>` rectangle, while it renders
box-drawing characters (`═ ║ ╔`) through the font. A frame or progress bar
mixes the two, so any difference between the grid and the font's advance width
becomes a seam. The selected font's own block glyphs are never used.

**Workaround.**

- Prefer a font with a `0.6 em` advance width: JetBrains Mono, Cascadia Mono,
  Liberation Mono, Noto Sans Mono, Source Code Pro, Hack or IBM Plex Mono.
- Keep symbol fonts *after* text fonts in the stack. `Segoe UI Symbol` on
  Windows and `Apple Symbols` on iOS also cover Latin characters, but both are
  proportional.
- Prefer GIF output for box-art-heavy or full-width recordings.

Upstream: [asg#19](https://github.com/kingsword09/asg/issues/19),
[asg#17](https://github.com/kingsword09/asg/issues/17) and
[asg#18](https://github.com/kingsword09/asg/issues/18).

## Outside a browser, only the first frame appears

Non-browser renderers ignore CSS animation and `@font-face`. They render only
frame 0, so `resvg`, `librsvg` and ImageMagick show the initial prompt and
cursor instead of the recording. The same applies to editor previews,
Inkscape, PDF pipelines and image proxies that convert formats.

**Workaround.** Render a still with `asg --at <seconds>` for those consumers,
or use the GIF.

## Other sharp edges

* **Theme names are not shared with `agg`.** When a recording produces both GIF
  and SVG, `Render` fails if only one renderer recognizes the selected theme.
  Use a custom palette; see [REFERENCE.md](REFERENCE.md).

* **File size scales with screen changes, not pixel count.** A short SVG can be
  far smaller than the equivalent GIF (`examples/multi-output.svg` is 9.0 KB
  versus 13.4 KB, and 1.6 KB versus 7.9 KB gzipped), but a busy full-screen TUI
  can run into hundreds of KB. Keep SVG recordings short.
