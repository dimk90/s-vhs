# AGENTS.md

Guidance for AI agents working in the `s-vhs` repository.

## Project

`s-vhs` — a terminal recorder in the spirit of
[VHS](https://github.com/charmbracelet/vhs), built as a thin Bash wrapper
around `tmux` + `asciinema` + `agg`. Recordings are driven by a user-written
shell script that sources `s-vhs.sh` and calls its functions; output is a
`.cast` rendered to GIF (SVG/MP4 planned).

Selling points to preserve when changing behaviour: sharp output (no GIF
quality loss), no timing drift across resolutions, terminal size in rows/cols
instead of pixels, no browser/Node dependency.

Status: early draft, pre-`v0.1.0`. The public function names are **not** frozen
— see `doc/PLAN.md`, which calls for renaming toward VHS-like names
(`Type`, `Enter`, `SetRows`, ...).

## Layout

| Path          | Purpose                                                    |
| ------------- | ---------------------------------------------------------- |
| `s-vhs.sh`    | The whole implementation. Sourced library, never executed. |
| `README.md`   | User-facing docs; many sections are still `> TODO:`.       |
| `doc/PLAN.md` | Roadmap / checklist. Update checkboxes when a task lands.  |
| `examples/`   | Empty placeholder for example recording scripts (planned). |

No build system, no test suite, no CI. Verification is manual: run a recording
script and inspect the produced GIF.

## Dependencies

Runtime: `bash`, `tmux`, `asciinema`, `agg`.
Optional (padding): `magick` (preferred) or `ffmpeg`.
Dev: `shellcheck`.

## Conventions

Follow the `shell-code` and `code-style` skills; `s-vhs.sh` is the reference
implementation of them. Project-specific points:

- **Sourced library, not a program.** `s-vhs.sh` has no `main`, no arg parsing,
  and must stay safe to `source`. It installs an `EXIT` trap (`_cleanup`) in the
  sourcing script's shell.
- **Configuration via overridable defaults.** Every setting is
  `: "${NAME:=default}"` so a recording script can set it before sourcing.
  Required values use `: "${CAST:?message}"`. Add new settings the same way,
  with a comment explaining the unit or the reason for the default.
- **Sections.** `## Constants`, `## Session`, `## Input`, `## Recording`,
  `## Render`, `## Internal`. Keep new functions in the matching section;
  underscore-prefixed helpers go last, under `## Internal`.
- **Docstrings.** Every function opens with the `#`-framed block including
  `Parameters:` and a real `Example:`. No exceptions, including internals.
- **Comments explain why, not what** — e.g. why the cast is truncated after
  detaching, why `magick` needs `-coalesce`. Preserve these when refactoring.
- **State globals** `REC_PID` and `RECORDED` are module state; keep their
  lifecycle (`record` sets, `stop_recording`/`render` clear) intact.
- **shellcheck-clean.** Suppress only per-line, with an adjacent explanation.
- Every VHS feature parity claim in `README.md` links the upstream issue it
  addresses; keep that link when editing such a line.

## Git

- Branch: `develop`.
- Commit subjects: short, imperative, optional prefix (like '[doc]', '[ci]', '[examples]')
  (e.g. `Draft README, PLAN and s-vhs.sh`).
- Do not stage/unstage files unless explicitly asked.
