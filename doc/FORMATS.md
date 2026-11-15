# Output Formats

The outputs of one recording differ in size, quality and where they play.

## Which Format to Pick

| Destination                        | Format                      | Why                                                            |
| ---------------------------------- | --------------------------- | -------------------------------------------------------------- |
| Anywhere, if you ship only one     | `.gif` + `SetOptimize 'on'` | Plays almost everywhere                                        |
| README, package page, web page     | `.webp`                     | Same pixels as the GIF at about half the size                  |
| Short recording shown in a browser | `.svg`                      | Sharp at any zoom, selectable text. See [SVG pitfalls](SVG.md) |
| Chat, slides, video players        | `.mp4`                      | The video format every app accepts                             |
| Your own web page, smallest file   | `.webm`                     | Slow to encode, does not play in older Safari                  |
| Archive, render again later        | `.cast`                     | The recording itself, font and theme are chosen at render      |

## Size

Every format rendered from one recording, the
[stress clip](../scripts/stress.rec.sh): 29 s of small colored text, a color
gradient and fast scrolling. The unoptimized GIF, 191 KB, is 100 %:

| Output | Quality              | `SetOptimize 'off'` | `SetOptimize 'on'` |
| ------ | -------------------- | ------------------: | -----------------: |
| GIF    | Reference            |               100 % |               85 % |
| WebP   | Same pixels as GIF   |                52 % |               51 % |
| MP4    | Lossy                |               183 % |              165 % |
| WebM   | Lossy                |                64 % |               38 % |
| SVG    | Drawn by the browser |                74 % |                  - |
| Cast   | Not an image         |                55 % |                  - |

- **MP4 is the largest.** Video encoders spend many bits on the sharp edges
  of text, so losing quality does not make the file smaller.
- **WebP is the easy win:** half the GIF, with identical pixels.
- **WebM is the smallest,** but slow: with `SetOptimize 'on'` it took
  2.5 minutes to encode. Every other output took 30 s or less.
- **SVG and cast are text** and shrink a lot when a web server compresses
  them: to 9 KB and 6 KB here.

Sizes depend on the recording, and two runs of the same script can differ by
up to 20 %. See [OPTIMIZATION.md](OPTIMIZATION.md) for what `SetOptimize`
does to each format.

## Video Quality

MP4 and WebM are made for camera footage, not for text. They store color at
half the resolution: each 2x2 pixel block shares one color. White and grey
text stays sharp, but small colored text blurs and loses color - dark colors
on a dark background most of all.

The same frame, zoomed 3x:

| Output    |                                                                 |
| --------- | --------------------------------------------------------------- |
| GIF, WebP | <img src="images/chroma-gif.png" alt="Sharp colored digits">    |
| MP4       | <img src="images/chroma-mp4.png" alt="Blurred colored digits">  |
| WebM      | <img src="images/chroma-webm.png" alt="Blurred colored digits"> |

For colored text, prefer GIF, WebP or SVG. The measurements behind the video
settings are in [ENCODING.md](ENCODING.md).

## Compatibility

✅ works · ⚠️ partial or not verified · ❌ does not work

### Code Hosts

| Host                         | GIF | WebP | SVG         | MP4 / WebM             |
| ---------------------------- | --- | ---- | ----------- | ---------------------- |
| GitHub README                | ✅  | ✅   | ✅          | ⚠️ uploaded files only |
| GitHub issue, PR, discussion | ✅  | ✅   | ✅          | ✅                     |
| npmjs.com                    | ✅  | ✅   | ✅          | ❌                     |
| PyPI                         | ✅  | ✅   | ⚠️[^pypi]   | ❌                     |
| crates.io                    | ✅  | ✅   | ✅[^crates] | ❌                     |
| pi.dev packages              | ✅  | ✅   | ⚠️[^pi]     | ❌                     |

- **Images:** `![](demo.gif)` works on every host. `<img src="demo.gif">`
  also works for GIF and WebP, except on pi.dev, which strips it.
- **Paths:** npmjs.com and PyPI need an absolute `https://` URL. GitHub,
  crates.io and pi.dev accept a path relative to the README.
- **SVG:** the animation runs, scripts are removed.
- **Video on GitHub:** drag the file into an issue or comment editor to upload
  it. In an issue, the uploaded URL on its own line becomes a player. In a
  README, use `<video src="https://github.com/user-attachments/assets/…">`:
  other hosts and `![]()` do not work, and the reader has to click to play.

[^pypi]:
    PyPI loads images through its image proxy (camo). An animated SVG
    was not tested there.

[^crates]:
    crates.io turns a relative SVG path into the repository's raw URL
    with `?sanitize=true` added.

[^pi]: Expected to work like GIF and WebP, but not tested.

### Your Own Web Page

Every current browser plays GIF, WebP, SVG and MP4. WebM needs AV1 support.

**WebP with a GIF fallback.** The browser loads only the one it shows:

```html
<picture>
  <source srcset="demo.webp" type="image/webp" />
  <img src="demo.gif" alt="Demo" width="600" />
</picture>
```

**Video.** Unlike GIF and WebP, an MP4 or WebM does not start or loop by
itself. The page has to ask for it:

```html
<video autoplay loop muted playsinline width="600">
  <source src="demo.webm" type='video/webm; codecs="av01.0.05M.08"' />
  <source src="demo.mp4" type="video/mp4" />
</video>
```

- `muted` is required: browsers block autoplay of video that may have sound.
- `playsinline` keeps iPhones from opening the video full screen.
- The `codecs` value lets a browser without AV1 skip the WebM and take the
  MP4.

### Apps

Collected from vendor documentation and public reports in November 2026, not
tested with s-vhs outputs:

| App              | GIF | WebP          | SVG             | MP4 | WebM                 |
| ---------------- | --- | ------------- | --------------- | --- | -------------------- |
| Slack            | ✅  | ⚠️            | ❌              | ✅  | ✅                   |
| Discord          | ✅  | ✅            | ❌              | ✅  | ✅                   |
| Telegram         | ✅  | ⚠️            | ❌              | ✅  | ⚠️ may show a file   |
| Email            | ✅  | ⚠️ Apple Mail | ⚠️ Apple Mail   | ❌  | ❌                   |
| PowerPoint       | ✅  | ⚠️            | ⚠️ no animation | ✅  | ⚠️ Windows only      |
| Keynote          | ✅  | ⚠️            | ⚠️ no animation | ✅  | ❌                   |
| Google Slides    | ✅  | ❌            | ❌              | ✅  | ✅                   |
| Notion           | ✅  | ✅            | ⚠️              | ✅  | ⚠️ browser-dependent |
| Confluence Cloud | ✅  | ⚠️            | ⚠️              | ✅  | ⚠️                   |

- **Email:** classic Outlook for Windows shows only the first frame of a GIF.
  Video is sent as an attachment.
- **Google Slides:** insert video from Google Drive.
- **WebM in Safari:** plays only on devices with an AV1 hardware decoder
  (Apple M3, A17 Pro and newer).

Sources: [Can I email](https://www.caniemail.com/),
[PowerPoint](https://support.microsoft.com/en-us/powerpoint/video-and-audio-file-formats-supported-in-powerpoint),
[Discord](https://discord.com/blog/modern-image-formats-at-discord-supporting-webp-and-avif),
[Telegram](https://core.telegram.org/api/gifs),
[Google Slides](https://support.google.com/docs/answer/97447),
[Notion](https://www.notion.com/help/images-files-and-media),
[Confluence](https://support.atlassian.com/confluence-cloud/docs/work-with-images-videos-and-files/).
