#!/usr/bin/env bash
# detect-project.sh — Detect tathep project from git remote and output config JSON.
# Usage: bash detect-project.sh [project-root]
# Output: {"project":"...","repo":"...","validate":"...","review_skill":"...","base_branch":"...","branch":"..."}
#
# Compatible with bash 3.x (macOS default).

set -euo pipefail

PROJECT_ROOT="${1:-.}"
cd "$PROJECT_ROOT" 2>/dev/null || true

# Get current branch
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

# Get remote URL and extract repo slug
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
REPO_SLUG=$(echo "$REMOTE_URL" | sed 's/.*[:/]\([^/]*\/[^.]*\).*/\1/' 2>/dev/null || echo "")

# Match against known projects
PROJECT="unknown"
REPO=""
VALIDATE=""
REVIEW_SKILL=""
BASE_BRANCH="main"

case "$REMOTE_URL" in
  *bd-eye-platform-api*)
    PROJECT="tathep-platform-api"
    REPO="100-Stars-Co/bd-eye-platform-api"
    VALIDATE="npm run validate:all"
    REVIEW_SKILL="tathep-api-review-pr"
    BASE_BRANCH="develop"
    ;;
  *bluedragon-eye-website*)
    PROJECT="tathep-website"
    REPO="100-Stars-Co/bluedragon-eye-website"
    VALIDATE="npm run ts-check && npm run lint:fix && npm test"
    REVIEW_SKILL="tathep-web-review-pr"
    BASE_BRANCH="develop"
    ;;
  *bluedragon-eye-admin*)
    PROJECT="tathep-admin"
    REPO="100-Stars-Co/bluedragon-eye-admin"
    VALIDATE="npm run ts-check && npm run lint@fix && npm run test"
    REVIEW_SKILL="tathep-admin-review-pr"
    BASE_BRANCH="develop"
    ;;
  *tathep-ai-agent-python*)
    PROJECT="tathep-ai-agent"
    REPO="100-Stars-Co/tathep-ai-agent-python"
    VALIDATE="uv run black --check . && uv run mypy ."
    REVIEW_SKILL="tathep-agent-review-pr"
    BASE_BRANCH="develop"
    ;;
  *tathep-video-processing*)
    PROJECT="tathep-video"
    REPO="100-Stars-Co/tathep-video-processing"
    VALIDATE="bun run check && bun run test"
    REVIEW_SKILL="tathep-video-review-pr"
    BASE_BRANCH="develop"
    ;;
esac

# Build JSON manually (no jq dependency)
echo "{\"project\":\"${PROJECT}\",\"repo\":\"${REPO}\",\"validate\":\"${VALIDATE}\",\"review_skill\":\"${REVIEW_SKILL}\",\"base_branch\":\"${BASE_BRANCH}\",\"branch\":\"${BRANCH}\"}"
