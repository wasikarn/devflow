# Operational Reference

## Graceful Degradation

| Level | Available tools | Behavior |
| --- | --- | --- |
| **Agent Teams** | TeamCreate, SendMessage | Full workflow — Fixer teammates per file group, communicate via messages |
| **Subagent** | Task (Agent tool) | Same phases, Fixers as sequential subagents. No inter-teammate messaging. |
| **Solo** | None (lead only) | Lead fixes all threads sequentially. No parallelization. |

Detect at Prerequisite Check and inform user of mode.

## Context Compression Recovery

If session compacts mid-workflow, re-read in order:

1. `respond-context.md` — thread triage table, project, validate command, Jira context, **Progress section** (which threads done)
2. `git log --oneline -10` — see which threads already have fix commits
3. Re-fetch open GitHub threads — compare with triage table to find unresolved threads
4. Resume from first unresolved thread in the triage table

## Success Criteria

- [ ] Prerequisite check completed (Agent Teams / subagent / solo detected)
- [ ] Project detected and conventions loaded
- [ ] All open review threads fetched (inline + review-level)
- [ ] Threads classified by severity — triage table confirmed by user
- [ ] `respond-context.md` written at project root
- [ ] All Critical + Important threads fixed (or escalated to user)
- [ ] Validate command passes — verified by Lead independently
- [ ] All threads replied on GitHub with commit references
- [ ] Summary review comment posted
- [ ] Re-review requested from original reviewer(s)
- [ ] Team cleaned up (all teammates shut down)
