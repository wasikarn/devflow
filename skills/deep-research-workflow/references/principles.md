# Principles

## Anti-patterns

- Jumping from prompt to code without written plan → missing conventions cause wrong assumptions that compound silently
- Chat-based steering instead of document-based annotation → chat messages get context-compressed; only `plan.md` Annotations survive long sessions
- Patching a bad approach incrementally instead of reverting → each patch adds complexity on top of a wrong foundation; technical debt compounds
- Using loose/any types to make things compile quickly → defers type errors to runtime; harder to trace and fix later
- Adding unnecessary comments or jsdocs to generated code → noise that clutters the codebase; well-named code is self-documenting
- Allowing scope creep during implementation phase → plan becomes inaccurate; hard to verify completion or revert cleanly
- Splitting research, planning, and implementation across separate sessions — single long sessions preserve context better
- Skipping open questions — unresolved ambiguities compound into plan errors

## Key Rules

- **Persistent artifacts** — `research.md` and `plan.md` anchor context through compression; if context is compacted, re-read both files before continuing
- **Plan before code** — all creative decisions happen in research/planning; implementation is execution only
- **Revert over patch** — if going wrong, revert and re-scope; incremental patches compound mistakes
- **Scope trimming** — actively cut scope; a smaller correct feature beats a larger broken one
- **Reference existing patterns** — use codebase code as specification, not abstract design
- **Emphatic depth** — surface-level research causes surface-level bugs; read deeply, trace fully
- **Annotation cycles are valuable** — 1–6 rounds of plan review catches more issues than rushing to code
