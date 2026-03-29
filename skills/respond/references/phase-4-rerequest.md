# Phase 4: Re-request Review (Lead Only)

```bash
gh pr edit {pr} --add-reviewer {original_reviewer_login}
```

## Cleanup

Remove `respond-context.md` from the project root after re-review is requested — this file is
ephemeral scaffolding and must not remain as uncommitted state in the target project:

```bash
rm -f {artifacts_dir}/respond-context.md
```

## Final Summary

✅ **Good** — all fields populated, commit count matches threads:

```markdown
## Respond Review Complete

**PR:** #42
**Threads addressed:** 3
**Commits made:** 2
**Validate:** ✅ passes
**Re-review requested:** reviewer-a
```

❌ **Bad** — placeholders not filled in, validate status missing:

```markdown
## Respond Review Complete

**PR:** #{pr}
**Threads addressed:** {total}
**Commits made:** {count}
**Re-review requested:** {reviewer_login}
```

See [operational.md](operational.md) for Success Criteria checklist and team cleanup steps.
