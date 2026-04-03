# Token Optimization for Devflow

**Date:** 2026-04-03
**Status:** Approved
**Author:** Claude (via brainstorming session)

## Executive Summary

Reduce token usage in devflow skills by 30-60% through targeted optimizations: field filtering for bootstrap agents, token metrics tracking, and PR diff filters. A simplified token budget watchdog replaces the proposed 4-agent team.

## Problem Statement

Devflow skills consume significant tokens through:
1. **Full MCP responses** — Jira/Confluence APIs return full issue/page content
2. **Unfiltered PR diffs** — Large PRs include lockfiles, generated files, vendored code
3. **No token visibility** — No tracking of per-skill/phase token costs
4. **No budget enforcement** — Expensive operations run without cost awareness

## Solution Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     devflow skills                          │
│  (build, review, debug, respond, merge-pr, etc.)           │
└───────────────────────┬─────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│  Bootstrap    │ │ Token Budget  │ │ Token Metrics │
│  Agents       │ │ Watchdog      │ │ Tracking      │
│  (--fields)   │ │ (1 agent)     │ │ (TypeScript)  │
└───────┬───────┘ └───────┬───────┘ └───────┬───────┘
        │                 │                 │
        ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│              devflow-metrics.jsonl                          │
│  { "tokens": { "input", "output", "estimated", "phase" } }  │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Bootstrap Agents (Field Filtering)

**Verdict:** ✅ PROCEED

**What:** Add `--fields` parameter to `issue-bootstrap` agent for filtered MCP calls.

**Why:** MCP calls return full issue content (~15K tokens). Field filtering reduces to essential fields only (~2-3K tokens).

**Implementation:**

```typescript
// agents/issue-bootstrap.md (enhancement)
// Add --fields parameter with presets:

// Presets (recommended):
//   --preset=review    → fields=key,status,assignee,summary,description
//   --preset=build     → fields=key,summary,acceptance_criteria,subtasks
//   --preset=debug     → fields=key,summary,priority,linked_issues

// Custom fields:
//   --fields=key,status,summary
```

**Token Savings:** 8,000-15,000 per skill invocation

**Files Changed:**
- `skills/jira-integration/SKILL.md` — Add preset detection logic
- `agents/devflow-build-bootstrap.md` — Pass `--preset=build`
- `agents/devflow-debug-bootstrap.md` — Pass `--preset=debug`
- `agents/pr-review-bootstrap.md` — Pass `--preset=review`

---

### 2. Token Metrics Tracking

**Verdict:** ✅ PROCEED

**What:** Extend `devflow-metrics.jsonl` with token tracking fields.

**Why:** No visibility into per-skill/phase token costs. Foundation for budget enforcement.

**Implementation:**

```jsonl
// devflow-metrics.jsonl (extended schema)
{
  "timestamp": "2026-04-03T15:00:00Z",
  "skill": "build",
  "phase": "research",
  "mode": "full",
  "tokens": {
    "input": 15000,
    "output": 3000,
    "estimated_mcp": 5000,
    "cumulative_session": 45000
  }
}
```

**Schema Versioning:**
- Add `schema_version: "1.1"` field
- Backward compatible — old entries remain readable
- New entries include token fields

**Files Changed:**
- `devflow-engine/src/metrics.ts` — Add token tracking
- `skills/metrics/SKILL.md` — Display token metrics
- `skills/dashboard/SKILL.md` — Show token summary

**Token Overhead:** Minimal (50-100 tokens per append)

---

### 3. PR Diff Filters

**Verdict:** ✅ PROCEED

**What:** Extend existing `--focused` flag with file filtering.

**Why:** Large PRs include lockfiles, generated files, vendored code that consume tokens without review value.

**Implementation:**

```bash
# Extend --focused in review skill
rtk gh pr diff "$PR_NUM" --files "*.ts,*.tsx" --exclude "*.test.ts,*.spec.ts"

# Threshold-based auto-filter
if [[ $(git diff --numstat | wc -l) -gt 100 ]]; then
  # Auto-exclude common noise
  EXCLUDE="--exclude package-lock.json,*.min.js,yarn.lock"
fi
```

**Token Savings:** 10,000-50,000 for large PRs

**Files Changed:**
- `skills/review/SKILL.md` — Add `--files` and `--exclude` parameters
- `agents/pr-review-bootstrap.md` — Auto-filter logic

---

### 4. Token Budget Watchdog (Simplified)

**Verdict:** ✏️ REVISE (4 agents → 1 agent)

**What:** Single agent monitors token budget and warns when approaching threshold.

**Why:** Prevent runaway token costs on expensive operations. Originally 4-agent team, simplified to 1 agent after review.

**Implementation:**

```markdown
# agents/token-watchdog.md
name: token-watchdog
description: Monitor session token budget and warn when approaching threshold.
model: haiku
invocation: Spawned at named injection points (after_bootstrap, before_review)

## Behavior
1. Read cumulative tokens from devflow-metrics.jsonl
2. Compare against threshold (default: 50k tokens)
3. If approaching threshold:
   - Output warning with suggestions
   - Recommend alternatives (compact mode, reduced scope)
4. Never block — warn only

## Threshold
- Default: 50,000 tokens per session
- Configurable via --budget-threshold flag
```

