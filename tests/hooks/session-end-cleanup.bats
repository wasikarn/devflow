#!/usr/bin/env bats
# Tests for session-end-cleanup.sh — SessionEnd hook (async).

HOOK="$BATS_TEST_DIRNAME/../../hooks/session-end-cleanup.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  export CLAUDE_PLUGIN_DATA="$TMPDIR_TEST/plugin-data"
  mkdir -p "$CLAUDE_PLUGIN_DATA"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test ".tmp files in plugin data dir → deleted" {
  local tmp_file="$CLAUDE_PLUGIN_DATA/session.tmp"
  touch "$tmp_file"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ ! -f "$tmp_file" ]
}

@test ".lock files in plugin data dir → deleted" {
  local lock_file="$CLAUDE_PLUGIN_DATA/process.lock"
  touch "$lock_file"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ ! -f "$lock_file" ]
}

@test "regular .md files → preserved" {
  local md_file="$CLAUDE_PLUGIN_DATA/plan.md"
  touch "$md_file"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -f "$md_file" ]
}

@test "missing plugin data dir → exits 0 gracefully" {
  export CLAUDE_PLUGIN_DATA="$TMPDIR_TEST/nonexistent"

  run bash "$HOOK"
  [ "$status" -eq 0 ]
}
