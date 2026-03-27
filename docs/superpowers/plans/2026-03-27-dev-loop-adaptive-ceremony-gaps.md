# dev-loop Adaptive Ceremony — Remaining Gaps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the 5 remaining gaps in the Adaptive Ceremony System spec that are not yet in the codebase.

**Architecture:** Most of the spec has already been implemented (blast-radius scoring, Micro mode, Phase 5 Verify, plan-challenger dual-lens, rationalization blockers, structured evidence, criticality scaling). This plan covers ONLY the confirmed gaps discovered via code review.

**Tech Stack:** Markdown files only — no code changes. Changes to `.md` files in `skills/dlc-build/references/`, `agents/`, and `skills/dlc-build/SKILL.md`.

---

## Gap Analysis Summary

These 5 items are confirmed missing after reading all affected files:

| Gap | File | Spec Section | Effort |
| ----- | ------ | ------------- | -------- |
| A | `skills/dlc-build/SKILL.md` | §1.2 Live Context Injection | Tiny |
| B | `skills/dlc-build/references/phase-3-plan.md` | §8.1 Artifact Folder | Medium |
| C | `skills/dlc-build/references/review-lenses/typescript.md` | §6.6 TypeScript 4-Dimension Scoring | Small |
| D | `agents/metrics-analyst.md` | §8.2 Skill Evolution Protocol | Medium |
| E | `skills/dlc-build/references/phase-9-ship.md` | §8.2 metrics-analyst trigger | Small |

All other spec items are already implemented — do NOT re-implement them.

---

## Files Modified

- Modify: `skills/dlc-build/SKILL.md:27-31` — add `!git diff --name-only HEAD` injection
- Modify: `skills/dlc-build/references/phase-3-plan.md:1-109` — remove EnterPlanMode/ExitPlanMode, write plan directly to artifacts_dir
- Modify: `skills/dlc-build/references/review-lenses/typescript.md` — append 4-dimension type scoring section
- Modify: `agents/metrics-analyst.md` — add session lens-update-suggestion logic; enable Write tool
- Modify: `skills/dlc-build/references/phase-9-ship.md:76-90` — add Step 8 metrics-analyst trigger after Step 7

---

## Task 1 (Gap A): Add `git diff --name-only HEAD` to SKILL.md

**Files:**
- Modify: `skills/dlc-build/SKILL.md`

- [ ] **Step 1: Read current SKILL.md header section**

Read `skills/dlc-build/SKILL.md` lines 27–33 to confirm the current `!command` injections.

- [ ] **Step 2: Add git diff injection after the Recent commits line**

Edit `skills/dlc-build/SKILL.md`. Find this block:

```
**Git branch:** !`git branch --show-current`
**Recent commits:** !`git log --oneline -5 2>/dev/null || true`
```

Replace with:

```
**Git branch:** !`git branch --show-current`
**Recent commits:** !`git log --oneline -5 2>/dev/null || true`
**Changed files:** !`git diff --name-only HEAD 2>/dev/null || echo "clean"`
```

**Why:** Spec §1.2 requires this injection to give the blast-radius scorer live context about what's already in-flight. The scorer uses both recent commits AND changed-but-uncommitted files to evaluate Novelty and Scope factors.

- [ ] **Step 3: Verify markdown lints**

```bash
npx markdownlint-cli2 "skills/dlc-build/SKILL.md"
```

Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add skills/dlc-build/SKILL.md
git commit -m "feat(dlc-build): add git diff --name-only HEAD injection to SKILL.md header"
```

---

## Task 2 (Gap B): Remove EnterPlanMode — write plan.md directly to artifacts_dir

**Files:**
- Modify: `skills/dlc-build/references/phase-3-plan.md`

**Context:** Currently phase-3-plan.md Step 1 calls `EnterPlanMode` (which writes to `~/.claude/plans/{random}.md`), then copies to `{artifacts_dir}/{date}-{task-slug}/plan.md`. Spec §8.1 explicitly states `~/.claude/plans/` is no longer used by dlc-build. The canonical path is already `{artifacts_dir}/{date}-{task-slug}/plan.md`. The copy step is the source of truth, but the EnterPlanMode → copy dance is vestigial.

- [ ] **Step 1: Read phase-3-plan.md Step 1 in full**

Read `skills/dlc-build/references/phase-3-plan.md` lines 1–80 to confirm the current EnterPlanMode/ExitPlanMode usage and copy logic.

- [ ] **Step 2: Rewrite Step 1 to write plan directly**

Edit `skills/dlc-build/references/phase-3-plan.md`. Replace Step 1 entirely.

**Current (lines 1–76 approximately):**
```markdown
## Step 1: Write Plan

