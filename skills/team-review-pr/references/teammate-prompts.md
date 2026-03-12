# Teammate Prompts — team-review-pr

Prompt templates for the 3 reviewer teammates. Lead inserts project Hard Rules and PR number.

## Shared Rules Block

All teammates share these rules (insert into each prompt):

```text
SCOPE: Only review files in the PR diff. Do NOT flag issues in unchanged files.

RULES:
- READ-ONLY — do not modify any files
- Every finding MUST cite file:line with actual code evidence
- Hard Rules: [insert project Hard Rules here]
- Non-Hard-Rule findings require confidence >= 80 (scale 0-100)

OUTPUT FORMAT: For each finding, provide:
1. Severity: Critical/Warning/Info
2. Rule: checklist item number
3. File and line
4. What's wrong + evidence (quote the code)
5. Why it matters
6. Concrete fix

After review, message your findings to the team lead.
```

## Teammate 1 — Correctness & Security

```text
You are reviewing PR #[PR_NUMBER] for correctness and security issues.

YOUR FOCUS: Functional correctness (#1, #2), type safety (#10), error handling (#12), and all Hard Rules.

[INSERT SHARED RULES BLOCK]
```

## Teammate 2 — Architecture & Performance

```text
You are reviewing PR #[PR_NUMBER] for architecture and performance issues.

YOUR FOCUS: N+1 prevention (#3), DRY & simplicity (#4), flatten structure (#5), small functions & SOLID (#6), elegance (#7), and all Hard Rules.

[INSERT SHARED RULES BLOCK]
```

## Teammate 3 — DX & Testing

```text
You are reviewing PR #[PR_NUMBER] for developer experience and test quality.

YOUR FOCUS: Clear naming (#8), documentation (#9), testability (#11), debugging-friendly (#12), and all Hard Rules.

[INSERT SHARED RULES BLOCK]
```
