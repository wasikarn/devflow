#!/usr/bin/env bash
# fix-tables.sh — Normalize markdown table rows to '| cell |' aligned style.
#
# Handles:
#   - Escaped pipes (\|) — treated as literal content, not separators
#   - Pipes inside code spans (`a | b`) — not treated as separators
#   - Fenced code blocks (``` or ~~~) — skipped entirely
#
# Usage:
#   bash scripts/fix-tables.sh              # process . recursively
#   bash scripts/fix-tables.sh dir/         # process directory recursively
#   bash scripts/fix-tables.sh f1.md f2.md  # process specific files (pre-commit)
#
# Compatible with macOS awk (one true awk / BWK awk).

set -euo pipefail

TOTAL=0
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

# Awk program: normalizes one file, writes to stdout.
# shellcheck disable=SC2016  # single quotes intentional — awk program, no expansion wanted
AWK_PROG='
function is_fence(line,    s) {
    s = line
    if (substr(s,1,1)==" ") s=substr(s,2)
    if (substr(s,1,1)==" ") s=substr(s,2)
    if (substr(s,1,1)==" ") s=substr(s,2)
    f = substr(s, 1, 3)
    return (f == "```" || f == "~~~")
}

function split_cells(row, cells,    buf, in_code, n, i, ch) {
    delete cells
    n = 0; buf = ""; in_code = 0
    for (i = 1; i <= length(row); i++) {
        ch = substr(row, i, 1)
        if (ch == "`") {
            in_code = !in_code; buf = buf ch
        } else if (ch == "\\" && i < length(row) && substr(row, i+1, 1) == "|") {
            buf = buf "\\|"; i++
        } else if (ch == "|" && !in_code) {
            cells[++n] = buf; buf = ""
        } else {
            buf = buf ch
        }
    }
    cells[++n] = buf
    return n
}

function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

function norm_row(s,    cells, n, end_i, result, i, c) {
    if (substr(s, 1, 1) != "|") return s
    n = split_cells(s, cells)
    end_i = (substr(s, length(s), 1) == "|") ? n-1 : n
    result = "|"
    for (i = 2; i <= end_i; i++) {
        c = trim(cells[i])
        result = result (c != "" ? " " c " " : " ") "|"
    }
    return result
}

BEGIN { in_fence = 0 }
{
    if (is_fence($0)) in_fence = !in_fence
    if (!in_fence && substr($0, 1, 1) == "|") {
        s = $0; sub(/[\r\n]+$/, "", s)
        print norm_row(s)
    } else {
        print
    }
}
'

fix_file() {
    local file="$1"
    awk "$AWK_PROG" "$file" > "$TMPFILE"
    if ! cmp -s "$file" "$TMPFILE"; then
        local changed
        changed=$(diff "$file" "$TMPFILE" | grep -c '^< ' || true)
        cp "$TMPFILE" "$file"
        printf '  fixed %3d rows  %s\n' "$changed" "$file"
        TOTAL=$((TOTAL + changed))
    fi
}

# Determine files to process
if [ "$#" -eq 0 ] || { [ "$#" -eq 1 ] && [ -d "$1" ]; }; then
    root="${1:-.}"
    while IFS= read -r -d '' md; do
        fix_file "$md"
    done < <(find "$root" -name "*.md" -print0 | sort -z)
else
    # Individual file paths (e.g. from xargs in pre-commit hook)
    for f in "$@"; do
        [ -f "$f" ] && fix_file "$f"
    done
fi

printf '\nTotal rows normalized: %d\n' "$TOTAL"
