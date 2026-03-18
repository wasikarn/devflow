#!/usr/bin/env bash
# check-deps.sh — SessionStart hook (startup)
# Checks required tools for claude-code-skills plugin.
# Outputs a warning to Claude's context if any are missing.
# Silent if all tools are present.

MISSING=""

check() {
  local tool="$1" install="$2" note="$3"
  if ! command -v "$tool" > /dev/null 2>&1; then
    MISSING="${MISSING}\n- \`${tool}\` — ${note}\n  Install: ${install}"
  fi
}

check "jq"  "brew install jq"                          "required by workflow hooks"
check "git" "pre-installed on most systems"            "required by all DLC skills"
check "gh"  "brew install gh && gh auth login"         "required by dlc-build, dlc-review, dlc-respond, dlc-debug, merge-pr"
check "rtk" "brew install rtk  (https://rtk-ai.app/)" "recommended — token-optimized git/gh output in DLC skills"

if [ -n "$MISSING" ]; then
  printf "## ⚠️  claude-code-skills: Missing Dependencies\n\nThe following tools are not installed. Some skills and hooks will not work correctly:\n%b\n\nInstall missing tools and restart Claude Code to dismiss this warning.\n" "$MISSING"
fi
