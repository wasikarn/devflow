# Output Template and Key Principles

## Output Template

When presenting analysis, use this structure. The template below shows a filled-in example.

✅ **Good** — all sections populated, specific evidence, quantified where possible:

```markdown
## System Map
[AI Coding Speed ↑] → feeds → [Code Output Volume ↑] → triggers → [Review Queue ↑]
                                                        → also affects → [PR Merge Rate ↑]

## System Strengths
- CI/CD pipeline acts as balancing loop — catches regressions before they compound

## Feedback Loops
- R1: Speed Spiral — AI speed ↑ → output ↑ → team expects more → AI used more → speed ↑
- B1: Review Brake — output ↑ → review queue ↑ → PR wait time ↑ → output ↓

## Bottleneck Analysis
- Current: code review (2 reviewers, 15 PRs/week backlog)
- After intervention: merge conflicts (more parallel branches → more conflicts)
- Shift risk: Medium — 2 reviewers can absorb ~20 PRs/week, but conflicts scale non-linearly

## Critical Thinking
- Key assumption: review quality stays constant as volume grows
- Weakest link: we assumed reviewers won't fatigue — 50+ PRs/week will degrade quality
- Missing evidence: actual reviewer capacity data

## System Health Assessment

| Dimension | Score | Reason |
| --- | --- | --- |
| Loop balance | 2/5 | R1 (speed spiral) dominates; B1 weak |
| Bottleneck clarity | 4/5 | Review queue is clearly measurable |
| Intervention reversibility | 5/5 | Adding review automation is fully reversible |
| Feedback signal | 3/5 | PR wait time visible; reviewer fatigue is not |

**Overall: 3/5** — system optimized for output speed, not output quality. Fragile under volume.

## Recommendation
- Leverage point: strengthen B1 (Review Brake) via automated review tooling
- Why this point: reduces cognitive load on reviewers → quality holds as volume grows
- Risk if wrong: automation misses context-sensitive bugs → false confidence
- How to verify: track Critical findings per PR before/after — should stay ≥ 1 per 10 PRs
```

❌ **Bad** — only symptoms, no feedback loops, no bottleneck shift, no evidence:

```markdown
## Analysis
The team is generating too much code too fast. Reviewers are overwhelmed.
We should slow down AI usage or hire more reviewers.
```

When presenting analysis, structure your output as:

```markdown
## System Map
[Components and connections]

## System Strengths
- [existing balancing mechanism or resilient pattern that's already working]

## Feedback Loops
- R1: [name] — [description]
- B1: [name] — [description]

## Bottleneck Analysis
- Current: [where]
- After intervention: [where it shifts] — Shift risk: [Low/Medium/High]
- Downstream capacity: [assessment]

## Critical Thinking
- Key assumption: [what we're assuming]
- Weakest link in reasoning: [where the logic is thinnest]
- Missing evidence: [what we don't know]

## System Health Assessment

| Dimension | [1-5] | Reason |
| --- | --- | --- |
| Loop balance | | R:B ratio — many R, few B = fragile |
| Bottleneck clarity | | Is the constraint well-identified? |
| Intervention reversibility | | Can we undo the proposed change? |
| Feedback signal | | Will we know if it's working? |

**Overall: [1-5]** — [one-line summary]

## Recommendation
- Leverage point: [what to change]
- Why this point: [reasoning]
- Risk if wrong: [what happens]
- How to verify: [feedback signal to watch]
```

## Key Principles

- **See the whole, not the parts** — problems are rarely where they appear
- **Respect feedback loops** — they're more powerful than any single intervention
- **Today's solution is tomorrow's problem** — always ask "then what?"
- **The system is not broken, it's perfectly designed for the results it gets** — change the design, not the symptoms
