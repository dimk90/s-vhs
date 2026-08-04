# Changelog

## `[v0.2.0]` - Unreleased

### New
* Add `Env` command.
* Add `RunOffRecord` command: `Hide` + `Run` + `Show` in one call.

### Changed
* Isolate recordings from the user's tmux server and configuration with a dedicated s-vhs socket.
* Name the session `s-vhs-<pid>` by default, so recordings can run in parallel.

### Fixed
* Fix `Show` after `Hide`, so a recording can be paused and resumed.
* Never kill a tmux session s-vhs did not start, including on an exit before `Start`.
* Keep the closing frame of a hidden segment: the pause before `Hide` stays.


## `[v0.1.0]` - 03.08.2026

* Basic implementation.
