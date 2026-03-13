---
name: optimize-context
description: "Audit, score, and optimize CLAUDE.md files. Use when CLAUDE.md is outdated, too large (>15KB), or needs initial setup. Triggers: 'optimize context', 'audit context', 'improve CLAUDE.md', 'init claude.md', 'bootstrap claude.md', 'setup context'."
argument-hint: "[--dry-run?] [--coverage?]"
disable-model-invocation: true
---

# /optimize-context

Audit, score, and optimize CLAUDE.md files for maximum agent effectiveness. Invoke as `/optimize-context [--dry-run]` — add `--dry-run` to run phases 1-3 only (report without edits).

## References

| File | Content |
| --- | --- |
| [quality-criteria.md](references/quality-criteria.md) | CLAUDE.md Quality rubric (8 criteria, 100 pts) + Project Coverage rubric (12 categories) — load in Phase 2 |
| [compression-guide.md](references/compression-guide.md) | Compression techniques: tables, one-liners, pointer-to-docs patterns — load in Phase 4 |
| [templates.md](references/templates.md) | CLAUDE.md templates by project type (horizontal/vertical/hybrid) — load in Phase 4 when creating from scratch |
| `scripts/pre-scan.sh` | Detects framework, npm scripts, dir structure in ~30ms — run first in Phase 1 |
| [key-rules.md](references/key-rules.md) | 12 operational rules — read before making changes in Phase 4 |

