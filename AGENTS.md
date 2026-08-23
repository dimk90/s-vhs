# AGENTS.md

## Project

`s-vhs` — a terminal recorder in the spirit of
[VHS](https://github.com/charmbracelet/vhs): a thin Bash wrapper around
`tmux` + `asciinema` + output-specific renderers. A recording is a user-written
shell script that sources `s-vhs.sh` and calls its functions. Every recording
produces a `.cast` — retained when requested as an output, otherwise temporary
and used only to render the other outputs (GIF, SVG).

## Layout

| Path                 | Purpose                                                      |
| -------------------- | ------------------------------------------------------------ |
| `s-vhs.sh`           | The whole implementation. Sourced library + two subcommands. |
| `README.md`          | User-facing docs.                                            |
| `CHANGELOG.md`       | One line per significant change, newest version on top.      |
| `doc/REFERENCE.md`   | Commands today + planned settings. Keep in sync.             |
| `doc/PLAN.md`        | Roadmap / checklist. Tick boxes when a task lands.           |
| `doc/INTRO.md`       | How the pipeline works, for users.                           |
| `doc/SVG.md`         | Animated SVG pitfalls and workarounds, for users.            |
| `doc/DEBUG.md`       | Debugging recording scripts (`watch`, live pane).            |
| `doc/DEPLOY.md`      | GitHub Pages deployment (remote imports, skill).             |
| `doc/RELEASE.md`     | Release procedure, read when cutting a release.              |
| `doc/HISTORY.md`     | Verbatim archive of code removed from `s-vhs.sh`.            |
| `skills/*/SKILL.md`  | Agent skills teaching recording scripts; published to Pages. |
| `examples/`          | Example recording scripts, rendered output, catalogue.       |
| `scripts/release.sh` | Release tooling; its own changes stay out of the changelog.  |

No build system, no test suite. The only CI is
`.github/workflows/release.yml` (tag push → GitHub release + Pages deploy).
Verification is manual: run a recording script and inspect or replay every
requested output.

## Dependencies

Runtime: `bash`, `tmux`, `asciinema`; `agg` for GIF output, `asg` for SVG.
Dev: `shellcheck`; `gh` optionally, to validate the agent skill during a
release.

## Conventions

Follow the `shell-code` and `code-style` skills; load `s-vhs-recording` when
writing or running a `*.rec.sh` script. Project-specific points:

- **Sourced library with subcommands.** Sourcing `s-vhs.sh` only defines
  functions and installs the `EXIT` trap (`_svhs_cleanup`); executing it —
  including the piped `curl … | bash -s -- new …` — runs `new` or `watch` and
  exits. Each is a thin wrapper around a function usable from a recording
  script. Do not grow it into a CLI or add a general `main`; dispatch detects
  execution, never `$1`, which a sourced library inherits from its caller.
- **Bash 3.2 compatible.** macOS still ships bash 3.2.57 as `/bin/bash`: no
  bash 4+ syntax (`declare -A`, `mapfile`, `${var,,}`, `&>>`, namerefs), guard
  every empty-array expansion (`${arr[@]+"${arr[@]}"}`), and use only utilities
  and flags present in the BSD userland too (`head -c`, not `truncate -s`).
- **Configuration is functions only.** `Set*` functions are the only supported
  way to change settings; never expose or document setting variables or
  pre-source assignments. Require every `Set*` call before `Start` and reject
  reconfiguration afterwards, relaxing that only for a concrete use case.
- **Validation.** Scalar values are validated in their setter and reported
  immediately; required overall configuration is validated in `Start` before
  starting tmux or the recorder. Preserve deliberate pass-through values (such
  as custom renderer themes) instead of an allowlist. Internal defaults are
  initialized while sourcing.
- **Messages.** Informational messages go to stdout with a `::: ` prefix
  (`printf '::: Wrote %s\n' "$output"`), matching asciinema. Errors go to
  stderr with no prefix, named after the reporting command
  (`printf 'Start: session has already started\n' >&2`).
- **Sections.** `## Version`, `## Settings / Defaults / Consts`,
  `## Template`, `## Session`, `## Input`, `## Recording`, `## Render`,
  `## Internal`, `## CLI`. Keep new functions in the matching section — one
  that only sends input to the session (`Type`, `Key`, `Wait`, `Run`) belongs
  to `## Input`, one that drives the recorder (`Show`, `Hide`) to
  `## Recording`.
- **Version.** The literal in `svhs_version` is the only place the version
  number is written.
- **Naming tiers.** VHS-like CamelCase (`Type`, `SetRows`) is reserved for
  recording commands and setters. Other public helpers use `svhs_`
  (`svhs_version`); private functions and state use `_svhs_` / `_SVHS_`.
- **Recorder state.** Preserve its lifecycle: `Show` stores the recorder PID
  and marks the first recorded segment, `Hide`/`Render` clear the active PID,
  and later `Show` calls append.
- **Outputs.** `SetOutput` is repeatable; each call adds an output. `Render`
  invokes only the tools needed for the requested outputs, so a cast-only
  recording must not invoke `agg`, `asg` or any other renderer.
- **Template.** The scaffold written by `_svhs_new` is a bare starting point,
  not an example: an active `SetOutput`, common settings commented out with
  their defaults, a minimal body. Its heredoc in `s-vhs.sh` is the source of
  truth; the only other copy is the README block, updated in the same change.
  Do not add a third one under `examples/`.
- **Reference is part of the change.** Every added, removed, renamed or
  behaviour-changed public command needs its row in `doc/REFERENCE.md` in the
  same change — signature, default value and matching section. It is a lookup
  table, not a guide: one line per command, no rationale, examples or section
  prose; a rule about a single command goes into that command's row even if the
  cell grows, and prose outside the tables is justified only for a rule global
  to a section. Rationale and design notes belong in `README.md` or here.
- **Skill.** `skills/s-vhs-recording/SKILL.md` teaches an agent to write
  recordings, so it stays a self-contained single file — the release workflow
  publishes it verbatim as `skill` and `skill-<tag>`. Its directory layout
  follows the [Agent Skills spec](https://agentskills.io/specification) so
  `gh skill install` discovers it, which requires the `name` in the front
  matter to match the directory name. It teaches judgement, not every command:
  a new setting earns a line only when using it well needs one, while a changed
  or removed command it mentions is updated in the same change.
- **Changelog is part of the change.** Every significant fix, change or
  addition gets one clear line in `CHANGELOG.md` under the unreleased
  version's `### New`, `### Changed` or `### Fixed` heading — what a user
  notices, not how it was implemented. Skip purely internal refactors, doc
  touch-ups and formatting.
- **Examples.** A script under `examples/` renders at `SetFontSize 40` or
  larger (smaller looks soft once a README scales the GIF down) and keeps the
  default shell, which carries no personal configuration into the recording.
  Call `SetShell` or `SetPrompt` only in an example about them. Keep the
  catalogue in `examples/README.md` in sync when adding or merging one.
- **Parity claims.** Every VHS feature parity claim in `README.md` links the
  upstream issue it addresses; keep that link when editing such a line.

## Git

- Branch: `develop`.
- Commit subjects: short, imperative, optional prefix (like `[doc]`, `[ci]`,
  `[examples]`) — e.g. `Draft README, PLAN and s-vhs.sh`.
