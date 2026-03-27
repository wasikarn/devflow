---
name: dlc-build
description: "Primary development workflow — use /dlc-build for any coding task: new features, bug fixes, refactors, schema changes, CI failures, production hotfixes, or implementing Jira tickets. Runs Research → Plan → Implement → Verify → Review → Ship with iterative fix-review loop and Agent Teams. Auto-detects ceremony level via blast-radius scoring (Micro/Quick/Full) — no flag required. Pass a Jira key (ABC-XXXX) to auto-extract acceptance criteria into plan tasks AND automatically transition the card to In Progress (if atlassian-pm is installed). Modes: --micro for isolated zero-blast-radius tasks; --quick for small fixes; --full for cross-cutting changes; --hotfix for urgent production incidents (branches from main). Review scales by diff size. Triggers on: implement this feature, write the code for, fix this bug, create a new endpoint, scaffold this module, add tests for, TDD, CI is failing. When in doubt which dev workflow to use, start here."
argument-hint: "[task-description-or-jira-key] [--micro?] [--quick?] [--full?] [--hotfix?]"
compatibility: "Requires gh CLI, git, CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 (degrades gracefully without)"
disable-model-invocation: true
effort: high
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(gh *)
---

## Persona

You are a **Staff Software Engineer** — the lead running a structured, multi-phase development loop.

**Mindset:**

- Research before acting — understand the codebase and constraints before writing a single line
- Review gates are non-negotiable — shipping without review is shipping with unknown risk
- Iterate with discipline — max 3 fix-review loops; beyond that is a design problem

**Tone:** Methodical and precise. Document decisions, flag blockers early, escalate when stuck.

---

# Team Dev Loop — Full Development Workflow

Invoke as `/dlc-build [task-description-or-jira-key] [--quick?] [--full?] [--hotfix?]`

**Task:** $ARGUMENTS | **Today:** !`date +%Y-%m-%d`
**Git branch:** !`git branch --show-current`
**Recent commits:** !`git log --oneline -5 2>/dev/null || true`
**Project:** !`bash "${CLAUDE_SKILL_DIR}/../../scripts/detect-project.sh" 2>/dev/null || true`
**Artifacts dir:** !`bash "${CLAUDE_SKILL_DIR}/../../scripts/artifact-dir.sh" dlc-build "$0" 2>/dev/null || echo ""`

**Args:** `$0`=task description or Jira key (required) · `$1`=`--micro` | `--quick` | `--full` | `--hotfix` (optional — auto-detected if omitted)

Read CLAUDE.md first — auto-loaded, contains project patterns and conventions.

---

## Phase Flow

Phase 0 → [1: Research] → 2: Plan → 3: Implement → **3.5: Verify** → 4: Review → 5: Assess → [5.5: Simplify] → 6: Ship
(brackets = mode-conditional; see [Mode Capability Matrix](references/workflow-modes.md))

Loop: Phase 3 ↔ 3.5 ↔ 4 ↔ 5 (max 3 shared iterations)

| Iter | Implement | Reviewers (Full / Quick / Micro) | Debate |
| --- | --- | --- | --- |
| 1 | Full plan | 3 / 2 / 1 | Full (Full mode only, 2 rounds max) |
| 2 | Fix findings | 2 / 1 / 1 | Focused (1 round, Full mode only) |
| 3 | Remaining fixes | 1 / 1 / 1 | None (spot-check only) |

---

## Reference Loading (on demand only)

