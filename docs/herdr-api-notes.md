# herdr API notes (verified via wiring spike, herdr 0.7.0)

These were confirmed live against a running herdr session. They're the only
herdr surface herdr-review depends on.

## Identify the workspace / agent

`herdr agent list` → JSON, one entry per detected agent:
```json
{"agent":"claude","agent_status":"working","cwd":"/Users/persijano/me",
 "pane_id":"w8:p1","tab_id":"w8:t1","workspace_id":"w8","focused":true, ...}
```
- `pane_id` here is the **target for "Add all to chat"**.
- `agent_status` ∈ working | idle | blocked | done | unknown.

Env inside a herdr pane: `HERDR_SOCKET_PATH`, `HERDR_BIN_PATH`,
`HERDR_WORKSPACE_ID`, `HERDR_TAB_ID`, `HERDR_PANE_ID`.

## Open / close the sidebar pane (Foundation 1 ✅)

```
herdr pane split --current --direction right --ratio 0.35 --no-focus --cwd <repo>
herdr pane close <pane_id>
```
New pane id is found via `herdr pane list` (workspace pane that isn't the agent's).
For the plugin, declare `[[panes]] placement = "split"` and open via keybinding
or a `workspace.focused` event hook (for "always present").

## Send text to a pane / agent (Foundation 2 ✅)

```
herdr pane send-text <pane_id> "<literal text>"   # no Enter
herdr pane send-keys <pane_id> enter              # submit
herdr agent send  <agent_pane> "<literal text>"   # agent-targeted, literal
```
Confirmed the shell actually executes injected text (file side-effect test).
**"Add all to chat"** = `agent send <agent_pane> "path:start-end - comment\n..."`.

Caveat: `herdr pane read <id>` returns empty for an *unattended* pane (no client
rendering that tab). Don't rely on it; our sidebar renders itself.

## Subscribe to events (Foundation 3 ✅)

Connect the unix socket `$HERDR_SOCKET_PATH`, write newline-delimited JSON:
```json
{"id":"sub1","method":"events.subscribe","params":{"subscriptions":[
  {"type":"pane.created"},
  {"type":"pane.agent_status_changed","pane_id":"w8:p1"}
]}}
```
Reply: `{"id":"sub1","result":{"type":"subscription_started"}}` then a stream of
`{"data":{...},"type":...}` events. Useful types: `pane.agent_status_changed`
(turn boundaries → snapshot worktree for "last turn"; refresh on idle/done),
`pane.created`/`pane.closed`, `worktree.*`.

CLI alternative for one-shot waits: `herdr wait agent-status <pane> --status idle`.

## Diff scopes (plain git)

- Uncommitted: `git -C <repo> diff` (+ `git status --porcelain` for untracked).
- Branch: `git -C <repo> diff $(git merge-base origin/main HEAD)...HEAD`.
- Last turn: on each `pane.agent_status_changed → idle/done`, snapshot the
  worktree to a private ref (`git write-tree` w/ temp index → `update-ref
  refs/herdr-turns/N`); diff `refs/herdr-turns/{N-1}` vs `{N}` (Conductor's
  checkpointer pattern).
