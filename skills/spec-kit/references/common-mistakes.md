# Common Mistakes to Avoid (spec-kit)

- **Specifying tech stack in step 2** — wait until `/speckit.plan` (step 4); early commitment constrains architecture before research reveals the real constraints
- **Expecting unlimited questions from `/speckit.clarify`** — capped at 5 per invocation and 10 total across the session; run it again if you need more coverage
- **Skipping `/speckit.clarify` without saying so** — ambiguities compound into plan/task errors; if intentionally skipping for a spike/prototype, explicitly state it so the agent doesn't block
- **Using free-form clarification before `/speckit.clarify`** — run structured clarify first (sequential, coverage-based, answers recorded in Clarifications); free-form refinement is a follow-up, not a replacement
- **Skipping plan validation (step 4.5)** — generated plans often include sequences or components not explicitly requested; audit before generating tasks
- **Not checking for over-engineering in the plan** — Claude can add unrequested components; always ask for rationale when something wasn't in the spec
- **Running `/speckit.tasks` without `plan.md`** — the command reads plan.md to generate granular steps; it will fail without it
- **Ignoring `[P]` markers in tasks.md** — tasks marked `[P]` have no sequential dependencies; running them serially wastes implementation time
- **Re-running `/speckit.constitution` carelessly** — it silently overwrites existing principles; export content you want to keep before re-running, overwrites are irreversible
- **Missing local CLI tools for `/speckit.implement`** — the agent runs tool commands (npm, dotnet, etc.); have them installed and at the correct version before starting
- **Only checking CLI output after implement** — runtime errors (e.g., browser console errors) may not appear in the terminal; test the running app and paste any errors back to the agent
- **Using spec-kit for throwaway spikes** — the workflow is designed for features worth keeping; for quick proof-of-concept experiments, skip spec-kit entirely and run `/speckit.specify` only after you decide to commit to the feature; forcing the full workflow on a spike wastes clarification budget on something you may discard