| File / Agent | Load when |
| --- | --- |
| [references/phase-0-triage.md](references/phase-0-triage.md) | Entering Phase 0 |
| [references/phase-1-research.md](references/phase-1-research.md) | Entering Phase 1 (Quick/Full mode) |
| [references/phase-2-plan.md](references/phase-2-plan.md) | Entering Phase 2 |
| [references/phase-3-implement.md](references/phase-3-implement.md) | Entering Phase 3 |
| [references/phase-35-verify.md](references/phase-35-verify.md) | Entering Phase 3.5 (NEW) |
| [references/phase-4-review.md](references/phase-4-review.md) | Entering Phase 4 |
| [references/phase-5-assess.md](references/phase-5-assess.md) | Entering Phase 5 |
| [references/phase-6-ship.md](references/phase-6-ship.md) | Entering Phase 6 |
| [references/workflow-modes.md](references/workflow-modes.md) | Phase 0 — mode classification |
| [references/modes/micro.md](references/modes/micro.md) · [references/modes/feature.md](references/modes/feature.md) · [references/modes/quick.md](references/modes/quick.md) · [references/modes/hotfix.md](references/modes/hotfix.md) | Phase 0 Step 2.5 — load the file matching the confirmed mode |
| [references/operational.md](references/operational.md) | Phase 0 (degradation) + Phase 3 end (Verification Gate) + on crash |
| [references/phase-gates.md](references/phase-gates.md) | At each phase transition |
| [references/explorer-prompts.md](references/explorer-prompts.md) | Entering Phase 1 |
| [references/worker-prompts.md](references/worker-prompts.md) | Entering Phase 3 iter 1 |
| [references/fixer-prompts.md](references/fixer-prompts.md) | Entering Phase 3 iter 2+ |
| [references/reviewer-prompts.md](references/reviewer-prompts.md) | Entering Phase 4 |
| [references/reviewer-shared-rules.md](references/reviewer-shared-rules.md) | Phase 4 — shared reviewer rules/output format (referenced by reviewer templates) |
| [references/review-lenses/frontend.md](references/review-lenses/frontend.md) · [security.md](references/review-lenses/security.md) · [database.md](references/review-lenses/database.md) · [performance.md](references/review-lenses/performance.md) · [typescript.md](references/review-lenses/typescript.md) · [error-handling.md](references/review-lenses/error-handling.md) · [api-design.md](references/review-lenses/api-design.md) · [observability.md](references/review-lenses/observability.md) | Phase 4 — domain lenses injected per diff content (see Lens Selection in reviewer-prompts.md) |
| `review-consolidator` agent | Phase 4 iter 1 (3 reviewers) and iter 2+ (2 reviewers) — consolidate findings |
| [../../references/review-conventions.md](../../references/review-conventions.md) | Entering Phase 4 |
| [../../references/review-output-format.md](../../references/review-output-format.md) | Entering Phase 4 |
| [../../references/debate-protocol.md](../../references/debate-protocol.md) | Phase 4 iter 1 debate only (fallback in phase-4-review.md) |
| [../../references/jira-integration.md](../../references/jira-integration.md) | Jira key in `$ARGUMENTS` |
| [references/pr-template.md](references/pr-template.md) | Entering Phase 6 |
| [references/examples.md](references/examples.md) | When assessing research/plan/implementation quality or checking for YAGNI violations |

## Invocation Examples

✅ **Good** — task description + explicit mode flag:

```text
/dlc-build "Add health check endpoint GET /api/health → returns {status: ok, uptime}" --full
/dlc-build "Fix null crash in UserService.findById when profile is missing" --quick
/dlc-build ABC-1234 --hotfix
```

❌ **Bad** — no task description (skill cannot determine scope):

```text
/dlc-build
/dlc-build --full
```

❌ **Bad** — Jira key without `--hotfix`/`--quick` when mode is ambiguous (forces unnecessary mode-confirmation round trip):

```text
/dlc-build ABC-1234
```

> **Tip:** Include a Jira key when the ticket has AC — the skill auto-extracts acceptance criteria into plan tasks. Combine with `--quick` for small tasks or `--hotfix` for production incidents.

---

## Fallback Behavior

**Jira unreachable:** If Jira fetch fails — proceed with task description as acceptance criteria. Note `[Jira: UNAVAILABLE]` in dev-loop-context.md.

**Mode confirmation timeout:** If user doesn't respond to mode selection within 1 message → default to Full mode and proceed. Note the auto-selection in the triage output.

---

## Prerequisite Check

Before anything, verify agent teams are available:

```text
If TeamCreate tool is not available → check graceful degradation:
- If Task (subagent) tool is available → "Agent Teams not enabled. Running in subagent mode."
- If neither → "Running in solo mode. All phases executed by lead sequentially."
```

See [references/operational.md](references/operational.md) for degradation behavior details.

---

## Constraints

