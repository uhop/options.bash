---
description: Update AI-facing docs (llms.txt, ARCHITECTURE.md, AGENTS.md) after API or structural changes
---

# AI Documentation Update

Update all AI-facing files after changes to modules or project structure.

## Steps

1. Read the changed `.sh` module files to identify what changed.
2. Read `AGENTS.md` and `ARCHITECTURE.md` for current state.
3. Update `llms.txt`:
   - Ensure module descriptions match the current API.
   - Update common patterns if new features were added.
   - Keep it concise — this is for quick LLM consumption.
4. Update `ARCHITECTURE.md` if project structure or module dependencies changed.
5. Update `AGENTS.md` if critical rules, commands, or architecture quick
   reference changed.
6. If `AGENTS.md` changed, run `/sync-ai-rules` to propagate to
   `.windsurfrules` / `.cursorrules` / `.clinerules`.
7. Update `wiki/Home.md` if the overview needs to reflect new features.
8. Update the relevant `wiki/<module>.md` page if a module's API changed.
9. Update `README.md` if user-facing features or examples changed.
10. Provide a summary of what was updated.
