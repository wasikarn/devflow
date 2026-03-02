# claude-code-skills

Personal collection of Claude Code skills (custom slash commands) for structured development workflows.

## Installation

Skills are symlinked from `~/.claude/skills/` — changes here take effect immediately in all Claude Code sessions.

```bash
# Link a skill to Claude Code
ln -s "$(pwd)/skills/<name>" ~/.claude/skills/<name>
```

---

## Skills

### PR Review Skills (`*-review-pr`)

Three project-specific skills sharing the same architecture. Dispatch **7 parallel agents**, verify Jira AC, then fix code (Author) or submit inline GitHub review comments in Thai (Reviewer).

| Skill | Project | Tech Stack | Validate Command |
|-------|---------|-----------|-----------------|
| `/api-review-pr` | tathep-platform-api | AdonisJS 5.9 + Effect-TS + Japa | `npm run validate:all` |
| `/web-review-pr` | tathep-website | Next.js 14 Pages Router + Chakra UI + React Query | `npm run ts-check && npm run lint:fix && npm test` |
| `/admin-review-pr` | tathep-admin | Next.js 14 Pages Router + Tailwind + Vitest | `npm run ts-check && npm run lint@fix && npm run test` |

**Usage:**

```bash
/api-review-pr 42              # PR #42, Author mode (fix code)
/api-review-pr 42 BEP-123      # with Jira ticket
/api-review-pr 42 Reviewer     # submit inline comments in Thai
/api-review-pr 42 BEP-123 Reviewer
```

**7 Agents dispatched in parallel (foreground, READ-ONLY):**

