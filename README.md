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


## Quick Start


A recording is a plain shell script that sources `s-vhs.sh`:

```shell
#!/usr/bin/env bash

source ./s-vhs.sh

# Where should we write the GIF?
SetOutput 'demo.gif'

# Set up an 60x8 terminal with a 34px font.
SetCols 60
SetRows 8
SetFontSize 34

# Start the terminal, then the recorder.
Start
Show

# Type a command in the terminal
Type "echo 'Welcome to S-VHS!"
sleep 1 # Pause for dramatic effect...
Type " Stay awhile and listen...'"
sleep 1

# Pause for dramatic effect...
sleep 0.5

# Run the command by pressing enter.
Key Enter

# Admire the output for a bit.
sleep 5

# Stop recording and write every requested output.
Render
```

Run it to render the GIF:
```shell
chmod +x demo.rec.sh && demo.rec.sh
```

You should see a new file called `demo.gif` (or whatever you named the Output) in the directory:

<img src="examples/images/quick-start.gif" width=700>


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

> [!NOTE]
> `s-vhs` targets bash 3.2, the version macOS still ships as `/bin/bash`, 
> so recording scripts run on a stock Mac without installing a newer bash.


## Examples

> [!NOTE]
> See [`examples/`](examples) for more recording scripts.


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

Start your new recording from the bundled template:

```shell
./s-vhs.sh new demo.rec.sh
```
> The file is created executable, and an existing one is never overwritten. Drop
> the path to print the template instead: `./s-vhs.sh new > demo.rec.sh`.

It writes:

```shell
#!/usr/bin/env bash

source ./s-vhs.sh

SetOutput 'demo.gif'

# SetCols 100
# SetRows 40
# SetFontSize 28
# SetFontFamily 'JetBrains Mono'
# SetTheme 'kanagawa'
# SetTypingSpeed 0.07

Start
Show

Type 'echo "Hello from s-vhs"'
Key Enter
sleep 3

Render
```

## Command Reference

See [REFERENCE.md](doc/REFERENCE.md) for description of all `s-vhs` commands.

## License

[MIT](LICENSE)
