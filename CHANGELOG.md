# Changelog

## `[v0.6.0]` - Unreleased

### New
* Add animated WebP output through `agg`+`ffmpeg`.

### Changed
* `SetOptimize`: also shrink WebP output, through the encoder's slowest lossless effort.
* Use extended regular expressions (ERE) instead of BRE in `Wait` and `WaitLine`.

## `[v0.5.0]` - 02.09.2026

### New
* Add `Highlight`: sweep a selection over text on screen, the way a mouse drag would.
* Add `SetHighlightColors`: pick the colors and attributes of the `Highlight` selection.
* Add `SetHighlightSpeed`: set how fast `Highlight` sweeps its selection.
* Add `Finally`: run a cleanup command in the host shell however the recording ends.

### Changed
* Change `_svhs_cleanup` to public `svhs_cleanup` - the teardown installed as the `EXIT` trap.


## `[v0.4.2]` - 25.08.2026

### Fixed
* Suppress Apple's zsh migration notice in Bash recordings on macOS.
* `SetFontFamily`: Fall back to agg's default fonts when requested font is missing.


## `[v0.4.1]` - 25.08.2026

### Changed
* Defer `SetFontAntialiasing` and `SetFontHinting` until next agg release.


## `[v0.4.0]` - 23.08.2026

### New
* Add `SetPlaybackSpeed`: play the rendered animation faster or slower.
* Add `SetFramerate`: cap the frames per second of the rendered animation.
* Add `SetIdleTimeLimit`: cap how long a pause is played back.
* Add `SetLoop`: stop the rendered animation after one pass instead of repeating it.
* Add `SetTitle`: store a title in the cast metadata for players to show.
* Add `SetQuiet`: suppress recorder, text converter, GIF renderer and s-vhs informational output.
* Add `Require`: check recording-specific command dependencies before starting a session.
* Add `Copy` and `Paste` commands.
* Add plain-text `.txt` output through `asciinema convert`.
* Add `SetLastFrameDuration`: control how long the last GIF frame is held before looping.
* Add `SetBoldIsBright`: draw bold text in the bright ANSI color in GIF output, as most terminals do.
* Add `SetEngine`: pick the GIF frame renderer, `resvg` for color COLRv1 emoji.
* Add `SetEmojiFontFamily`: pick the fonts emoji are drawn with, in GIF and SVG output.
* Add `SetFontDir`: render a GIF with fonts kept next to the recording script instead of installed ones.
* Add `SetFontAntialiasing`: trade GIF glyph smoothness against file size.
* Add `SetFontHinting`: fit glyph outlines to the pixel grid, keeping small GIF text legible.
* Add `SetPadding`, `SetPaddingX` and `SetPaddingY`: pad the terminal in SVG output.
* Add `SetWindowBar`: draw macOS-style window decorations above the terminal in SVG output.
* Add `SetCursor`: hide the terminal cursor in SVG output.
* Add `WaitLine`: wait for a pattern on the cursor's current row.
* Add `SetOptimize`: shrink GIF output with a lossless `gifsicle` pass.
* Add an agent skill teaching coding agents to write and verify recording scripts, installable with `gh skill install dimk90/s-vhs s-vhs-recording` or from `https://dimk90.github.io/s-vhs/skill`.

### Changed
* SVG output now caps idle pauses at 5 seconds like GIF output.
* Show non-fatal S-VHS warnings in yellow.
* Print the S-VHS version when a recording starts.
* Print the recorded grid and the estimated pixel size of each rendered output.

### Fixed
* Initialize the default playback speed so rendering works without `SetPlaybackSpeed`.


## `[v0.3.0]` - 16.08.2026

### New
* Add animated SVG output through `asg`.
* Add `svhs_watch` and `s-vhs.sh watch [session]` to debug a recording's process.

### Changed
* Add `no-wait` argument to `Start`, for debugging a shell that never becomes ready.

### Fixed
* `Start` now waits until the shell is ready for input.
* `Render` keep the closing frame of a recording.


## `[v0.2.0]` - 06.08.2026

### New
* Add `Env` command.
* Add `RunOffRecord` command: `Hide` + `Run` + `Show` in one call.
* Add `SetPrompt` command + bundled themes (`arrow`, `plain`, `path`, `powerline`)
* Add `native` option for `SetPrompt` to use current shell configuration.
* Add named key commands: `Enter`, `Tab`, `Backspace`, `Up`, etc.
* Add `Sleep` command as alias for `sleep` for style consistency.
* Publish version-pinned remote imports through GitHub Pages.

### Changed
* Record in an isolated shell by default: no personal rc files.
* Keep recordings out of the user's shell history.
* `SetShell` now takes `bash`, `zsh` or `fish`, and falls back to `bash` when that shell is not installed.
* Isolate recordings from the user's tmux server and configuration with a dedicated s-vhs socket.
* Name the session `s-vhs-<pid>` by default, so recordings can run in parallel.

### Fixed
* Fix `Show` after `Hide`, so a recording can be paused and resumed.
* Never kill a tmux session s-vhs did not start, including on an exit before `Start`.
* Keep the closing frame of a hidden segment: the pause before `Hide` stays.


## `[v0.1.0]` - 03.08.2026

* Basic implementation.
