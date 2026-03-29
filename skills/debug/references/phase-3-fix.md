# Phase 3: Fix + Harden

Create Fixer in same team using prompts from [teammate-prompts.md](teammate-prompts.md):

- **Full mode:** Full Mode Fixer prompt (references investigation.md)
- **Quick mode:** Quick Mode Fixer prompt (includes condensed DX checklist from [dx-checklist.md](dx-checklist.md))Fixer executes Fix Plan from `investigation.md`.

Commit strategy: one commit per Fix Plan item — `fix(area)`, `test(area)`, `dx(area)`.

## Verification Loop

After **each Fix Plan item** committed by Fixer, Lead independently verifies before Fixer continues:

```text
1. Run validate command and read actual output (do not trust Fixer's "tests pass" claim)
2. If validate FAILS:
   a. Send exact error output to Fixer: "Validate failed with: {error_text} — retry"
   b. Fixer retries (attempt counter increments)
   c. If 3 retries on same item → escalate (see below)
3. If validate PASSES: confirm to Fixer and continue to next Fix Plan item
```

**If fix fails 3 times on the same item:**

1. Present all attempts + error patterns to user
2. **Check alternative hypothesis first** — if `investigation.md` has an alternative hypothesis, offer: "Try alternative hypothesis: {hypothesis} before full re-investigation"
3. If alternative also fails or none exists → offer 4 escalation options (see phase-gates.md)

After all Fix Plan items done, Lead shuts down Fixer.

**Final Lead Verification (do not rely on Fixer's claims):**

1. Run validate command fresh and read actual output
2. `git diff --stat HEAD~N` — confirm scope matches Fix Plan (N = number of fix commits)
3. `rtk git log --oneline -10` — confirm one commit per Fix Plan item
4. `git status` — confirm clean working tree

**GATE:** All Fix Plan items done + Final Lead verification passes → proceed.

## Phase 4: Fix Review (conditional)

Run Fix Review if: `--review` flag was passed **or** severity is P0.

Create Fix Reviewer in same team using prompts from [teammate-prompts.md](teammate-prompts.md).
Provide: fix commit hashes (from `rtk git log --oneline -N`), root cause summary from `investigation.md`.

After Fix Reviewer completes, Lead shuts down Fix Reviewer.

**If Fix Reviewer finds Critical issues** → Lead presents findings to user and asks whether to fix before shipping or proceed.
**If Fix Reviewer finds only Warnings/Info** → include in Debug Summary; proceed to Phase 5.
