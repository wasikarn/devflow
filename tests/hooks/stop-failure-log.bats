#!/usr/bin/env bats
# Tests for stop-failure-log.sh — StopFailure hook.

HOOK="$BATS_TEST_DIRNAME/../../hooks/stop-failure-log.sh"

run_hook() {
  echo "$1" | bash "$HOOK"
}

setup() {
  TMPDIR_TEST="$(mktemp -d)"
  export HOME="$TMPDIR_TEST"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test "rate limit error with LOG=1 → log file created" {
  run bash -c "
    export HOME='$TMPDIR_TEST'
    export LOG=1
    echo '{\"error\":\"rate_limit_error\",\"error_details\":\"Too many requests\"}' | bash '$HOOK'
  "
  [ "$status" -eq 0 ]
  # Log file must exist under the overridden HOME
  local log_file
  log_file="$TMPDIR_TEST/.claude/session-logs/$(date +%Y-%m-%d).log"
  [ -f "$log_file" ]
  grep -q "rate_limit_error" "$log_file"
}

@test "LOG=0 → no log file created" {
  run bash -c "
    export HOME='$TMPDIR_TEST'
    export LOG=0
    echo '{\"error\":\"rate_limit_error\",\"error_details\":\"\"}' | bash '$HOOK'
  "
  [ "$status" -eq 0 ]
  local log_dir="$TMPDIR_TEST/.claude/session-logs"
  # Directory should not exist or be empty
  [ ! -d "$log_dir" ] || [ -z "$(ls -A "$log_dir" 2>/dev/null)" ]
}

@test "billing error → logged with correct event type" {
  run bash -c "
    export HOME='$TMPDIR_TEST'
    export LOG=1
    echo '{\"error\":\"billing_error\",\"error_details\":\"Insufficient credits\"}' | bash '$HOOK'
  "
  [ "$status" -eq 0 ]
  local log_file="$TMPDIR_TEST/.claude/session-logs/$(date +%Y-%m-%d).log"
  [ -f "$log_file" ]
  grep -q "StopFailure" "$log_file"
  grep -q "billing_error" "$log_file"
}

@test "log rotation: file >500KB → gzip triggered" {
  # Pre-create an oversized log file
  local log_dir="$TMPDIR_TEST/.claude/session-logs"
  local today
  today="$(date +%Y-%m-%d)"
  local log_file="$log_dir/$today.log"
  mkdir -p "$log_dir"
  # Write >512000 bytes
  dd if=/dev/zero bs=1024 count=520 2>/dev/null | tr '\0' 'x' > "$log_file"

  run bash -c "
    export HOME='$TMPDIR_TEST'
    export LOG=1
    echo '{\"error\":\"overload_error\",\"error_details\":\"\"}' | bash '$HOOK'
  "
  [ "$status" -eq 0 ]
  # Original .log file should be gone (gzipped), or a .gz file should exist
  [ -f "${log_file}.gz" ] || [ ! -f "$log_file" ]
}
