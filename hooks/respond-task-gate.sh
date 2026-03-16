#!/usr/bin/env bash
# TaskCompleted hook for dlc-respond
# Verifies that completed fix tasks include file:line evidence.
# Exit code 2 = block completion and send feedback to teammate.

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract task name and tool output
TASK_NAME=$(echo "$INPUT" | jq -r '.task_name // empty')
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty')

# Only gate respond-related tasks
if ! echo "$TASK_NAME" | grep -qi "respond\|fix-thread\|reply-thread"; then
  exit 0
fi

# Check if the output contains file:line evidence
# Pattern: filename.ext:number or `filename.ext:number`
if ! echo "$TOOL_OUTPUT" | grep -qE '[a-zA-Z0-9_/.-]+\.[a-zA-Z]+:[0-9]+'; then
  echo '{"decision": "block", "reason": "Your output must include file:line evidence. Cite the specific file and line number you fixed."}' >&2
  exit 2
fi

exit 0
