#!/usr/bin/env bash
# classify-env-gaps.sh — Cross-reference env vars across code, schema, and .env.example.
# Usage: bash classify-env-gaps.sh [project-root] [schema-file] [example-file]
# Output: {"schema_vars":[...],"example_vars":[...],"code_vars":[...],"gaps":{...},"gap_count":N}
#
# Extends scan-env-refs.sh by adding schema + example parsing and gap analysis.
# Compatible with bash 3.x (macOS default).

set -euo pipefail

PROJECT_ROOT="${1:-.}"
SCHEMA_FILE="${2:-env.ts}"
EXAMPLE_FILE="${3:-.env.example}"

# Resolve paths
SCHEMA_PATH="$PROJECT_ROOT/$SCHEMA_FILE"
EXAMPLE_PATH="$PROJECT_ROOT/$EXAMPLE_FILE"

# --- Phase 1: Scan code for env var references ---
EXCLUDE_DIRS="node_modules|dist|build|\.next"
CODE_TMPFILE=$(mktemp)
trap 'rm -f "$CODE_TMPFILE" "$SCHEMA_TMPFILE" "$EXAMPLE_TMPFILE"' EXIT

# Pattern 1: process.env.VAR_NAME
grep -rn 'process\.env\.\w\+' "$PROJECT_ROOT" \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' 2>/dev/null \
  | grep -vE "$EXCLUDE_DIRS" \
  | sed 's/.*process\.env\.\([A-Za-z_][A-Za-z0-9_]*\).*/\1/' \
  >> "$CODE_TMPFILE" || true

# Pattern 2: Env.get('VAR_NAME')
grep -rn "Env\.get(" "$PROJECT_ROOT" \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' 2>/dev/null \
  | grep -vE "$EXCLUDE_DIRS" \
  | sed "s/.*Env\.get(['\"][[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\).*/\1/" \
  >> "$CODE_TMPFILE" || true

# Pattern 3: env('VAR_NAME')
grep -rn "env(" "$PROJECT_ROOT" \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' 2>/dev/null \
  | grep -vE "$EXCLUDE_DIRS" \
  | grep -v "Env\.get" \
  | sed "s/.*env(['\"][[:space:]]*\([A-Za-z_][A-Za-z0-9_]*\).*/\1/" \
  >> "$CODE_TMPFILE" || true

CODE_VARS=$(sort -u "$CODE_TMPFILE" | grep -E '^[A-Z_][A-Z0-9_]*$' || true)

# --- Phase 2: Parse schema file ---
SCHEMA_TMPFILE=$(mktemp)
if [ -f "$SCHEMA_PATH" ]; then
  # Match patterns like: VAR_NAME: Env.schema.xxx or 'VAR_NAME': Env.schema.xxx
  grep -oE "['\"]?[A-Z_][A-Z0-9_]*['\"]?\s*:" "$SCHEMA_PATH" 2>/dev/null \
    | sed "s/['\": ]//g" \
    | grep -E '^[A-Z_][A-Z0-9_]*$' \
    | sort -u >> "$SCHEMA_TMPFILE" || true
fi
SCHEMA_VARS=$(cat "$SCHEMA_TMPFILE")

# --- Phase 3: Parse .env.example ---
EXAMPLE_TMPFILE=$(mktemp)
if [ -f "$EXAMPLE_PATH" ]; then
  # Match lines like: VAR_NAME=value or VAR_NAME= (skip comments and empty lines)
  grep -E '^[A-Z_][A-Z0-9_]*=' "$EXAMPLE_PATH" 2>/dev/null \
    | sed 's/=.*//' \
    | sort -u >> "$EXAMPLE_TMPFILE" || true
fi
EXAMPLE_VARS=$(cat "$EXAMPLE_TMPFILE")

# --- Phase 4: Compute gaps ---
# Helper: check if var is in a list (one var per line)
var_in_list() {
  echo "$2" | grep -qx "$1" 2>/dev/null
}

# Build gap arrays
IN_CODE_NOT_SCHEMA=""
IN_CODE_NOT_EXAMPLE=""
IN_SCHEMA_NOT_CODE=""
IN_EXAMPLE_NOT_CODE=""
GAP_COUNT=0

# Code vars not in schema/example
if [ -n "$CODE_VARS" ]; then
  while IFS= read -r var; do
    [ -z "$var" ] && continue
    if [ -n "$SCHEMA_VARS" ]; then
      if ! var_in_list "$var" "$SCHEMA_VARS"; then
        IN_CODE_NOT_SCHEMA="${IN_CODE_NOT_SCHEMA:+${IN_CODE_NOT_SCHEMA}, }\"${var}\""
        GAP_COUNT=$((GAP_COUNT + 1))
      fi
    fi
    if [ -n "$EXAMPLE_VARS" ]; then
      if ! var_in_list "$var" "$EXAMPLE_VARS"; then
        IN_CODE_NOT_EXAMPLE="${IN_CODE_NOT_EXAMPLE:+${IN_CODE_NOT_EXAMPLE}, }\"${var}\""
        GAP_COUNT=$((GAP_COUNT + 1))
      fi
    fi
  done <<EOF
$CODE_VARS
EOF
fi

# Schema vars not in code
if [ -n "$SCHEMA_VARS" ]; then
  while IFS= read -r var; do
    [ -z "$var" ] && continue
    if [ -n "$CODE_VARS" ]; then
      if ! var_in_list "$var" "$CODE_VARS"; then
        IN_SCHEMA_NOT_CODE="${IN_SCHEMA_NOT_CODE:+${IN_SCHEMA_NOT_CODE}, }\"${var}\""
        GAP_COUNT=$((GAP_COUNT + 1))
      fi
    fi
  done <<EOF
$SCHEMA_VARS
EOF
fi

# Example vars not in code
if [ -n "$EXAMPLE_VARS" ]; then
  while IFS= read -r var; do
    [ -z "$var" ] && continue
    if [ -n "$CODE_VARS" ]; then
      if ! var_in_list "$var" "$CODE_VARS"; then
        IN_EXAMPLE_NOT_CODE="${IN_EXAMPLE_NOT_CODE:+${IN_EXAMPLE_NOT_CODE}, }\"${var}\""
        GAP_COUNT=$((GAP_COUNT + 1))
      fi
    fi
  done <<EOF
$EXAMPLE_VARS
EOF
fi

# --- Build JSON arrays for var lists ---
build_json_array() {
  local vars="$1"
  local result=""
  if [ -z "$vars" ]; then
    echo "[]"
    return
  fi
  while IFS= read -r var; do
    [ -z "$var" ] && continue
    result="${result:+${result}, }\"${var}\""
  done <<EOF
$vars
EOF
  echo "[${result}]"
}

SCHEMA_JSON=$(build_json_array "$SCHEMA_VARS")
EXAMPLE_JSON=$(build_json_array "$EXAMPLE_VARS")
CODE_JSON=$(build_json_array "$CODE_VARS")

# --- Output ---
echo "{\"schema_vars\":${SCHEMA_JSON},\"example_vars\":${EXAMPLE_JSON},\"code_vars\":${CODE_JSON},\"gaps\":{\"in_code_not_schema\":[${IN_CODE_NOT_SCHEMA}],\"in_code_not_example\":[${IN_CODE_NOT_EXAMPLE}],\"in_schema_not_code\":[${IN_SCHEMA_NOT_CODE}],\"in_example_not_code\":[${IN_EXAMPLE_NOT_CODE}]},\"gap_count\":${GAP_COUNT}}"