Call `EnterPlanMode` — Claude switches to Opus, plan file created at `~/.claude/plans/{random}.md`.

**Source material by mode:**
...

## Plan Structure
...

After writing the plan: call `ExitPlanMode`. Plan file path returned.

**Copy plan to artifacts_dir:** Immediately copy the created file:

```bash
cp ~/.claude/plans/{returned-filename}.md {artifacts_dir}/{date}-{task-slug}/plan.md
```

Update `plan_file:` in `{artifacts_dir}/dev-loop-context.md` to the new artifacts_dir path.
The `{artifacts_dir}/{date}-{task-slug}/plan.md` path is the canonical path for all downstream consumers.
```

**Replace with:**
```markdown
## Step 1: Write Plan

Write `{artifacts_dir}/{date}-{task-slug}/plan.md` directly — do NOT use `EnterPlanMode` or `~/.claude/plans/`. The canonical path is `{artifacts_dir}/{date}-{task-slug}/plan.md` from the first write.

**Source material by mode:**

| Mode | Plan source |
| ------ | ------------ |
| Micro | Task description only |
| Quick | Task description + research.md WHAT/WHY |
| Full | Task description + research.md (ADDED/MODIFIED/REMOVED + clarifications) |
| Hotfix | Broken code path only — minimal scope |

## Plan Structure

All modes produce a plan.md with these sections:

(keep existing plan structure content unchanged)

After writing plan.md: Update `plan_file:` in `{artifacts_dir}/dev-loop-context.md` to `{artifacts_dir}/{date}-{task-slug}/plan.md`.
```

The key change: remove the `Call EnterPlanMode`, `call ExitPlanMode`, and `cp ~/.claude/plans/...` lines entirely. Keep all plan structure content (must_haves, truths, key_links, tasks, readiness verdict, truth quality rules, plan quality rules) unchanged.

- [ ] **Step 3: Verify the update was applied correctly**

Read `skills/dlc-build/references/phase-3-plan.md` and confirm:
- No mention of `EnterPlanMode`
- No mention of `ExitPlanMode`
- No mention of `~/.claude/plans/`
- Plan is written directly to `{artifacts_dir}/{date}-{task-slug}/plan.md`
- All plan structure sections (must_haves, truths, key_links, tasks) are intact

- [ ] **Step 4: Verify markdown lints**

```bash
npx markdownlint-cli2 "skills/dlc-build/references/phase-3-plan.md"
```

Expected: 0 errors.

- [ ] **Step 5: Commit**

```bash
git add skills/dlc-build/references/phase-3-plan.md
git commit -m "feat(dlc-build): write plan.md directly to artifacts_dir, remove EnterPlanMode"
```

---

## Task 3 (Gap C): Add 4-dimension type scoring to typescript.md lens

**Files:**
- Modify: `skills/dlc-build/references/review-lenses/typescript.md`

**Context:** Spec §6.6 requires TypeScript reviewer to score each new/modified type definition on 4 dimensions. The current typescript.md lens has detailed hard rules but no 4-dimension scoring output requirement.

- [ ] **Step 1: Read the current end of typescript.md**

Read `skills/dlc-build/references/review-lenses/typescript.md` to find the last line of content (after the closing code block backticks).

- [ ] **Step 2: Append 4-dimension scoring section**

The file ends with a closing ```` ``` ```` for the lens code block. Append the 4-dimension scoring INSIDE the code block, before the closing backticks.

Find the last content line before the closing ` ``` ` and add after it:

```
4-DIMENSION TYPE SCORING (when diff adds or modifies type definitions):

