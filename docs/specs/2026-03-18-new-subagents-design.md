# Design: New Subagents for DLC Skill Suite

**Date:** 2026-03-18
**Status:** Approved

## Problem Statement

The DLC skill suite (dlc-build, dlc-review, dlc-debug) has two workflow gaps:

1. **Review consolidation is duplicated** — dlc-build uses an inline unnamed subagent
   (`consolidation-prompt.md`) while dlc-review makes the main model do mechanical
   dedup/sort inline. Same logic, two implementations, main model doing Haiku-level work.

2. **dlc-debug has no bootstrap agent** — unlike dlc-build (dev-loop-bootstrap) and
   dlc-review (pr-review-bootstrap), dlc-debug makes the lead pre-gather context inline.
   Worse: when triggered after dlc-build, the Investigator starts with zero knowledge of
   what was just built — causing redundant file reads.

## Solution

Create 2 named Haiku agents that integrate into the existing DLC skill call sites.

---

## Agent 1: `review-consolidator`

### Purpose

Mechanical post-review dedup/sort/signal-check. Offloads ~100 tokens of inline steps
from main model per review session. Shared between dlc-build and dlc-review.

### Spec

```yaml
name: review-consolidator
model: haiku
tools: Read
memory: none
```

### Input

One of two forms (caller decides):

- **File paths:** `review-findings-1.md`, `review-findings-2.md`, `review-findings-3.md`
  at `{project_root}/.claude/dlc-build/`
- **Inline block:** findings text passed directly in prompt (for dlc-review which does
  not write per-reviewer files)

### Process (strictly ordered)

1. **Dedup** — same file:line across reviewers → keep highest confidence, merge evidence
2. **Pattern cap** — same violation in >3 files → consolidate to 1 row + "and N more"
3. **Sort** — Critical → Warning → Info
4. **Signal check** — if (Critical+Warning)/Total < 60% → prepend flag `⚠ Low signal`
5. **Output** — findings table in `review-output-format.md` format

### Output Format

```markdown
**Summary: Critical X / Warning Y / Info Z**

| # | Sev | Rule | File | Line | Consensus | Issue |
|---|-----|------|------|------|-----------|-------|
| 1 | Critical | #2 | `src/foo.ts` | 42 | 3/3 | ... |
```

### Error Handling

- Missing findings file → return empty contribution + note `[no findings from reviewer N]`
- Empty findings → return empty table (not an error)

### Integration Points

| Skill | Phase | Change |
| ------- | ------- | -------- |
| dlc-build | Phase 4 iter 1 | Replace `consolidation-prompt.md` inline call with `Agent(subagent_type: "review-consolidator")` |
| dlc-review | Phase 4 Convergence | Replace 4 inline steps with `Agent(subagent_type: "review-consolidator")` |

**File retired:** `skills/dlc-build/references/consolidation-prompt.md` — content moves to agent.

---

## Agent 2: `dlc-debug-bootstrap`

### Agent Purpose

Pre-gather shared context before dlc-debug Phase 1 spawns teammates. Key differentiator
from other bootstrap agents: reads dlc-build artifacts when present, giving the
Investigator full context of what was just built — eliminating redundant reads in the
common build→test→debug workflow.

### Agent Spec

```yaml
name: dlc-debug-bootstrap
model: haiku
tools: Read, Glob, Bash, Grep
memory: none
argument-hint: "[bug-description-or-jira-key]"
compatibility: fd, ast-grep
```

### Agent Input

Bug description or Jira key from caller (`$ARGUMENTS`), plus `{project_root}` path.

### Agent Process

```text
Step 1: Check for dlc-build artifacts
  Glob("{project_root}/.claude/dlc-build/dev-loop-context.md")
  ├─ Found → extract: plan items relevant to affected area, files modified
  └─ Not found → skip (standard bootstrap, no Recent Build Context section)

Step 2: Map affected files from bug description
  Parse stack trace / error message → identify file paths (max 5)
  fd -t f matching patterns in affected area

Step 3: Recent commits in affected area
  git log --oneline -10 -- {affected_files}

Step 4: Scan file structure (NOT full file content)
  ast-grep for relevant function signatures
  Collect key class/interface names only

Step 5: Write Shared Context to debug-context.md
  Append ## Shared Context section
```

### Output Written to `debug-context.md`

```markdown
## Shared Context
**Gathered:** {timestamp}

### Recent Build Context (from dlc-build)
(only present when dlc-build artifacts found)
{relevant plan items and modified files from recent build}

### Affected Files
- {file:line-range} — {brief description of relevant section}

### Recent Commits
{git log --oneline -10 output for affected files}

### Code Structure Notes
{function signatures, key patterns in affected area}
```

### Agent Error Handling

- `debug-context.md` not yet created → agent creates skeleton then appends
- `ast-grep` unavailable → fallback to grep for function signatures
- dlc-build artifacts present but unrelated to bug area → omit Recent Build Context section

### Integration Point

| Skill | Phase | Change |
| ------- | ------- | -------- |
| dlc-debug | Phase 0 Step 4 | Replace inline bootstrap Steps 1–4 with `Agent(subagent_type: "dlc-debug-bootstrap")` |

---

## Files Changed

| File | Action | Notes |
| ------ | -------- | ------- |
| `agents/review-consolidator.md` | Create | ~60 lines |
| `agents/dlc-debug-bootstrap.md` | Create | ~80 lines |
| `skills/dlc-build/references/phase-4-review.md` | Edit | Replace inline subagent call |
| `skills/dlc-build/SKILL.md` | Edit | Add reference table row |
| `skills/dlc-review/SKILL.md` | Edit | Replace Phase 4 consolidation steps |
| `skills/dlc-debug/SKILL.md` | Edit | Replace Phase 0 bootstrap steps 1–4 |
| `skills/dlc-build/references/consolidation-prompt.md` | Delete | Content moves to agent |

## Non-Goals

- Jira context agent — each skill uses Jira differently; shared agent would oversimplify
- dlc-respond bootstrap — thread-fetch pattern is simple enough to stay inline
- Agent Teams teammate extraction — teammates stay inline per DLC skill design intent

## Success Criteria

- `review-consolidator` produces identical output to current dlc-build consolidation
- `dlc-debug-bootstrap` writes valid `## Shared Context` section that Investigator can use
- All 3 DLC skills pass `npx markdownlint-cli2` after edits
- Symlinks created via `link-skill.sh`
