# S-VHS

```
███████╗    ██╗   ██╗██╗  ██╗███████╗
██╔════╝    ██║   ██║██║  ██║██╔════╝
███████╗ ██ ██║   ██║███████║███████╗
╚════██║ ██ ╚██╗ ██╔╝██╔══██║╚════██║
███████║     ╚████╔╝ ██║  ██║███████║
╚══════╝      ╚═══╝  ╚═╝  ╚═╝╚══════╝
● REC      SUPER VHS      SP 0:00:00
```

A terminal recorder like [VHS](https://github.com/charmbracelet/vhs), but superior:

- **Always sharp** — no GIF quality loss
  ([#625](https://github.com/charmbracelet/vhs/issues/625),
  [#69](https://github.com/charmbracelet/vhs/issues/69#issuecomment-3121533232)).
- **No timing drift** — 1 second is 1 second at any resolution
  ([#69](https://github.com/charmbracelet/vhs/issues/69#issuecomment-3121533232)).
- **Sized in rows and cols** — no dancing with pixel width and height
  ([#578](https://github.com/charmbracelet/vhs/issues/578)).
- **No browser, no Node** — just a wrapper around `tmux` + `asciinema` + `agg`
  ([#528](https://github.com/charmbracelet/vhs/issues/528),
  [#438](https://github.com/charmbracelet/vhs/issues/438),
  [#150](https://github.com/charmbracelet/vhs/issues/150),
  [#45](https://github.com/charmbracelet/vhs/issues/45)).
- **Animated SVG output**
  ([#644](https://github.com/charmbracelet/vhs/discussions/644),
  [#109](https://github.com/charmbracelet/vhs/issues/109),
  [#105](https://github.com/charmbracelet/vhs/issues/105)).


## Quick Start


```shell
# Where should we write the GIF?
Output demo.gif

# Set up a 1200x600 terminal with 46px font.
Set FontSize 46
Set Width 1200
Set Height 600

# Type a command in the terminal.
Type "echo 'Welcome to VHS!'"

# Pause for dramatic effect...
Sleep 500ms

# Run the command by pressing enter.
Enter

# Admire the output for a bit.
Sleep 5s
```
> TODO: rewrite with `s-vhs`

Run it to render gif:
[Link to gif](...)

> [!NOTE]
> See more recording scripts in [`examples/`](examples).


## Installation


`s-vhs` is a bash script, so you only need its dependencies:
- Install `tmux` and `asciinema`:
  ```shell
  sudo pacman -S tmux asciinema
  ```
- Install `agg` -> follow [official instructions](https://github.com/asciinema/agg#building) or
  ```shell
  paru -S asciinema-agg
  ```

> [!NOTE]
> The provided instructions are for ArchLinux, but you can easily adapt it for your favorite distro ;)


## Examples

> TODO:

### Enter

### Type

### Key

### Wait

### Show/Hide

### Set Theme

### Font Size

### Set Line Height

### It's a shell script - enjoy its power:

> TODO: mouse emulation example
>

> ;) [#66](https://github.com/charmbracelet/vhs/issues/66)

### Recording Template

```shell
# SetRows 80
# SetCols 40
# SetOutput demo.gif
# SetOutput demo.cast
# SetOutput demo.mp4
# SetOutput demo.svg
# TODO: ...
```

## Command Reference

> TODO: https://github.com/charmbracelet/vhs#vhs-command-reference

## License

[MIT](LICENSE)
