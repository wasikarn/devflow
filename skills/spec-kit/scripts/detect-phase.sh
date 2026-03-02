#!/usr/bin/env bash
# Detect current SDD workflow state for a spec-kit project.
#
# Usage:
#   ./detect-phase.sh                    # auto-detect feature from branch or SPECIFY_FEATURE
#   ./detect-phase.sh <feature-slug>     # e.g. 001-photo-albums
#
# Output: JSON with current_step, next_action, missing_files, feature_dir

set -euo pipefail

readonly SPECIFY_DIR=".specify"
readonly SPECS_DIR="${SPECIFY_DIR}/specs"
readonly CONSTITUTION_PATH="${SPECIFY_DIR}/memory/constitution.md"

# Workflow state — populated by detect_workflow_state
CURRENT_STEP=""
NEXT_ACTION=""
MISSING_FILE=""
STATUS="ok"

# ── Predicates ────────────────────────────────────────────────────────────────

file_exists() { [[ -f "$1" ]]; }
dir_exists()  { [[ -d "$1" ]]; }
is_git_repo() { git rev-parse --is-inside-work-tree &>/dev/null; }

project_is_initialized() { dir_exists  "${SPECIFY_DIR}"; }
constitution_exists()    { file_exists "${CONSTITUTION_PATH}"; }
spec_exists()            { file_exists "${1}/spec.md"; }
plan_exists()            { file_exists "${1}/plan.md"; }
tasks_exist()            { file_exists "${1}/tasks.md"; }

# ── Feature slug resolution ───────────────────────────────────────────────────

branch_matches_feature_pattern() { [[ "$1" =~ ^[0-9]{3}-.+ ]]; }

current_git_branch() { git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""; }

resolve_feature_slug() {
  local explicit_arg="${1:-}"
  [[ -n "$explicit_arg" ]]        && { echo "$explicit_arg"; return; }
  [[ -n "${SPECIFY_FEATURE:-}" ]] && { echo "${SPECIFY_FEATURE}"; return; }

  if is_git_repo; then
    local branch
    branch=$(current_git_branch)
    branch_matches_feature_pattern "$branch" && echo "$branch" && return
  fi

  echo ""
}

# ── Task counting ─────────────────────────────────────────────────────────────

count_incomplete_tasks() { grep -c '^\- \[ \]'            "$1" 2>/dev/null || echo 0; }
count_completed_tasks()  { grep -c '^\- \[x\]\|^\- \[X\]' "$1" 2>/dev/null || echo 0; }

# ── Workflow state detection ──────────────────────────────────────────────────

detect_implementation_progress() {
  local tasks_file="${1}/tasks.md"
  local incomplete completed
  incomplete=$(count_incomplete_tasks "$tasks_file")
  completed=$(count_completed_tasks  "$tasks_file")

  if [[ "$incomplete" -gt 0 ]]; then
    CURRENT_STEP="6_in_progress"
    NEXT_ACTION="Run: /speckit.implement  (${incomplete} tasks remaining, ${completed} done)"
  else
    CURRENT_STEP="6_complete"
    NEXT_ACTION="Feature complete! Consider: /speckit.taskstoissues or open a PR."
  fi
}

detect_workflow_state() {
  local feature_dir="$1"

  if ! project_is_initialized; then
    CURRENT_STEP="0"; NEXT_ACTION="Run: specify init --here --ai claude"
    MISSING_FILE="${SPECIFY_DIR}/"; return
  fi

  if ! constitution_exists; then
    CURRENT_STEP="1_pending"; NEXT_ACTION="Run: /speckit.constitution"
    MISSING_FILE="${CONSTITUTION_PATH}"; return
  fi

  if [[ -z "$feature_dir" ]]; then
    CURRENT_STEP="2_pending"; NEXT_ACTION="Run: /speckit.specify <description>"
    STATUS="no_feature_detected"; return
  fi

  if ! spec_exists "$feature_dir"; then
    CURRENT_STEP="2_pending"; NEXT_ACTION="Run: /speckit.specify <description>"
    MISSING_FILE="${feature_dir}/spec.md"; return
  fi

  if ! plan_exists "$feature_dir"; then
    CURRENT_STEP="3_or_4"; NEXT_ACTION="Optional: /speckit.clarify | Then: /speckit.plan <tech stack>"
    MISSING_FILE="${feature_dir}/plan.md"; return
  fi

  if ! tasks_exist "$feature_dir"; then
    CURRENT_STEP="5_pending"; NEXT_ACTION="Optional: /speckit.analyze | Then: /speckit.tasks"
    MISSING_FILE="${feature_dir}/tasks.md"; return
  fi

  detect_implementation_progress "$feature_dir"
}

# ── JSON serialization ────────────────────────────────────────────────────────

bool()           { "$@" && echo true || echo false; }
artifact_bool()  { [[ -n "$1" ]] && file_exists "$1" && echo true || echo false; }
missing_array()  { [[ -n "$MISSING_FILE" ]] && echo "[\"${MISSING_FILE}\"]" || echo "[]"; }

emit_json() {
  local feature_slug="$1" feature_dir="$2"

  cat <<EOF
{
  "status": "${STATUS}",
  "current_step": "${CURRENT_STEP}",
  "next_action": "${NEXT_ACTION}",
  "feature_slug": "${feature_slug}",
  "feature_dir": "${feature_dir}",
  "checks": {
    "specify_dir":  $(bool dir_exists  "${SPECIFY_DIR}"),
    "constitution": $(bool file_exists "${CONSTITUTION_PATH}"),
    "spec_md":      $(artifact_bool    "${feature_dir:+${feature_dir}/spec.md}"),
    "plan_md":      $(artifact_bool    "${feature_dir:+${feature_dir}/plan.md}"),
    "tasks_md":     $(artifact_bool    "${feature_dir:+${feature_dir}/tasks.md}")
  },
  "missing_files": $(missing_array)
}
EOF
}

# ── Entry point ───────────────────────────────────────────────────────────────

main() {
  local feature_slug feature_dir
  feature_slug=$(resolve_feature_slug "${1:-}")
  feature_dir="${feature_slug:+${SPECS_DIR}/${feature_slug}}"

  detect_workflow_state "$feature_dir"
  emit_json "$feature_slug" "$feature_dir"
}

main "$@"
