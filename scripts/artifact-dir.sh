#!/usr/bin/env bash
# artifact-dir.sh — Return (and create) the artifact directory for a given skill.
# Usage: artifact-dir.sh <skill-name> [context-suffix]
# Output: absolute path (stdout)
# Side effect: mkdir -p on the output path
#
# Path convention: $HOME/.claude/projects/<encoded-path>/dev-loop/<skill>[/<suffix>]
# Encoding: absolute project root path with / replaced by -
# This matches Claude Code's own ~/.claude/projects/ naming convention.
# The leading - in the encoded path (e.g., -Users-kobig-...) is intentional — not a bug.
#
# Compatible with bash 3.x (macOS default).

set -euo pipefail

SKILL_NAME="${1:?artifact-dir.sh: skill name required}"
CONTEXT_SUFFIX="${2:-}"

# Derive project root
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Encode: replace every / with -
# Result has a leading - because the absolute path starts with /
ENCODED=$(echo "$PROJECT_ROOT" | tr '/' '-')

# Compose path
if [ -n "$CONTEXT_SUFFIX" ]; then
  ARTIFACT_DIR="$HOME/.claude/projects/${ENCODED}/dev-loop/${SKILL_NAME}/${CONTEXT_SUFFIX}"
else
  ARTIFACT_DIR="$HOME/.claude/projects/${ENCODED}/dev-loop/${SKILL_NAME}"
fi

mkdir -p "$ARTIFACT_DIR"
echo "$ARTIFACT_DIR"
