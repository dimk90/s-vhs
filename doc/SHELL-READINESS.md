# Shell Startup Readiness

## Problem

`Start` returns as soon as `tmux new-session -d` has spawned the configured
shell. The shell may not yet be ready to accept interactive input, so an
immediate `Run` or `Type` can race with its initialization:

```bash
Start
Run "$command"
```

When the race occurs, a pane capture can show the command twice:

```text
command
❯ command
```

This is present in the tmux pane itself, not an artifact of `watch` or
`capture-pane`. It may be absent from the rendered recording when the command
runs before `Show` and the application subsequently redraws the screen.

## Cause

A newly created pseudo-terminal initially has canonical input and kernel echo
enabled (`icanon echo`). If s-vhs sends input at this point, the terminal driver
echoes it before the shell has printed its prompt. Once Bash Readline, zsh ZLE,
or the fish reader starts, it switches the terminal to noncanonical, no-echo
mode (`-icanon -echo`), prints the prompt, and redraws the already buffered
input. The command is displayed twice but normally executes only once.

The race can also make the initial recording state nondeterministic or deliver
input while a native shell configuration is still starting.

## Required Fix

`Start` should contain an internal shell-readiness barrier and return only when
input can be sent safely. It should:

1. Obtain the pane TTY and current foreground command from tmux using
   `#{pane_tty}` and `#{pane_current_command}`.
2. Wait until the foreground command is the configured shell and `stty -a`
   reports both `-icanon` and `-echo` for the pane TTY.
3. Detect the shell or session exiting while it waits.
4. Fail with a `Start` error after a bounded timeout and clean up the session.
5. Print the successful `Start` message only after the barrier passes.

Checking the foreground command prevents a startup program that temporarily
uses raw terminal mode from being mistaken for the shell prompt. The terminal
mode check does not depend on prompt text and therefore works with themed,
literal, colored, and empty prompts.

A native shell configuration can execute arbitrary startup code or disable its
line editor entirely. The implementation must verify and define the behavior
for that case rather than silently falling back to a fixed delay.

## Rejected Workarounds

- `Wait '❯'` depends on one particular prompt and shifts synchronization to
  every recording script.
- A fixed `Sleep` is machine-dependent and remains a race.
- Sending a probe command is itself subject to the startup race and can signal
  before the shell has returned to its next prompt.

## Verification

- Start each supported shell—bash, zsh, and fish—and immediately send a command;
  `capture-pane` must contain one displayed command and one execution.
- Cover themed, literal, empty, and native prompt modes.
- Exercise a deliberately slow shell startup.
- Verify timeout and early shell-exit errors remove the tmux session.
- Start recording immediately after `Start` and confirm the first cast frame is
  stable.
