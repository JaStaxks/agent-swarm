#!/usr/bin/env bash
# agent-swarm auto mode. Prints nothing (and changes nothing) unless "auto": true
# is set. The project's .claude/swarm.json wins over ~/.claude/swarm.json when it
# has an "auto" key. Toggle with: /swarm auto on|off [--global]
auto_of() {
  [ -f "$1" ] || return 1
  tr -d ' \t\r\n' < "$1" | grep -o '"auto":\(true\|false\)' | head -n1 | cut -d: -f2
}
project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
val="$(auto_of "$project_dir/.claude/swarm.json")"
[ -n "$val" ] || val="$(auto_of "$HOME/.claude/swarm.json")"
[ "$val" = "true" ] || exit 0
cat <<'MSG'
agent-swarm auto mode is on. For every task that is multi-part (several features, files, assets or sources; sweeps, audits, migrations; research or drafting across many items), use the agent-swarm:swarm skill without waiting to be asked: triage the tier, pick the pack, and run it. Small tasks (one edit, one question, a handful of tool calls) still run inline as tier 0. The user can turn this off with /swarm auto off.
MSG
exit 0