Score each new/modified interface, type alias, or enum on these dimensions (1–10):

| Dimension         | Score | Threshold | Question                                           |
|-------------------|-------|-----------|----------------------------------------------------|
| Encapsulation     |       | <5 = flag | Can internals change without breaking consumers?   |
| Invariant Express |       | <5 = flag | Does the type make invalid states unrepresentable? |
| Usefulness        |       | <5 = flag | Does it add value over using primitive types?      |
| Enforcement       |       | <5 = flag | Does TypeScript actually enforce the constraints?  |

Overall type health = average of 4 dimensions.
Score <5 in ANY dimension = Warning finding citing the specific gap.
Score ≥8 average = note as strength, no action required.

Examples of low scores:
- Encapsulation=2: `type Config = { dbHost: string; dbPort: number }` — caller knows internals
  Fix: opaque type or branded type to hide structure
- Invariant=1: `type Status = 'active' | 'inactive' | string` — `string` widens away the invariant
  Fix: `type Status = 'active' | 'inactive'`
- Usefulness=2: `type Id = number` without branding — adds no safety over `number` directly
  Fix: `type UserId = number & { __brand: 'UserId' }`
- Enforcement=1: `interface Response { data: unknown }` — TS cannot enforce shape
  Fix: Zod schema + `z.infer<typeof ResponseSchema>`
```

- [ ] **Step 3: Verify the file structure is valid**

Read the full typescript.md to confirm the 4-dimension scoring was added inside the code block fence and the file is well-formed.

- [ ] **Step 4: Verify markdown lints**

```bash
npx markdownlint-cli2 "skills/dlc-build/references/review-lenses/typescript.md"
```

Expected: 0 errors.

- [ ] **Step 5: Commit**

```bash
git add skills/dlc-build/references/review-lenses/typescript.md
git commit -m "feat(dlc-build): add 4-dimension type scoring to typescript review lens"
```

---

## Task 4 (Gap D): Add lens-update-suggestion logic to metrics-analyst agent

**Files:**
- Modify: `agents/metrics-analyst.md`

**Context:** Spec §8.2 says after dlc-build completes in Full mode, metrics-analyst should:
1. Read `review-findings-*.md` from current session
2. Check dlc-metrics.jsonl for the same finding categories in the last 5 sessions
3. If a category recurs ≥3 times: create `lens-update-suggestion.md` in `{artifacts_dir}`, notify user

The current metrics-analyst only reads `~/.claude/dlc-metrics.jsonl` for retrospective reporting. It does NOT read per-session review findings or create suggestion files. Also, `Write` is currently in `disallowedTools`, which prevents creating the suggestion file.

- [ ] **Step 1: Read the current metrics-analyst.md frontmatter and all steps**

Read `agents/metrics-analyst.md` in full to see the current `disallowedTools` and all 4 steps.

- [ ] **Step 2: Enable Write tool in frontmatter**

Edit `agents/metrics-analyst.md` frontmatter. Change:

```yaml
disallowedTools: Edit, Write
```

To:

```yaml
disallowedTools: Edit
```

**Why:** The agent needs Write to create `lens-update-suggestion.md`. Edit is still blocked (agent should not modify existing files — only create new ones).

- [ ] **Step 3: Add $ARGUMENTS handling at top of Steps section**

After the `## Steps` heading, add:

```markdown
### 0. Parse Arguments

`$ARGUMENTS` may contain an artifacts dir path (passed by dlc-build Phase 9):
`{artifacts_dir}` — directory where this session's review findings live.

If `$ARGUMENTS` is empty or not a valid path: set `session_dir = null`. The agent will skip
Step 5 (session lens check) and run only the general retrospective report (Steps 1–4).
```

- [ ] **Step 4: Add Step 5 — Session Lens Update Check**

Append to `agents/metrics-analyst.md`, after the existing `### 4. Output Retrospective Report` section and its code block:

