#!/usr/bin/env bash
# PostToolUseFailure hook — inject diagnostic context after Edit/Write failures.
# Reads error from hook payload and outputs hookSpecificOutput JSON.
# Non-blocking: Claude sees the context alongside the original error.
#
# NOTE: no set -euo pipefail — this hook must always exit 0 (soft hook).

# shellcheck source=lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

require_jq
INPUT=$(cat)

read -r ERROR < <(jq_fields '.error // ""')

# Build diagnostic hint based on error patterns
HINT=""

shopt -s nocasematch
if [[ "$ERROR" == *"old_string not found"* ]] || [[ "$ERROR" == *"did not find"* ]]; then
  HINT="The text to replace was not found in the file. The file may have changed since you last read it. Re-read the file with the Read tool and retry with the exact current content."
elif [[ "$ERROR" == *"permission denied"* ]]; then
  HINT="File is read-only or protected. Check file permissions or verify it's not in a protected location."
elif [[ "$ERROR" == *"no such file"* ]] || [[ "$ERROR" == *"not found"* ]]; then
  HINT="File does not exist at this path. Verify the path is correct or create the file first with the Write tool."
elif [[ "$ERROR" == *"outside"* ]] || [[ "$ERROR" == *"not allowed"* ]]; then
  HINT="Path is outside the allowed project directory."
else
  HINT="The edit operation failed. Re-read the file with the Read tool to get its current content, then retry with the exact text as it appears in the file."
fi
shopt -u nocasematch

jq -n --arg hint "Diagnostic hint: $HINT" \
  '{"hookSpecificOutput": {"hookEventName": "PostToolUseFailure", "additionalContext": $hint}}'

exit 0
