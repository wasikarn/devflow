#!/usr/bin/env bash
# Inject project context on fresh session startup.
# Output goes to stdout → added to Claude's context.
# Lightweight: only git state + project detection. CLAUDE.md handles the rest.

# Git state
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$BRANCH" ]; then
  echo "## Session Context"
  echo "- Branch: \`$BRANCH\`"
  DIRTY_COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  if [ "$DIRTY_COUNT" -gt 0 ]; then
    echo "- $DIRTY_COUNT uncommitted change(s) — review before starting new work"
  fi
  STASH_COUNT=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  if [ "$STASH_COUNT" -gt 0 ]; then
    echo "- $STASH_COUNT stash(es) saved"
  fi
fi