```markdown
### 5. Session Lens Update Check (only when session_dir is set)

Skip this step if `session_dir` is null (no artifacts_dir passed in $ARGUMENTS).

**5a. Extract finding categories from this session:**

Read all `{session_dir}/review-findings-*.md` files. For each finding in the consolidated
output, extract the category label if present (e.g., `[SECURITY]`, `[TYPE_SAFETY]`,
`[ERROR_HANDLING]`, `[PERFORMANCE]`, `[NULL_CHECK]`). Fall back to the reviewer role if
no category label is present (`Correctness`, `Architecture`, `DX`).

Collect a deduplicated list of finding categories for this session.

**5b. Check for recurrence in last 5 sessions:**

From the dlc-metrics.jsonl entries (already read in Step 1), filter to the last 5 entries
that are Full mode runs (field `"mode": "full"`). For each category found in 5a:

- Search for that category keyword in the last 5 sessions' date range in dlc-metrics.jsonl.
  Note: dlc-metrics.jsonl does not store finding categories — use the dates from Step 3
  to find the last 5 Full-mode run dates, then look for `review-findings-*.md` files
  under `{session_dir}/../` for those dates if accessible. If those files are not accessible
  (archived or absent), note the limitation and skip the cross-session check for that category.
- Count sessions where the category appeared.

**5c. Create suggestion file if pattern found:**

If ANY category appears in ≥3 of the last 5 Full-mode sessions:

Write `{session_dir}/lens-update-suggestion.md`:

```markdown
## Lens Update Suggestion

Generated: {ISO date}
Pattern: {category} appeared in {count}/5 recent Full-mode sessions

### Recurring Finding: {category}

Sessions affected: {list of dates}

Sample findings:
- {quote one representative finding with file:line from this session}

### Suggested lens update

Review lens: {lens file that covers this category}
Suggested addition: Add a Hard Rule or Warning pattern for "{category}" findings that
recur across sessions. Consider whether this represents a project-wide anti-pattern
that should be added to `.claude/skills/review-rules/hard-rules.md`.

**IMPORTANT:** This is a suggestion only — never auto-applies. User reviews and approves.
```

Then output to conversation:

```
⚠️ Recurring pattern detected: [{category}] appeared in {count}/5 recent Full-mode sessions.
Lens update suggestion saved to: {session_dir}/lens-update-suggestion.md
Review and approve before adding to hard-rules.md or a lens file.
```

If no recurring pattern: output nothing for this step (silent pass).

**5d. Skip conditions:**

- `session_dir` is null → skip entirely
- `dlc-metrics.jsonl` has fewer than 5 Full-mode entries → skip cross-session check
  (output: `Lens update check skipped — fewer than 5 Full-mode sessions in history`)
- No review-findings files in session_dir → skip (output: `No review findings found in {session_dir}`)
```

- [ ] **Step 5: Verify the file is well-formed**

Read the full `agents/metrics-analyst.md` to confirm:
- Frontmatter has `disallowedTools: Edit` (Write is no longer blocked)
- Step 0 (arguments parsing) is added before Step 1
- Step 5 (session lens check) is added after Step 4
- All existing steps 1–4 are unchanged

- [ ] **Step 6: Verify markdown lints**

```bash
npx markdownlint-cli2 "agents/metrics-analyst.md"
```

Expected: 0 errors.

- [ ] **Step 7: Commit**

```bash
git add agents/metrics-analyst.md
git commit -m "feat(metrics-analyst): add lens-update-suggestion logic for recurring finding patterns"
```

---

## Task 5 (Gap E): Add metrics-analyst trigger to phase-9-ship.md

**Files:**
- Modify: `skills/dlc-build/references/phase-9-ship.md`

**Context:** Spec §8.2 says metrics-analyst runs after dlc-build completes in Full mode, only if dlc-metrics.jsonl has ≥5 entries. Currently Phase 9 writes a metrics entry (Step 7) but never triggers metrics-analyst. The Mode Capability Matrix in workflow-modes.md already shows `8: metrics-analyst | Skip | Skip | Run if ≥5 entries | Skip` — this matrix entry has no corresponding implementation in Phase 9.

- [ ] **Step 1: Read phase-9-ship.md Step 7 in full**

