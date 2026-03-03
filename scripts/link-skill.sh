#!/usr/bin/env bash
# link-skill.sh — Create ~/.claude/skills/ symlinks for skills in this repo.
# Usage:
#   bash scripts/link-skill.sh            # link all skills in skills/
#   bash scripts/link-skill.sh spec-kit   # link one skill by name
#   bash scripts/link-skill.sh --list     # show current link status

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"

mkdir -p "$CLAUDE_SKILLS"

# ── Helpers ───────────────────────────────────────────────────────────────────
link_skill() {
  local name="$1"
  local src="$SKILLS_DIR/$name"
  local dst="$CLAUDE_SKILLS/$name"

  if [[ ! -d "$src" ]]; then
    echo "  ✗ $name — not found in skills/" >&2
    return 1
  fi

  if [[ -L "$dst" ]]; then
    local existing; existing=$(readlink "$dst")
    if [[ "$existing" == "$src" ]]; then
      echo "  ✓ $name — already linked"
      return 0
    fi
    echo "  ~ $name — relinking ($existing → $src)"
    ln -sf "$src" "$dst"
  elif [[ -e "$dst" ]]; then
    echo "  ✗ $name — $dst exists and is not a symlink, skipping" >&2
    return 1
  else
    ln -s "$src" "$dst"
    echo "  + $name — linked"
  fi
}

list_status() {
  echo "Skills in repo:"
  for skill_dir in "$SKILLS_DIR"/*/; do
    local name; name=$(basename "$skill_dir")
    local dst="$CLAUDE_SKILLS/$name"
    if [[ -L "$dst" ]]; then
      echo "  ✓ $name → $(readlink "$dst")"
    else
      echo "  ✗ $name (not linked)"
    fi
  done
}

# ── Main ──────────────────────────────────────────────────────────────────────
case "${1:-}" in
  --list)
    list_status
    ;;
  "")
    echo "Linking all skills → $CLAUDE_SKILLS"
    for skill_dir in "$SKILLS_DIR"/*/; do
      link_skill "$(basename "$skill_dir")"
    done
    ;;
  *)
    link_skill "$1"
    ;;
esac
