#!/usr/bin/env bash
# TeammateIdle hook for dlc-respond
# Nudges idle Fixer teammates to stay on task.
# Exit code 2 = send feedback and keep teammate working.

set -euo pipefail

INPUT=$(cat)

TEAM_NAME=$(echo "$INPUT" | jq -r '.team_name // empty')

if ! echo "$TEAM_NAME" | grep -qi "respond"; then
  exit 0
fi

echo '{"decision": "block", "reason": "You are idle. Continue fixing your assigned threads and message the team lead when done. If blocked, message lead with: thread number, what you tried, and where you are stuck."}' >&2
exit 2
