#!/bin/bash
# PostToolUse hook: auto-run tests when env.ts or config files are modified

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.command // empty')

[[ -z "$file_path" ]] && exit 0

# Match **/env.ts or **/config/**
case "$file_path" in
  */env.ts|*/config/*)
    ;;
  *)
    exit 0
    ;;
esac

# Find project root (look for .adonisrc.json upward)
dir=$(dirname "$file_path")
while [[ "$dir" != "/" ]]; do
  [[ -f "$dir/.adonisrc.json" ]] && break
  dir=$(dirname "$dir")
done
[[ ! -f "$dir/.adonisrc.json" ]] && exit 0

echo "env/config change detected: $file_path"
echo "Running tests..."

output=$(cd "$dir" && timeout 120 node ace test 2>&1)
exit_code=$?

echo "$output" | tail -20

exit $exit_code
