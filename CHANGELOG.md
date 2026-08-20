# Changelog

## `[v0.4.0]` - Unreleased

### New
* Add `SetPlaybackSpeed`: play the rendered animation faster or slower.
* Add `SetFramerate`: cap the frames per second of the rendered animation.
* Add `SetIdleTimeLimit`: cap how long a pause is played back.
* Add `SetLoop`: stop the rendered animation after one pass instead of repeating it.
* Add `SetTitle`: store a title in the cast metadata for players to show.
* Add `SetQuiet`: suppress recorder, GIF renderer and s-vhs informational output while keeping errors visible.
* Add `Require`: check recording-specific command dependencies before starting a session.
* Add `Copy` and `Paste` commands.

### Changed
* SVG output now caps idle pauses at 5 seconds like GIF output.


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
