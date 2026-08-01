# AGENTS.md

Guidance for AI agents working in the `s-vhs` repository.

## Project

`s-vhs` — a terminal recorder in the spirit of
[VHS](https://github.com/charmbracelet/vhs), built as a thin Bash wrapper
around `tmux` + `asciinema` + output-specific renderers. Recordings are driven
by a user-written shell script that sources `s-vhs.sh` and calls its functions.
Every recording uses a `.cast`; it is retained when requested as an output and
otherwise kept only temporarily while producing outputs such as GIF
(SVG/MP4 planned).

Selling points to preserve when changing behaviour: sharp output (no GIF
quality loss), no timing drift across resolutions, terminal size in rows/cols
instead of pixels, no browser/Node dependency.

Status: early draft, pre-`v0.1.0`. The public function names are **not** frozen
— see `doc/PLAN.md`, which calls for renaming toward VHS-like names
(`Type`, `Enter`, `SetRows`, ...).

## Layout

| Path               | Purpose                                                       |
| ------------------ | ------------------------------------------------------------- |
| `s-vhs.sh`         | The whole implementation. Sourced library, never executed.    |
| `README.md`        | User-facing docs; many sections are still `> TODO:`.          |
| `doc/REFERENCE.md` | Reference of every command implemented today. Keep in sync.   |
| `doc/COMMANDS.md`  | VHS parity table and target API design notes.                 |
| `doc/PLAN.md`      | Roadmap / checklist. Update checkboxes when a task lands.     |
| `doc/HISTORY.md`   | Verbatim archive of code removed from `s-vhs.sh`.             |
| `examples/`        | Example recording scripts and their rendered output.          |

No build system, no test suite, no CI. Verification is manual: run a recording
script and inspect or replay every requested output.

## Dependencies

Core runtime: `bash`, `tmux`, `asciinema`.
Output-specific runtime: `agg` for GIF output.
Dev: `shellcheck`.

## Conventions

Follow the `shell-code` and `code-style` skills. Project-specific points:

- **Sourced library, not a program.** `s-vhs.sh` has no `main`, no arg parsing,
  and must stay safe to `source`. It installs an `EXIT` trap (`_svhs_cleanup`)
  in the sourcing script's shell.
- **Public configuration uses functions only.** A recording script sources
  `s-vhs.sh` first, then configures it through `Set*` functions. Do not expose
  or document setting variables, or support pre-source assignments as a second
  API. Public setters are the only supported way to modify settings.
- **Configuration phase.** Require every `Set*` call before `Start`, and reject
  attempts to reconfigure a session after it has started. Relax this rule for a
  specific setting only when a concrete use case requires it.
- **Setter validation.** Validate ordinary scalar values in the corresponding
  setter and report invalid values immediately. Preserve deliberate pass-through
  values, such as custom renderer themes, instead of validating against a
  restrictive allowlist.
- **Start validation.** Validate required overall configuration in `Start`
  before starting tmux or the recorder. Initialize internal defaults while
  sourcing.
- **Sections.** `## Settings`, `## Session`, `## Input`, `## Recording`,
  `## Render`, `## Internal`. Keep new functions in the matching section.
- **Recorder state.** Preserve its lifecycle: `Show` stores the recorder PID
  and marks the first recorded segment, `Hide`/`Render` clear the active PID,
  and later `Show` calls append.
- **Outputs.** `SetOutput` is repeatable and each call adds an output. An
  explicitly requested `.cast` is retained at that path; when no `.cast` is
  requested, record to a temporary cast and remove it after producing the
  requested outputs. `Render` invokes only tools needed for those outputs, so a
  cast-only recording must not invoke `agg` or any other renderer/converter.
- **Reference is part of the change.** Every added, removed, renamed, or
  behaviour-changed public command must be reflected in
  [`doc/REFERENCE.md`](doc/REFERENCE.md) in the same change — including its
  signature, default value, and section (`## Settings` or `## Commands`).
  `doc/REFERENCE.md` documents the current implementation; `doc/COMMANDS.md`
  tracks VHS parity and the planned API.
- Every VHS feature parity claim in `README.md` links the upstream issue it
  addresses; keep that link when editing such a line.

## Git

- Branch: `develop`.
- Commit subjects: short, imperative, optional prefix (like '[doc]', '[ci]', '[examples]')
  (e.g. `Draft README, PLAN and s-vhs.sh`).
- Do not stage/unstage files unless explicitly asked.
