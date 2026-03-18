#!/bin/bash
# bash-blockers.sh — Block bash commands that have dedicated Claude tools

cmd=$(jq -re '.tool_input.command // empty' 2>/dev/null) || exit 0
[[ -z "$cmd" ]] && exit 0

deny() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$1"
    exit 0
}

# Store regex patterns in variables — required for bash compatibility (avoids parse errors with special chars in [[ =~ ]])
RE_FIND='^[[:space:]]*(find|fd)[[:space:]]'
RE_CAT='^[[:space:]]*cat[[:space:]]'
RE_HEAD='^[[:space:]]*head[[:space:]]'
RE_TAIL='^[[:space:]]*tail[[:space:]]'
RE_PIPE_REDIRECT='[|>&]'
RE_FOLLOW='-(f[[:space:]]|-follow)'

# find/fd → Glob tool
[[ "$cmd" =~ $RE_FIND ]] && \
    deny "Use the Glob tool instead of bash find/fd — faster, respects .gitignore, structured output."

# cat (no pipe/redirect) → Read tool
[[ "$cmd" =~ $RE_CAT ]] && [[ ! "$cmd" =~ $RE_PIPE_REDIRECT ]] && \
    deny "Use the Read tool instead of bash cat/head/tail — supports line offset, limit, and structured output."

# head → Read tool
[[ "$cmd" =~ $RE_HEAD ]] && \
    deny "Use the Read tool instead of bash cat/head/tail — supports line offset, limit, and structured output."

# tail (without -f/--follow) → Read tool
[[ "$cmd" =~ $RE_TAIL ]] && [[ ! "$cmd" =~ $RE_FOLLOW ]] && \
    deny "Use the Read tool instead of bash cat/head/tail — supports line offset, limit, and structured output."
