#!/usr/bin/env bats
# Tests for cleanup-artifacts.sh — SessionStart hook (async).

HOOK="$BATS_TEST_DIRNAME/../../hooks/cleanup-artifacts.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  export CLAUDE_PLUGIN_DATA="$TMPDIR_TEST/plugin-data"
  mkdir -p "$CLAUDE_PLUGIN_DATA"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test "old artifact .md files (mtime >7 days) → deleted" {
  # Create two old artifact files
  local old1="$CLAUDE_PLUGIN_DATA/old-plan.md"
  local old2="$CLAUDE_PLUGIN_DATA/old-review.md"
  touch "$old1" "$old2"
  # Set mtime to 8 days ago
  touch -t "$(date -v-8d '+%Y%m%d%H%M' 2>/dev/null || date -d '8 days ago' '+%Y%m%d%H%M')" "$old1" "$old2"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ ! -f "$old1" ]
  [ ! -f "$old2" ]
}

@test "recent artifact .md files → preserved" {
  local recent="$CLAUDE_PLUGIN_DATA/current-plan.md"
  touch "$recent"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -f "$recent" ]
}

@test "missing artifacts dir → exits 0 gracefully" {
  # Point to non-existent directory
  export CLAUDE_PLUGIN_DATA="$TMPDIR_TEST/nonexistent"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}