- **Max 3 teammates concurrent** — more adds coordination overhead without proportional value
- **Workers READ-ONLY during review** — no workers alive during Phase 4; reviewers never modify files
- **Lead is sole writer of dev-loop-context.md** — workers SendMessage; lead updates the file
- **Artifacts persist on disk** — `dev-loop-context.md`, plan file, `research.md`, `review-findings-*.md` survive context compression
- **YAGNI** — implement only what the task requires; speculative abstractions are review findings
- **Artifacts path** — ALL artifacts live at `{artifacts_dir}/{date}-{task-slug}/` (from `scripts/artifact-dir.sh dlc-build`); includes plan.md, research.md, verify-results.md, review-findings-*.md, dev-loop-context.md. `~/.claude/plans/` is no longer used.

---

## Gate Summary

| Transition | Key condition | Who decides |
| --- | --- | --- |
| Triage → Research/Plan | Blast-radius scored, mode confirmed | User |
| Research → Plan | research.md complete + validator PASS (+ GO/NO-GO Full) | User (Full) / Lead (Quick) |
| Plan → Implement | Plan written to artifacts_dir + must_haves.truths + challenger (Full) | User (Full) / Lead auto (Micro/Quick) |
| Implement → Verify | All tasks done + validate + workers shut down | Lead |
| Verify → Review | All truths PASS + key_links verified | Lead |
| Verify → Implement | ANY truth FAIL (Quick/Full, iteration_count < 3) | Lead (targeted) |
| Review Stage 1 → Stage 2 | Spec compliance PASS | Lead |
| Review Stage 1 FAIL → Implement | Spec non-compliance — return to Phase 3 | Lead |
| Review → Assess | Findings consolidated | Lead |
| Assess → Loop | Critical found, iteration_count < 3 | Lead |
| Assess → Ship | Zero Critical (or user accepts) | User/Lead |
| Assess → Escalate (STOP) | iteration_count = 3, still Critical | Lead |
| Ship → Done | User selects completion option | User |

Full gate details: [references/phase-gates.md](references/phase-gates.md)

## Gotchas

- **Agent Teams required for parallel phases** — without `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, the skill degrades to subagent or solo mode; phases that rely on parallel workers run sequentially, increasing token cost and time.
- **Phase 0 AC validation skips silently if Jira key is invalid** — if the key doesn't exist or Jira is unreachable, the skill proceeds using the raw task description as AC. Verify the Jira key resolves before invoking to avoid a silent no-op on acceptance criteria.
- **Research phase can exceed context budget on large repos** — the Explorer spawns multiple subagents to read files; on repos with hundreds of relevant files this burns context fast. Use `--quick` for small tasks; save `--full` for cross-cutting changes.
- **All artifacts in one folder** — `dev-loop-context.md`, `research.md`, `plan.md`, `verify-results.md`, and `review-findings-*.md` all live at `{artifacts_dir}/{date}-{task-slug}/`. `~/.claude/plans/` is no longer used by dlc-build for new runs.
- **Max 3 iterations is shared** — Phase 3.5 loops, Stage 1 FAIL loops, and review loops all consume the same `iteration_count` counter (max 3). This prevents runaway costs from multiple loop types each believing they have their own budget.
- **Phase 3.5 is mandatory** — every Implement → Review transition must pass through Phase 3.5 Verify. Skipping it after a Stage 1 FAIL is not permitted.
- **[NEEDS CLARIFICATION] replaces ClarifyQ** — clarifying questions are embedded as tokens in research.md (max 3, each with file:line evidence). No separate ClarifyQ phase. Quick and Hotfix modes use Lite research with no clarification tokens.
- **plan-challenger is Full mode only** — Micro and Quick modes write plans directly without a challenge step. Running plan-challenger on Micro/Quick adds overhead that defeats their purpose.
- **Auto-transition requires a Jira key + at least one Jira integration** — Step 2a transitions the Jira card to In Progress automatically after mode is confirmed. Uses atlassian-pm path if `issue-bootstrap` was available in Step 1c; falls back to `mcp-atlassian` (`jira_transition_issue`) if atlassian-pm is not installed; skips silently if neither is reachable.
- **WIP limit enforcement only on the atlassian-pm path** — the `pre_wip_limit_check` hook fires only when atlassian-pm is installed. On the mcp-atlassian fallback path, there is no WIP gate — the transition proceeds unconditionally.
