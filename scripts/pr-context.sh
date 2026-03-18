#!/usr/bin/env bash
# pr-context.sh — Consolidated PR metadata for review skills.
# Usage: pr-context.sh <pr-number> [base-branch]
# Output: compact JSON with PR metadata, size classification, and changed files.
set -euo pipefail

PR="${1:?Usage: pr-context.sh <pr-number> [base-branch]}"
BASE="${2:-develop}"

# PR metadata (1 API call)
PR_JSON=$(gh pr view "$PR" --json title,body,labels,author,comments 2>/dev/null || echo '{}')

# Parse all fields in one jq pass (avoids 5 separate subshells + parse cycles)
eval "$(printf '%s' "$PR_JSON" | jq -r '
  "TITLE=" + (.title // "" | @sh),
  "AUTHOR=" + (.author.login // "" | @sh),
  "BODY_PREVIEW=" + (.body // "" | .[0:200] | @sh),
  "LABELS_JSON=" + ([.labels[].name] | tojson | @sh),
  "COMMENT_COUNT=" + (.comments | length | tostring)
')" 2>/dev/null || { TITLE=""; AUTHOR=""; BODY_PREVIEW=""; LABELS_JSON='[]'; COMMENT_COUNT=0; }

# Diff stats
DIFF_STAT=$(gh pr diff "$PR" --stat 2>/dev/null || git diff "${BASE}...HEAD" --stat 2>/dev/null || echo "")
TOTAL_LINE=$(echo "$DIFF_STAT" | tail -1)
FILES_CHANGED=$(echo "$TOTAL_LINE" | grep -o '[0-9]* file' | grep -o '[0-9]*' || echo "0")
INSERTIONS=$(echo "$TOTAL_LINE" | grep -o '[0-9]* insertion' | grep -o '[0-9]*' || echo "0")
DELETIONS=$(echo "$TOTAL_LINE" | grep -o '[0-9]* deletion' | grep -o '[0-9]*' || echo "0")
LINES_CHANGED=$((INSERTIONS + DELETIONS))

# Size classification per review-conventions.md
if [ "$LINES_CHANGED" -le 400 ]; then
  SIZE="normal"
elif [ "$LINES_CHANGED" -le 1000 ]; then
  SIZE="large"
else
  SIZE="massive"
fi

# Changed files → JSON array
CHANGED_FILES=$(gh pr diff "$PR" --name-only 2>/dev/null || git diff "${BASE}...HEAD" --name-only 2>/dev/null || echo "")
FILES_JSON=$(echo "$CHANGED_FILES" | jq -Rs '[split("\n") | .[] | select(. != "")]')

jq -n \
  --argjson pr_num "${PR}" \
  --arg title "${TITLE}" \
  --arg author "${AUTHOR}" \
  --argjson labels "${LABELS_JSON}" \
  --arg base "${BASE}" \
  --argjson lines_changed "${LINES_CHANGED}" \
  --argjson files_changed "${FILES_CHANGED}" \
  --arg size "${SIZE}" \
  --argjson comments "${COMMENT_COUNT}" \
  --argjson changed_files "${FILES_JSON}" \
  --arg body_preview "${BODY_PREVIEW}" \
  '{pr:$pr_num,title:$title,author:$author,labels:$labels,base:$base,lines_changed:$lines_changed,files_changed:$files_changed,size:$size,comments:$comments,changed_files:$changed_files,body_preview:$body_preview}'
