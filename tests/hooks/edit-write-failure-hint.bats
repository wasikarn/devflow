#!/usr/bin/env bats
# Tests for edit-write-failure-hint.sh — PostToolUseFailure hook.

HOOK="$BATS_TEST_DIRNAME/../../hooks/edit-write-failure-hint.sh"

run_hook() {
  echo "$1" | bash "$HOOK"
}

@test "old_string not found error → re-read hint in output" {
  run run_hook '{"error":"old_string not found in file","tool_input":{}}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Re-read" ]] || [[ "$output" =~ "re-read" ]] || [[ "$output" =~ "Read tool" ]]
}

@test "permission denied error → permission hint in output" {
  run run_hook '{"error":"permission denied: /etc/passwd","tool_input":{}}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "ermission" ]]
}

@test "no such file error → file not found hint in output" {
  run run_hook '{"error":"no such file or directory: /missing/path.ts","tool_input":{}}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "oes not exist" ]] || [[ "$output" =~ "path" ]] || [[ "$output" =~ "Write tool" ]]
}

@test "outside error → path restriction hint in output" {
  run run_hook '{"error":"path outside allowed directory","tool_input":{}}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "outside" ]] || [[ "$output" =~ "allowed" ]]
}

@test "unknown error → generic hint in output" {
  run run_hook '{"error":"something unexpected happened","tool_input":{}}'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "failed" ]] || [[ "$output" =~ "Read tool" ]] || [[ "$output" =~ "retry" ]]
}

@test "exit code is always 0 regardless of error type" {
  run run_hook '{"error":"catastrophic meltdown","tool_input":{}}'
  [ "$status" -eq 0 ]
}

@test "output is valid JSON with hookSpecificOutput" {
  run run_hook '{"error":"old_string not found","tool_input":{}}'
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput' > /dev/null
  echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "PostToolUseFailure"' > /dev/null
}
