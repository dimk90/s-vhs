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

- **Always sharp** - no GIF quality loss
  ([#625](https://github.com/charmbracelet/vhs/issues/625),
  [#69](https://github.com/charmbracelet/vhs/issues/69#issuecomment-3121533232)).
- **No timing drift** - 1 second is 1 second at any resolution
  ([#69](https://github.com/charmbracelet/vhs/issues/69#issuecomment-3121533232)).
- **Sized in rows and cols** - no dancing with pixel width and height
  ([#578](https://github.com/charmbracelet/vhs/issues/578)).
- **No browser, no Node** - just a wrapper around `tmux` + `asciinema` + `agg`
  ([#528](https://github.com/charmbracelet/vhs/issues/528),
  [#438](https://github.com/charmbracelet/vhs/issues/438),
  [#150](https://github.com/charmbracelet/vhs/issues/150),
  [#45](https://github.com/charmbracelet/vhs/issues/45)).


## Quick Start


A recording is a plain shell script that sources `s-vhs.sh`:

```bash
#!/usr/bin/env bash

source ./s-vhs.sh

# Where should we write the GIF?
SetOutput 'demo.gif'

# Set up a 60x8 terminal with a 34px font.
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

# Run the command by pressing enter.
Key Enter

# Admire the output for a bit.
sleep 5

# Stop recording and write every requested output.
Render
```

Run it to render the GIF:
```shell
./demo.rec.sh
```

You should see a new file called `demo.gif` (or whatever you passed to `SetOutput`) in the directory:

<img src="examples/quick-start.gif" width=700>


## Installation


`s-vhs` is a bash script, so you only need its dependencies:
- Install `tmux` and `asciinema`:
  ```bash
  sudo pacman -S tmux asciinema
  ```
- Install `agg`: follow [official instructions](https://github.com/asciinema/agg#building) or
  ```bash
  paru -S asciinema-agg
  ```

> [!NOTE]
> The provided instructions are for ArchLinux, but you can easily adapt them for your favorite distro ;)

> [!NOTE]
> `s-vhs` targets bash 3.2, the version macOS still ships as `/bin/bash`,
> so recording scripts run on a stock Mac without installing a newer bash.


## Examples

See [`examples`](examples) for the complete scripts behind the demos below, and a few more.

### Enter

```bash
Key Enter 4 0.5
```

<img src="examples/enter.gif" width=500>


### Type

```bash
# Regular typing
Type 'echo "whatever you want"'
sleep 1

Key Enter; sleep 0.5

# Slow typing
Type 'echo "slow down"' 0.25
```

<img src="examples/type.gif" width=500>

### Columns & Rows

```bash
SetCols 40
SetRows 8

Type 'tput cols'
Key Enter; sleep 1
Type 'tput lines'
Key Enter; sleep 1
```

<img src="examples/cols-rows.gif" width=500>

### Key

#### Arrows

```bash
Type 'echo navigate around'; sleep 0.5
Key Left 10 0.12
sleep 0.5
Key Right 10 0.05
```
<img src="examples/arrow.gif" width=500>

#### Backspace

```bash
Type 'echo delete anything...' 0.05; sleep 0.5
Key BSpace 18 0.05
```

<img src="examples/backspace.gif" width=500>

### Wait

Wait polls the visible pane until a text pattern shows up:

```bash
Type 'sleep 2 && echo "build succeeded"'
Key Enter

Wait '^build succeeded' 10
Type 'echo "and on we go"'
```

<img src="examples/wait.gif" width=500>

### Color Theme

```bash
# One of the renderer's named themes.
# A comma-separated hex palette
# (background, foreground, then 8 or 16 colors) also works.
SetTheme 'kanagawa'
```

<img src="examples/theme.gif" width=500>

### Font Size

The font size is the only pixel-sized setting: it scales the whole render 
without changing the terminal grid the recorded shell sees.

```bash
SetFontSize 40
```

<img src="examples/font-size-40.gif" width=500>

<img src="examples/font-size-20.gif" width=300>

<img src="examples/font-size-10.gif" width=150>

### Show / Hide

```bash
Start # Start session / initialize terminal

# Off camera: export the variable and wipe the screen it was typed on
Run 'export HIDDEN=wow' 0.5
Run 'clear' 0.5

Show # Start recording

# The recorded shell expands it, not this script
Type 'echo $HIDDEN'
Key Enter; sleep 2

Hide # Stop recording, the session keeps running

Run 'echo "nobody will ever see this"' 0.5
```

<img src="examples/hide-show.gif" width=500>

### Multiple Outputs

```shell
SetOutput "multi-output.cast"
SetOutput "multi-output.gif"
```

## Recording Template

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
# SetTheme 'dracula'
# SetTypingSpeed 0.07

Start
Show

Type 'echo "Hello from s-vhs"'
Key Enter
sleep 3

Render
```

## Documentation

- For the architecture behind `tmux + asciinema + agg` and how `s-vhs` glues
  them together, see [INTRO.md](doc/INTRO.md).

- For the full list of commands and settings, see [REFERENCE.md](doc/REFERENCE.md).

## Links

- [asciinema](https://github.com/asciinema/asciinema) project ❤️
- [agg](https://github.com/asciinema/agg) project ❤️

## License

[MIT](LICENSE)
