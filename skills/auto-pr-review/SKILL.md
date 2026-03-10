---
name: auto-pr-review
description: Autonomous multi-agent PR review pipeline with specialized focus areas
context: fork
agent: general-purpose
argument-hints:
  - "review PR #123"
  - "review current PR"
---

# Autonomous PR Review

Multi-agent PR review pipeline that dispatches 4 specialized reviewers in parallel.

## Input

**PR number:** `$ARGUMENTS` — if empty, detect from current branch:

```bash
gh pr view --json number --jq '.number' 2>/dev/null
```

## Phase 1: Gather Context

Fetch PR metadata and diff:

```bash
gh pr view $PR --json title,body,labels,author,baseRefName,headRefName,changedFiles --jq '.'
gh pr diff $PR
gh pr diff $PR --name-only
```

Read CLAUDE.md if present — it contains project conventions.

## Phase 2: Parallel Sub-Agent Review

Dispatch **4 sub-agents in parallel** (all READ-ONLY). Each agent receives the full diff and changed file list.

### Agent 1: Security Reviewer

Focus areas:

- Hardcoded secrets, API keys, tokens, passwords in code or config
- `.env` values committed to source
- Auth/authz gaps: missing middleware, permission checks, token validation
- SQL injection, XSS, path traversal vectors
- Insecure crypto, weak hashing, missing input sanitization
- Exposed internal errors in API responses

Severity: 🔴 Critical (secrets, auth bypass) · 🟡 Warning (potential vectors)

### Agent 2: Test Coverage Analyzer

Focus areas:

- Changed files with **no corresponding test changes** — flag as 🔴
- New functions/methods/endpoints without test coverage
- Modified business logic where existing tests don't cover the new paths
- Edge cases visible in the diff but untested (null, empty, error paths)
- Test quality: tests that assert nothing meaningful, missing assertions

Severity: 🔴 Critical (untested new endpoint/use case) · 🟡 Warning (missing edge case)

### Agent 3: Conventions Checker

Focus areas:

- Naming conventions: files, classes, functions, variables (per project standards in CLAUDE.md)
- File/folder structure: files placed in correct layer/directory
- Import patterns: barrel imports, relative vs alias paths, circular dependencies
- Code style: early returns vs nesting, function length, single responsibility
- Framework-specific patterns (check CLAUDE.md for project stack)

Severity: 🟡 Warning (convention violation) · 🔵 Info (style suggestion)

### Agent 4: Env Consistency Checker

Focus areas:

- Scan diff for new `process.env.*`, `Env.get(...)`, `env(...)` references
- Cross-reference against `.env.example` — flag missing entries as 🔴
- Cross-reference against `env.ts` (or equivalent schema) — flag missing validation as 🔴
- Check for env vars used in code but not documented
- Verify default values are sensible (no production secrets as defaults)

Severity: 🔴 Critical (used but not in schema/example) · 🟡 Warning (questionable default)

**CHECKPOINT** — collect ALL 4 agent results before proceeding.

## Phase 3: Synthesize Review

Deduplicate findings across agents. Remove false positives by verifying each finding against actual code (read the file, don't guess).

Output a **Review Summary** in this format:

```markdown
## PR Review Summary: #<number> — <title>

### Overview
<1-2 sentence summary of what the PR does>

### Findings

#### 🔴 Critical
- [Security] <file>:<line> — <description>
- [Tests] <file> — <description>

#### 🟡 Warning
- [Conventions] <file>:<line> — <description>
- [Env] <var_name> — <description>

#### 🔵 Info
- [Conventions] <file>:<line> — <description>

### Stats
- Files changed: X
- Critical: X | Warning: X | Info: X
- Test coverage: X changed files have tests / Y total changed

### Verdict
🔴 REQUEST_CHANGES | 🟡 COMMENT | 🟢 APPROVE
```

## Constraints

- Always read files before making claims — never speculate about code you haven't opened.
- Only review changed files (in the diff), not the entire codebase.
- If no issues found, say so clearly and approve.