**Named Injection Points:**
- `after_bootstrap` — After context gathering
- `before_review` — Before spawning review agents
- `before_plan` — Before planning phase

**Token Overhead:** 500-800 tokens per check

**Files Changed:**
- `agents/token-watchdog.md` — New agent
- `skills/build/SKILL.md` — Add injection point hooks
- `skills/review/SKILL.md` — Add injection point hooks

---

### 5. Compact Scripts

**Verdict:** ❌ BLOCK (Superseded by field filtering)

**Reason:** Functionality covered by Bootstrap Agents `--fields` parameter. Adding Python scripts would:
- Introduce new language stack
- Duplicate atlassian-pm presets
- Violate YAGNI principle

**Action:** Remove from scope, redirect effort to Component 1.

---

## Architecture Decisions

### Decision 1: TypeScript Only

**Context:** Maintainability Expert flagged Python as new language stack.

**Decision:** All new code uses TypeScript (devflow-engine) or Bash (scripts).

**Rationale:**
- Single language stack reduces complexity
- Shares existing tooling (bun test, TypeScript, linting)
- No new CI/CD pipeline changes

---

### Decision 2: Named Injection Points

**Context:** Integration Specialist flagged "Phase 0.5" as confusing.

**Decision:** Use named injection points instead of numbered phases.

**Rationale:**
- `after_bootstrap` is clearer than "Phase 0.5"
- No renumbering of existing phases
- Easier to add new injection points

**Named Points:**
```
before_bootstrap → bootstrap → after_bootstrap →
before_plan → plan → after_plan →
before_review → review → after_review →
```

---

### Decision 3: Session-Level Budget

**Context:** Token budget scope unclear (per-skill vs per-session).

**Decision:** Budget applies per-session, not per-skill.

**Rationale:**
- Avoids coordination overhead between skills
- Cumulative tracking is simpler
- Matches user mental model ("this session cost X tokens")

---

### Decision 4: Warning-Only Budget Enforcement

**Context:** Cost Analyst flagged negative ROI for blocking operations.

**Decision:** Token Budget Watchdog warns but never blocks.

**Rationale:**
- Blocking requires complex fallback logic
- Warning preserves user agency
- User can decide to proceed or optimize

---

## Implementation Phases

### Phase 1 (Immediate)

| Task | Effort | Files |
|------|--------|-------|
| Add `--fields` to issue-bootstrap | M | agents/issue-bootstrap.md |
| Update jira-integration skill | M | skills/jira-integration/SKILL.md |
| Update bootstrap agents | L | agents/devflow-*.md |
| Add token tracking to metrics | L | devflow-engine/src/metrics.ts |

**Success Metric:** Track token savings in devflow-metrics.jsonl

---

### Phase 2 (Next Sprint)

| Task | Effort | Files |
|------|--------|-------|
| Extend `--focused` with filters | M | skills/review/SKILL.md |
| Add auto-filter logic | M | agents/pr-review-bootstrap.md |
| Update dashboard skill | L | skills/dashboard/SKILL.md |

**Success Metric:** Measure diff filtering effectiveness on PRs >30 files

---

### Phase 3 (After Metrics Validation)

| Task | Effort | Files |
|------|--------|-------|
| Create token-watchdog agent | M | agents/token-watchdog.md |
| Add injection points to build | M | skills/build/SKILL.md |
| Add injection points to review | L | skills/review/SKILL.md |
| Add budget-threshold flag | L | skills/*/SKILL.md |

**Success Metric:** Validate threshold assumptions before full rollout

---

## Expected Impact

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Jira fetch tokens | ~15,000 | ~3,000 | 80% reduction |
| Large PR diff tokens | ~50,000 | ~10,000 | 80% reduction |
| Session visibility | None | Full tracking | New capability |
| Budget awareness | None | Warning system | New capability |

**Overall:** 30-60% token reduction per session

---

## Risks and Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Field filtering misses needed data | Low | Medium | Default to full context, explicit opt-in for filtering |
| Metrics overhead | Low | Low | Append-only, minimal fields |
| Watchdog false positives | Medium | Low | Warning-only, user decides |
| Breaking existing behavior | Low | High | Feature flags, gradual rollout |

---

## Future Considerations

1. **Context caching** — Share loaded references across skills (not in scope)
2. **SDK token tracking** — Track actual token counts from Claude Code API (requires API changes)
3. **MCP overhead tracking** — Track MCP call overhead (not trackable without API support)

---

## References

- [skills-best-practices.md](../../references/skills-best-practices.md) — Skill authoring guidelines
- [agent-hook-pattern.md](../../references/agent-hook-pattern.md) — Agent architecture
- [jira-integration/SKILL.md](../../skills/jira-integration/SKILL.md) — Current Jira integration
- [devflow-metrics.jsonl](../../devflow-metrics.jsonl) — Metrics schema