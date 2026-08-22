# Notes

## SetLoopOffset

`SetLoopOffset` is the odd one out: `agg --select 5..` *drops* the first five
seconds, while VHS's `LoopOffset` keeps every frame and only moves where the
loop starts. There is no cheap equivalent.


## ScrollUp / ScrollDown 📋

Missing. Would need tmux copy-mode plus `send-keys -X scroll-up`, and the
scrollback is captured only if the alternate screen is not in use.

## Screenshot 📋

Missing. Two plausible routes: `tmux capture-pane -p -e` for a text/ANSI dump,
or `agg --select <time>` to render a single frame out of the cast — though that
yields a one-frame GIF, not the PNG that VHS writes.
