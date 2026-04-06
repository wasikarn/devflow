# promote-hard-rule skill

Interactive review workflow for auto-detected Hard Rule candidates from `metrics-analyst` — approve, reject, or defer each candidate before it enters `hard-rules.md`.

## Skill Architecture

- `SKILL.md` only — no `references/` directory
- 5-step workflow: Locate → Parse → Review each candidate → Apply decisions → Summary
- Reads `.claude/skills/review-rules/candidate-rules.md` in the current project (written by `metrics-analyst`)
- Writes approved rules to `.claude/skills/review-rules/hard-rules.md` with evidence comments
- `allowed-tools: Read, Edit, Write, AskUserQuestion`

## Validate After Changes

```bash
npx markdownlint-cli2 "skills/promote-hard-rule/SKILL.md"
```

## Gotchas

- Candidate file path (`.claude/skills/review-rules/candidate-rules.md`) must match exactly what `metrics-analyst` writes. If `metrics-analyst` changes its output path, update the Step 1 `CANDIDATE_FILE` variable here.
- Evidence threshold (score ≥70, appearing in ≥3 of 5 sessions) should stay in sync with `metrics-analyst` candidate generation logic — if `metrics-analyst` raises the bar, update the Gotchas note in SKILL.md too.
- REJECTED entries are never deleted from `candidate-rules.md` — this is intentional for audit trail. Do not add cleanup logic.
- If `hard-rules.md` does not exist, the skill creates it before appending — this is handled in Step 4 APPROVE. Do not assume the file exists in tests.
- Evidence HTML comment format (`<!-- promoted: {date} | evidence: {count}/5 sessions ... -->`) is used by downstream tools to distinguish auto-promoted rules from manually written ones — keep the format stable.
- This skill can auto-trigger from description matching — description is specific enough to avoid false positives in builds or reviews.
