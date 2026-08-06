# Changelog

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
