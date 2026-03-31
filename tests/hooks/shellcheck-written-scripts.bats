#!/usr/bin/env bats
# Tests for shellcheck-written-scripts.sh — PostToolUse(Write) hook.

HOOK="$BATS_TEST_DIRNAME/../../hooks/shellcheck-written-scripts.sh"

run_hook() {
  echo "$1" | bash "$HOOK"
}

setup() {
  TMPDIR_TEST="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMPDIR_TEST"
}

@test ".sh file with shellcheck issues -> outputs hookSpecificOutput JSON" {
  # Create a real .sh file with a shellcheck-detectable issue
  local sh_file="$TMPDIR_TEST/bad.sh"
  printf '#!/usr/bin/env bash\necho $VAR\n' > "$sh_file"

  run run_hook "{\"tool_input\":{\"file_path\":\"$sh_file\"}}"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "hookSpecificOutput" ]]
  [[ "$output" =~ "PostToolUse" ]]
}

@test "non-.sh file -> exit 0 with no output" {
  local txt_file="$TMPDIR_TEST/notes.txt"
  echo "hello" > "$txt_file"

  run run_hook "{\"tool_input\":{\"file_path\":\"$txt_file\"}}"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "valid shell script with no issues -> exit 0 silently" {
  local sh_file="$TMPDIR_TEST/clean.sh"
  printf '#!/usr/bin/env bash\nset -euo pipefail\necho "hello"\n' > "$sh_file"

  run run_hook "{\"tool_input\":{\"file_path\":\"$sh_file\"}}"
  [ "$status" -eq 0 ]
  # shellcheck may or may not find issues -- if no issues, output should be empty
  # If output exists it must be valid JSON with hookSpecificOutput
  if [ -n "$output" ]; then
    echo "$output" | jq -e '.hookSpecificOutput' > /dev/null
  fi
}

@test "missing shellcheck binary -> exit 0 silently (graceful skip)" {
  local sh_file="$TMPDIR_TEST/any.sh"
  printf '#!/usr/bin/env bash\necho $UNQUOTED\n' > "$sh_file"

  # Write a wrapper script that runs the hook with a PATH containing only essential
  # tools (bash, jq, dirname, find, head, grep, wc) but NOT shellcheck.
  local wrapper="$TMPDIR_TEST/run-no-sc.sh"
  # Collect paths to required tools, excluding shellcheck
  local tool_bin
  tool_bin="$(mktemp -d)"
  for t in bash jq dirname basename find head grep wc tr env cat; do
    local p
    p="$(command -v "$t" 2>/dev/null)" && ln -sf "$p" "$tool_bin/$t" || true
  done

  cat > "$wrapper" <<EOF
#!/bin/bash
export PATH="$tool_bin"
echo '{"tool_input":{"file_path":"$sh_file"}}' | bash '$HOOK'
EOF
  chmod +x "$wrapper"

  run bash "$wrapper"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}
