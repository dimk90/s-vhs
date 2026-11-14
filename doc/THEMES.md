# Color Themes

`SetTheme` selects a bundled theme. The default is `dracula`. Every renderer
gets the same palette, so GIF, WebP, MP4, WebM and SVG share their colors.

```bash
SetTheme 'kanagawa'
```

## Gallery

Each sample shows the default foreground, ANSI colors 0–7 and bright colors
8–15, rendered as GIF and as SVG.

| Theme               | GIF                                                                                                 | SVG                                                                                                 |
| ------------------- | --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `asciinema`         | <img src="../examples/themes/asciinema.gif" width="400" alt="asciinema palette in GIF">             | <img src="../examples/themes/asciinema.svg" width="400" alt="asciinema palette in SVG">             |
| `atom-one`          | <img src="../examples/themes/atom-one.gif" width="400" alt="atom-one palette in GIF">               | <img src="../examples/themes/atom-one.svg" width="400" alt="atom-one palette in SVG">               |
| `dracula` (default) | <img src="../examples/themes/dracula.gif" width="400" alt="dracula palette in GIF">                 | <img src="../examples/themes/dracula.svg" width="400" alt="dracula palette in SVG">                 |
| `github-dark`       | <img src="../examples/themes/github-dark.gif" width="400" alt="github-dark palette in GIF">         | <img src="../examples/themes/github-dark.svg" width="400" alt="github-dark palette in SVG">         |
| `github-light`      | <img src="../examples/themes/github-light.gif" width="400" alt="github-light palette in GIF">       | <img src="../examples/themes/github-light.svg" width="400" alt="github-light palette in SVG">       |
| `kanagawa`          | <img src="../examples/themes/kanagawa.gif" width="400" alt="kanagawa palette in GIF">               | <img src="../examples/themes/kanagawa.svg" width="400" alt="kanagawa palette in SVG">               |
| `kanagawa-dragon`   | <img src="../examples/themes/kanagawa-dragon.gif" width="400" alt="kanagawa-dragon palette in GIF"> | <img src="../examples/themes/kanagawa-dragon.svg" width="400" alt="kanagawa-dragon palette in SVG"> |
| `kanagawa-light`    | <img src="../examples/themes/kanagawa-light.gif" width="400" alt="kanagawa-light palette in GIF">   | <img src="../examples/themes/kanagawa-light.svg" width="400" alt="kanagawa-light palette in SVG">   |
| `monokai`           | <img src="../examples/themes/monokai.gif" width="400" alt="monokai palette in GIF">                 | <img src="../examples/themes/monokai.svg" width="400" alt="monokai palette in SVG">                 |
| `nord`              | <img src="../examples/themes/nord.gif" width="400" alt="nord palette in GIF">                       | <img src="../examples/themes/nord.svg" width="400" alt="nord palette in SVG">                       |
| `solarized-dark`    | <img src="../examples/themes/solarized-dark.gif" width="400" alt="solarized-dark palette in GIF">   | <img src="../examples/themes/solarized-dark.svg" width="400" alt="solarized-dark palette in SVG">   |
| `solarized-light`   | <img src="../examples/themes/solarized-light.gif" width="400" alt="solarized-light palette in GIF"> | <img src="../examples/themes/solarized-light.svg" width="400" alt="solarized-light palette in SVG"> |

## Custom palettes

Pass 18 comma-separated six-digit hex colors, without `#`: background,
foreground, then ANSI 0–15.

```bash
SetTheme '282a36,f8f8f2,21222c,ff5555,50fa7b,f1fa8c,bd93f9,ff79c6,8be9fd,f8f8f2,6272a4,ff6e6e,69ff94,ffffa5,d6acff,ff92df,a4ffff,ffffff'
```

Any other value passes through to the renderer unchanged; one it does not
support fails at `Render`.

A theme changes only how the output is drawn. Programs in the session that ask
the terminal for its colors do not see it, 24-bit colors they print stay as
they are, and a retained `.cast` does not store it.

## Regenerate the Samples

```bash
./examples/themes.rec.sh
```

It renders every theme to GIF and SVG under `examples/themes/` and needs
`agg` and `asg`.
