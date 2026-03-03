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
each_skill_name() {
  for skill_dir in "$SKILLS_DIR"/*/; do
    basename "$skill_dir"
  done
}

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
  while IFS= read -r name; do
    local dst="$CLAUDE_SKILLS/$name"
    local target
    target=$(readlink "$dst" 2>/dev/null) \
      && echo "  ✓ $name → $target" \
      || echo "  ✗ $name (not linked)"
  done < <(each_skill_name)
}

# ── Main ──────────────────────────────────────────────────────────────────────
case "${1:-}" in
  --list)
    list_status
    ;;
  "")
    echo "Linking all skills → $CLAUDE_SKILLS"
    while IFS= read -r name; do
      link_skill "$name"
    done < <(each_skill_name)
    ;;
  *)
    link_skill "$1"
    ;;
esac