| Agent | Aspects Covered |
|-------|----------------|
| `pr-review-toolkit:code-reviewer` | Correctness, Architecture, N+1, DRY, Elegance, React/Next.js (#1–4, #7, #13) |
| `pr-review-toolkit:comment-analyzer` | Documentation quality (#9) |
| `pr-review-toolkit:pr-test-analyzer` | Test coverage (#11) |
| `pr-review-toolkit:silent-failure-hunter` | Error handling, debugging (#1, #12) |
| `pr-review-toolkit:type-design-analyzer` | TypeScript type design (#10) |
| `pr-review-toolkit:code-simplifier` | DRY, flatten, SOLID, naming (#4–6, #8) |
| `feature-dev:code-reviewer` | Clean Code + TS advanced types (confidence ≥80 only) |

**12-Point Checklist:**

| # | Aspect | Category |
|---|--------|----------|
| 1 | Functional Correctness | Correctness & Safety |
| 2 | Architecture / App Helpers | Correctness & Safety |
| 3 | N+1 Prevention | Performance |
| 4 | DRY & Simplicity | Maintainability |
| 5 | Flatten Structure | Maintainability |
| 6 | SOLID & Clean Architecture | Maintainability |
| 7 | Elegance / Effect-TS Usage | Maintainability |
| 8 | Clear Naming | Developer Experience |
| 9 | Documentation & Comments | Developer Experience |
| 10 | Type Safety (TS Advanced Types) | Developer Experience |
| 11 | Testability | Developer Experience |
| 12 | Debugging Friendly | Developer Experience |
| 13 | React/Next.js Performance *(web/admin only)* | Framework |

**QG Score:** starts 100 — Critical = −15, Important = −5, Suggestion = −1. Gate: 100 = PASS, 85–99 = CONDITIONAL, <85 = FAIL.

---

### `/spec-kit` — Spec-Driven Development

Full SDD workflow using [spec-kit](https://github.com/github/spec-kit). Guides through 6 steps from requirements to working code.

**6-Step Workflow:**

| Step | Command | Output |
|------|---------|--------|
| 1 | `/speckit.constitution` | `.specify/memory/constitution.md` — do once |
| 2 | `/speckit.specify <what>` | `spec.md` + `checklists/requirements.md` + git branch |
| 3 | `/speckit.clarify` | Updates `spec.md` Clarifications (max 5 questions) |
| 4 | `/speckit.plan <tech stack>` | `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/` |
| 5 | `/speckit.tasks` | `tasks.md` with `[P]` parallel markers |
| 6 | `/speckit.implement` | Marked `[X]` tasks, working code |

**Optional quality gates** (between steps 5–6):

- `/speckit.analyze` — cross-artifact consistency check (CRITICAL/HIGH/MEDIUM/LOW, max 50 findings, read-only)
- `/speckit.checklist` — requirement quality checklists (`checklists/[domain].md`)
- `/speckit.taskstoissues` — convert `tasks.md` to GitHub issues (requires GitHub MCP server)

**CLI:**

```bash
# Install
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Bootstrap
specify init my-project --ai claude
specify init --here --ai claude --ai-skills
```

---

### `/deep-research-workflow` — Research → Plan → Implement

Structured workflow for complex features requiring research before implementation. Produces a research report, architecture plan, and implementation steps.

---

### `/optimize-context` — CLAUDE.md Optimizer

Audit, score, and optimize CLAUDE.md files across a project. 5-phase workflow: discover → assess → score → propose → apply.

---

## Integration Patterns

### ralph-loop + spec-kit

[Ralph Loop](https://ghuntley.com/ralph/) (iterative self-referential agent loop) pairs naturally with spec-kit because spec-kit produces **verifiable artifacts** — tasks.md checkboxes and SC-NNN success criteria — that serve as concrete completion signals.

**Best fit: automate Phase 6 (`/speckit.implement`)**

```bash
/ralph-loop:ralph-loop "Run /speckit.implement. After each session run tests.
If tests fail, fix them and continue.
Output DONE only when: all tasks.md items are [X], all tests pass,
and all SC-NNN in spec.md are satisfied." \
  --completion-promise "DONE" \
  --max-iterations 30
```

**Iterative spec quality loop:**

```bash
/ralph-loop:ralph-loop "Run /speckit.analyze.
If CRITICAL or HIGH findings exist, fix them in spec.md.
Output SPEC_CLEAN only when analyze reports zero CRITICAL/HIGH issues." \
  --completion-promise "SPEC_CLEAN" \
  --max-iterations 10
```

**Full-auto with phase detection:**

```bash
/ralph-loop:ralph-loop "Check current spec-kit phase:
bash ~/.claude/skills/spec-kit/scripts/detect-phase.sh
Execute the recommended next_action.
Output FEATURE_DONE only when current_step is 6_complete." \
  --completion-promise "FEATURE_DONE" \
  --max-iterations 50
```

**When to use ralph-loop per step:**

| Step | Ralph-loop? | Reason |
|------|------------|--------|
| 1–3 (constitution/specify/clarify) | ❌ | Requires human judgment / input |
| 4 (plan) | ❌ | User must provide tech stack |
| 5 (tasks) | ❌ | Single-shot |
| quality gates (analyze/checklist) | ✅ | Loop until zero findings |
| 6 (implement) | ✅✅ | Tests are natural verifiers |

**Tips:**

- Use SC-NNN from `spec.md` as completion criteria — already measurable
- Respect `[P]` markers in `tasks.md` to identify parallelizable work
- Always set `--max-iterations` as safety net
- Never ralph-loop steps requiring human input (specify/plan/clarify)

---

## Skill Structure

```
skills/<name>/
  SKILL.md          # Main entry point (YAML frontmatter + workflow)
  references/       # Supporting docs referenced from SKILL.md
  scripts/          # Helper scripts
```

**SKILL.md frontmatter keys:**

```yaml
name: skill-name
description: "When to invoke (Claude uses this to match intent)"
argument-hint: "[pr-number] [jira-key?] [Author|Reviewer]"
context: fork                       # Isolate in fork context
disable-model-invocation: true      # Prevent nested model calls
```