Read `skills/dlc-build/references/phase-9-ship.md` lines 76–90 to confirm Step 7 is the last step.

- [ ] **Step 2: Add Step 8 after the existing Step 7**

Edit `skills/dlc-build/references/phase-9-ship.md`. After the closing `}` of the JSON metrics entry example, append:

```markdown
## Step 8: Lens Update Check (Full mode only)

Per [workflow-modes.md](../../../skills/build/references/workflow-modes.md): Micro, Quick, and Hotfix → skip this step entirely.

**Full mode:** Check entry count in `{artifacts_dir}/dlc-metrics.jsonl`:

```bash
wc -l < {artifacts_dir}/dlc-metrics.jsonl
```

- Fewer than 5 entries → skip (not enough history for pattern detection)
- 5 or more entries → spawn `metrics-analyst` with `{artifacts_dir}/{date}-{task-slug}/` as `$ARGUMENTS`

Wait for agent completion. The agent will:
1. Run the standard retrospective report from dlc-metrics.jsonl
2. Check current session's `review-findings-*.md` for recurring patterns
3. If a pattern recurs ≥3/5 sessions: create `lens-update-suggestion.md` and notify

If agent finds no recurring patterns: nothing is output (silent pass).
If agent finds patterns: message is surfaced to user with path to suggestion file.

**Never block shipping:** This step is informational. Even if metrics-analyst errors or times out, proceed to Done. Log "metrics-analyst skipped — error" in dev-loop-context.md.
```

- [ ] **Step 3: Verify the update was applied correctly**

Read `skills/dlc-build/references/phase-9-ship.md` in full and confirm:
- Step 7 (Metrics) is unchanged
- Step 8 (Lens Update Check) is added after it
- Step 8 references workflow-modes.md
- Step 8 has the Full-mode-only gate
- Step 8 has the ≥5 entries gate
- Step 8 has the "never block shipping" safety clause

- [ ] **Step 4: Also update SKILL.md Reference Loading table**

The Reference Loading table in SKILL.md lists when each file is loaded. After the metrics changes, there are no new files — metrics-analyst is already an agent. However, the SKILL.md `argument-hint` should still document the metrics-analyst trigger for contributors.

Check if the SKILL.md Reference Loading table needs any update by re-reading `skills/dlc-build/SKILL.md` lines 49–79.

If the table has no entry for phase-9-ship.md, that's expected (ship phase is always entered). If the table is missing any reference added in Tasks 1–5, add it. Otherwise skip this sub-step.

- [ ] **Step 5: Verify markdown lints**

```bash
npx markdownlint-cli2 "skills/dlc-build/references/phase-9-ship.md"
```

Expected: 0 errors.

- [ ] **Step 6: Commit**

```bash
git add skills/dlc-build/references/phase-9-ship.md
git commit -m "feat(dlc-build): trigger metrics-analyst after Phase 9 ship in Full mode"
```

---

## Self-Review Checklist

### 1. Spec coverage

| Spec item | Covered by task |
| ----------- | ---------------- |
| §1.2 `!git diff --name-only HEAD` injection | Task 1 |
| §8.1 plan.md written directly to artifacts_dir | Task 2 |
| §6.6 TypeScript 4-dimension type scoring | Task 3 |
| §8.2 lens-update-suggestion.md creation | Task 4 |
| §8.2 metrics-analyst trigger after ship (Full, ≥5 entries) | Task 5 |
| §9.1 Hook upgrades (deferred — verify API first) | NOT IMPLEMENTED — explicitly deferred by spec |
| All other spec items | Already implemented — confirmed by reading existing files |

### 2. No-placeholders check

- Task 1: exact line to add shown
- Task 2: old content and new content both shown for Edit; specific lines removed identified
- Task 3: exact text to append shown, including code examples
- Task 4: full Step 5 content written, exact frontmatter change specified
- Task 5: exact text to append shown with bash command

### 3. Type consistency

No types, method signatures, or function names involved — all markdown edits.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-03-27-dev-loop-adaptive-ceremony-gaps.md`.

**Two execution options:**

**1. Subagent-Driven (recommended)** — dispatch fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
