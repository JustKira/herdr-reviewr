#!/usr/bin/env bash
# Open / toggle the reviewr sidebar as a right split. Invoked by herdr with the plugin
# runtime env set (HERDR_BIN_PATH, HERDR_PANE_ID, HERDR_WORKSPACE_ID, HERDR_PLUGIN_*,
# HERDR_PLUGIN_CONTEXT_JSON, and HERDR_PLUGIN_EVENT_JSON for events).
#
#   sidebar.sh toggle   key action: open the sidebar, or close it if already open
#   sidebar.sh open     event hook: open the sidebar if not already open (e.g. worktree.created)
#
# No `set -e`: a transient jq/herdr hiccup must not silently abort the toggle; each step is
# tolerant and results are checked explicitly.
set -uo pipefail

# herdr runs plugin commands with a minimal PATH; ensure jq/git resolve on common installs.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

mode="${1:-toggle}"
H="${HERDR_BIN_PATH:-herdr}"

ws="${HERDR_WORKSPACE_ID:-}"
pane="${HERDR_PANE_ID:-}"
cwd=""
[ -n "${HERDR_PLUGIN_CONTEXT_JSON:-}" ] &&
  cwd=$(printf '%s' "$HERDR_PLUGIN_CONTEXT_JSON" | jq -r '.focused_pane_cwd // .workspace_cwd // empty' 2>/dev/null)

# An event fires without a focused pane; target the new worktree's workspace from the payload
# (worktree.created shape: .data.workspace.workspace_id, .data.workspace.worktree.checkout_path).
if [ -n "${HERDR_PLUGIN_EVENT_JSON:-}" ]; then
  ev="$HERDR_PLUGIN_EVENT_JSON"
  ws=$(printf '%s' "$ev" | jq -r '.data.workspace.workspace_id // .data.worktree.open_workspace_id // empty' 2>/dev/null)
  cwd=$(printf '%s' "$ev" | jq -r '.data.workspace.worktree.checkout_path // .data.worktree.path // empty' 2>/dev/null)
  pane=""
fi

# A workspace is required to key state and target the split; without it, do nothing rather
# than collide every workspace on a shared `pane-default` state file.
[ -n "$ws" ] || exit 0

statedir="${HERDR_PLUGIN_STATE_DIR:-${TMPDIR:-/tmp}}"
mkdir -p "$statedir" 2>/dev/null
state="$statedir/pane-$ws"

# Is a sidebar we opened still alive in this workspace?
existing=""
if [ -f "$state" ]; then
  prev=$(cat "$state" 2>/dev/null)
  if [ -n "$prev" ] && "$H" pane list --workspace "$ws" 2>/dev/null \
      | jq -e --arg p "$prev" '.result.panes[] | select(.pane_id == $p)' >/dev/null 2>&1; then
    existing="$prev"
  else
    rm -f "$state" 2>/dev/null # stale (closed via `q`)
  fi
fi

# Already open: toggle closes it; open is idempotent (don't stack a duplicate pane).
if [ -n "$existing" ]; then
  if [ "$mode" = "toggle" ]; then
    "$H" plugin pane close "$existing" >/dev/null 2>&1
    rm -f "$state" 2>/dev/null
  fi
  exit 0
fi

# Only open inside a git repo.
[ -n "$cwd" ] && git -C "$cwd" rev-parse --show-toplevel >/dev/null 2>&1 || exit 0

# A split plugin pane must target an existing pane; for an event (no focused pane), use the
# target workspace's first pane.
if [ -z "$pane" ]; then
  pane=$("$H" pane list --workspace "$ws" 2>/dev/null | jq -r '.result.panes[0].pane_id // empty' 2>/dev/null)
fi
[ -n "$pane" ] || exit 0

new=$("$H" plugin pane open --plugin "${HERDR_PLUGIN_ID:-reviewr}" --entrypoint sidebar \
  --placement split --direction right --target-pane "$pane" --cwd "$cwd" --no-focus 2>/dev/null \
  | jq -r '.result.plugin_pane.pane.pane_id // empty' 2>/dev/null)
[ -n "$new" ] && printf '%s' "$new" > "$state"