**Why passive context wins:** Compressed 8KB context = 100% task success vs 53% baseline. AGENTS.md outperforms skills by 2×. Full data and grade thresholds: [references/quality-criteria.md](references/quality-criteria.md#vercel-research).

Critical minimum thresholds (score below these → must fix before passing):

| Criterion | Min |
| ------------------- | ----- |
| Commands | 10/15 |
| Architecture | 10/15 |
| Retrieval readiness | 10/15 |
| Conciseness | 10/15 |

### Project Coverage (optional — `--coverage` flag)

When `$ARGUMENTS` includes `--coverage`: also assess how well the project adopts Claude Code features (12 categories, scored 0-3 per applicable category, normalized to 100). See [references/quality-criteria.md](references/quality-criteria.md) for the full rubric and relevance table. When args include "expect" + "score 100/100": list every gap and concrete steps to close each one.

## Workflow

Copy this checklist and check off items as you complete each phase:

```text
Progress:
- [ ] Phase 1: Discovery & Classification
- [ ] Phase 2: Quality Assessment
- [ ] Phase 3: Audit
- [ ] Phase 4: Generate Update
- [ ] Phase 5: Apply & Verify
```

> `--dry-run` → run phases 1-3 only, output report, skip phases 4-5.

### 1. Discovery & Classification

**Run pre-scan first** (saves ~2-4k tokens vs reading files individually):

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/pre-scan.sh [project-root]
```

Output is compact JSON: `claude_files` (path + bytes), `framework` (name + version), `npm_scripts`, `dir_structure`, `has_agent_docs`, `has_claude_rules`. Use this to skip manual framework detection and file discovery. If script unavailable, use Glob patterns `**/CLAUDE.md`, `**/.claude.local.md`, `**/.claude.md`.

Identify each file's type:

| Type | Location |
| ---------------- | ------------------------ |
| Project root | `./CLAUDE.md` |
| Local overrides | `./.claude.local.md` |
| Global defaults | `~/.claude/CLAUDE.md` |
| Package-specific | `./packages/*/CLAUDE.md` |

Also list `agent_docs/` and `.claude/rules/` (if any) for deduplication checks.

**Classify context type:**

| Type | Signal |
| ---------- | -------------------------------------------- |
| Horizontal | Uses major framework (Next.js, NestJS, etc.) |
| Vertical | Custom/internal project |
| Hybrid | Framework + complex domain logic |

Detect framework: check `package.json`, `requirements.txt`, `go.mod`, etc. If official docs index tool exists (e.g. `npx @next/codemod@canary agents-md`), recommend it.

**Novel content detection:**

1. Identify framework + version from lockfiles/configs
2. Compare against model training cutoff (Claude: August 2025)
3. List APIs/features that are post-cutoff → these need detailed documentation
4. List well-known patterns within training data → candidates for compression/removal

**Output:** State classification explicitly — e.g. "Classification: Hybrid (Next.js 14 + custom domain). Next.js 14 within training cutoff — no post-cutoff docs needed."

**No CLAUDE.md found?** → Create one using the appropriate template from [references/templates.md](references/templates.md), then continue to phase 2.

### 2. Quality Assessment

Score each file using the CLAUDE.md Quality rubric (100 points). See [references/quality-criteria.md](references/quality-criteria.md) for detailed scoring.

Quick checklist:

| Criterion | Weight |
| ---------------------- | ------ |
| Commands/workflows | 15 |
| Architecture clarity | 15 |
| Retrieval readiness | 15 |
| Conciseness | 15 |
| Non-obvious patterns | 10 |
| Novel content coverage | 10 |
| Currency | 10 |
| Actionability | 10 |

Grades: A (90-100), B (70-89), C (50-69), D (30-49), F (0-29).

**Output format per file** (must follow exactly):

```markdown
./CLAUDE.md — Score: XX/100 (Grade X) | Size: XX KB

| Criterion | Score | Status | Notes |
| --- | --- | --- | --- |
| Commands | XX/15 | ✅ or ⚠️ CRITICAL (if <10) | ... |
| Architecture | XX/15 | ✅ or ⚠️ CRITICAL (if <10) | ... |
| Retrieval readiness | XX/15 | ✅ or ⚠️ CRITICAL (if <10, framework only) | ... |
| Conciseness | XX/15 | ✅ or ⚠️ CRITICAL (if <10) | ... |
| Non-obvious | XX/10 | ✅ | ... |
| Novel content | XX/10 | ✅ | ... |
| Currency | XX/10 | ✅ | ... |
| Actionability | XX/10 | ✅ | ... |

Critical check: PASS ✅ — all criteria above minimums
— or —
Critical check: FAIL ⚠️ — [Criterion] at X/15 (min 10), [Criterion] at X/15 (min 10)
```

The Status column is **mandatory** — compare each score against the minimum thresholds table and mark `⚠️ CRITICAL` if below. Any `FAIL` criteria must be addressed in phase 4 before the file can pass.

If `--coverage` flag: also assess Project Coverage using the rubric in [references/quality-criteria.md](references/quality-criteria.md). Scan for `.claude/rules/`, `skills/`, `agents/`, `output-styles/`, `.claude/settings.json`, `.mcp.json`, `.claude-plugin/`. Score each applicable category 0-3, normalize to 100.

### 3. Audit

Audit each section deeply — trace references to actual codebase files, verify commands by running them, cross-reference architecture claims against real directory structure. Surface-level checks are insufficient.

| Check |
| ----------------- |
| Stale |
| Gaps |
| Redundant |
| Outdated |
| Oversized |
| Noise |
| Missing retrieval |

Categorize as `Stale (must fix)`, `Gaps (must add)`, `Redundant (can reduce)`, `Noise (should remove)`, `OK`.

Proceed directly to phase 4 after outputting the report.

### 4. Generate Update

Apply changes following these priorities:

1. **Fix stale** → update to match actual codebase
2. **Fill gaps** → add missing patterns (compressed format)
3. **Deduplicate** → replace with pointers to agent_docs/rules
4. **Compress** → tables + one-liners over prose

For compression techniques: [references/compression-guide.md](references/compression-guide.md).
For templates by project type: [references/templates.md](references/templates.md).

**Size targets:** <8KB optimal, 8-15KB acceptable, >15KB needs compression.
**Size measurement:** Exclude auto-generated sections (`<claude-mem-context>`, plugin-injected blocks) from byte count — score only human-authored content.

**Output format** (must show before editing):

```markdown
### Proposed Changes

| # | Finding | Action | Size Impact |
| --- | --- | --- | --- |
| 1 | Finding #1: <summary> | <what will change> | +/- XX bytes |
| 2 | Finding #2: <summary> | <what will change> | +/- XX bytes |
| 3 | Finding #5: OK | No action needed | — |

Projected: Score XX → XX | Size: XX KB → XX KB
```

Every finding from phase 3 must appear in this table — if no action needed, state why.

Proceed directly to phase 5 after outputting the proposed changes table.

### 5. Apply & Verify

1. Edit CLAUDE.md files using Edit tool
2. **Verify completeness:** List each proposed change with ✅/❌ status. Run `wc -c` for size. Read final file to confirm all sections intact.
3. **Validate:** Run 2-3 commands from CLAUDE.md, verify referenced paths exist, check retrieval directive present (framework projects), confirm explore-first wording (no absolute "MUST" directives)
4. **Re-score:** Show before/after for each criterion, confirm critical thresholds pass. If `--coverage`: re-assess Project Coverage too.

**If verification fails:** revert (`git checkout`), return to Phase 4, re-apply cleanly.

Report: `CLAUDE.md Quality: XX → XX | Fixed N stale | Added N gaps | Removed N redundant | Size: XX KB → XX KB`

## Key Rules

See [references/key-rules.md](references/key-rules.md) for 12 operational rules (evidence-based, preserve intent, compress not delete, idempotent, passive over active, and more).
