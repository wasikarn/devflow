#!/usr/bin/env bats
# Tests for check-deps.sh — SessionStart hook (startup).

HOOK="$BATS_TEST_DIRNAME/../../hooks/check-deps.sh"

setup() {
  TMPDIR_TEST="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test "all required tools present → exit 0 (no blocking)" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
}

@test "missing required tool → warning output contains tool name" {
  # Create a fake bin dir with only bash (so the subshell runs) but no jq/git/gh/rtk
  mkdir -p "$TMPDIR_TEST/notools"
  ln -sf "$(command -v bash)" "$TMPDIR_TEST/notools/bash"
  run bash -c "export PATH='$TMPDIR_TEST/notools'; bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "jq" ]]
}

@test "exit code always 0 even when tools are missing (never blocks)" {
  mkdir -p "$TMPDIR_TEST/empty"
  ln -sf "$(command -v bash)" "$TMPDIR_TEST/empty/bash"
  run bash -c "export PATH='$TMPDIR_TEST/empty'; bash '$HOOK'"
  [ "$status" -eq 0 ]
}

@test "warning output contains install instructions when tool missing" {
  mkdir -p "$TMPDIR_TEST/notools2"
  ln -sf "$(command -v bash)" "$TMPDIR_TEST/notools2/bash"
  run bash -c "export PATH='$TMPDIR_TEST/notools2'; bash '$HOOK'"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Install" ]]
}
