# herdr-review

A herdr-native review sidebar — a persistent right-pane TUI for reviewing an
agent's changes and sending comments back to the agent, inspired by Conductor's
review sidebar but living entirely in the terminal.

## Goal

A single pane, always present on the right of a herdr workspace, with tabs:

- **All files** — the repo file tree
- **Changes** — changed files + stats; click a file → its diff
- **Checks** — PR/CI status (via `gh`), git status, and the comment list

…and the core loop:

> select a line range in a diff → write a comment → repeat →
> **Add all to chat** → each comment is sent to the agent as `path:start-end - comment`.

Diff scopes: **uncommitted**, **all changes on branch**, and (nice-to-have)
**last turn** (snapshot the worktree on each agent `working→idle` transition).

## Design (minimal, no external review engine)

```
herdr plugin (herdr-plugin.toml)
  ├─ [[panes]] split (right)  → runs `herdr-review`
  ├─ keybind  prefix+d        → toggle
  └─ [[events]] pane.agent_status_changed → snapshot worktree for "last turn"

herdr-review  (one binary; ratatui)
  ├─ data:     git status / diff / merge-base   (+ gh later for Checks)
  ├─ comments: Vec<Comment { path, start, end, text }>   (in-memory)
  └─ herdr:    $HERDR_SOCKET_PATH → events.subscribe; agent.send for "Add all to chat"
```

No dependency on tuicr/hunk/revdiff — comments are a plain in-memory list; the
only "API" we lean on is the herdr CLI/socket (`agent send`, `events.subscribe`,
`pane.split`) plus `git`/`gh`.

## Status

Bootstrapping. First milestone: a wiring spike that proves the three foundations —
(1) a split pane opens reliably, (2) `herdr agent send` lands text in the agent
pane, (3) `events.subscribe` fires on `pane.agent_status_changed`.

## References

- herdr socket API: https://herdr.dev/docs/socket-api/
- herdr plugins: https://herdr.dev/docs/plugins/
