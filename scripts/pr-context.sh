#!/usr/bin/env bash
# pr-context.sh — Consolidated PR metadata for review skills.
# Usage: pr-context.sh <pr-number> [base-branch]
# Output: compact JSON with PR metadata, size classification, and changed files.
set -euo pipefail

PR="${1:?Usage: pr-context.sh <pr-number> [base-branch]}"
BASE="${2:-develop}"

# PR metadata (1 API call)
PR_JSON=$(gh pr view "$PR" --json title,body,labels,author,comments 2>/dev/null || echo '{}')
TITLE=$(echo "$PR_JSON" | grep -o '"title":"[^"]*"' | head -1 | sed 's/"title":"//;s/"$//' || echo "")
AUTHOR=$(echo "$PR_JSON" | grep -o '"login":"[^"]*"' | head -1 | sed 's/"login":"//;s/"$//' || echo "")
BODY=$(echo "$PR_JSON" | grep -o '"body":"[^"]*"' | head -1 | sed 's/"body":"//;s/"$//' | cut -c1-200 || echo "")
# Labels — extract array
LABELS_RAW=$(echo "$PR_JSON" | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"$//' | tr '\n' ',' | sed 's/,$//' || echo "")
# Comments — count only
COMMENT_COUNT=$(echo "$PR_JSON" | grep -c '"body"' || true)
# Subtract 1 for PR body itself
COMMENT_COUNT=$((COMMENT_COUNT > 0 ? COMMENT_COUNT - 1 : 0))

# Diff stats
DIFF_STAT=$(gh pr diff "$PR" --stat 2>/dev/null || git diff "${BASE}...HEAD" --stat 2>/dev/null || echo "")
# Parse total line: " N files changed, N insertions(+), N deletions(-)"
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

# Changed files list
CHANGED_FILES=$(gh pr diff "$PR" --name-only 2>/dev/null || git diff "${BASE}...HEAD" --name-only 2>/dev/null || echo "")
FILES_JSON=""
while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -n "$FILES_JSON" ] && FILES_JSON="${FILES_JSON},"
  FILES_JSON="${FILES_JSON}\"${f}\""
done <<EOF
$CHANGED_FILES
EOF

# Escape body for JSON (basic: replace newlines, quotes, backslashes)
BODY=$(echo "$BODY" | tr '\n' ' ' | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/ /g')

# Build labels JSON array
LABELS_JSON=""
if [ -n "$LABELS_RAW" ]; then
  IFS=',' read -r -a LABEL_ARR <<< "$LABELS_RAW" 2>/dev/null || LABEL_ARR=()
  for l in "${LABEL_ARR[@]}"; do
    [ -n "$LABELS_JSON" ] && LABELS_JSON="${LABELS_JSON},"
    LABELS_JSON="${LABELS_JSON}\"${l}\""
  done
fi

echo "{\"pr\":${PR},\"title\":\"${TITLE}\",\"author\":\"${AUTHOR}\",\"labels\":[${LABELS_JSON}],\"base\":\"${BASE}\",\"lines_changed\":${LINES_CHANGED},\"files_changed\":${FILES_CHANGED},\"size\":\"${SIZE}\",\"comments\":${COMMENT_COUNT},\"changed_files\":[${FILES_JSON}],\"body_preview\":\"${BODY}\"}"
