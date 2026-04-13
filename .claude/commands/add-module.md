---
description: Checklist for adding a new module to options.bash
---

# Add a New Module

Follow these steps when adding a new `.sh` module.

## Steps

1. Create `<name>.sh` in the project root with the implementation.
   - Add `#!/usr/bin/env bash` shebang.
   - Add `set -euo pipefail`.
   - Add an include guard: `if type <sentinel_function> > /dev/null 2>&1; then return; fi`
   - Use `module::function` naming convention.
   - Auto-load dependencies relative to `BASH_SOURCE`.
   - No external dependencies.
2. Create `tests/manual/test-<name>.sh` with a manual test script.
   - Source the new module using a relative path.
   - Exercise key functions with visible output.
3. Run the test script to verify: `bash tests/manual/test-<name>.sh`
4. Create `wiki/<name>.sh.md` with usage documentation.
   - Include: module description, bash requirement, dependencies, include guard,
     all functions with signatures and examples.
5. Add a link to the new wiki page in `wiki/Home.md`.
6. Update `ARCHITECTURE.md`:
   - Add the module to the project layout tree.
   - Add it to the dependency graph and source-time dependency table.
7. Update `llms.txt` with the module's API reference.
8. Update `AGENTS.md` architecture quick reference if the module fits in the
   layer diagram.
9. Sync AI rules if `AGENTS.md` changed (run `/sync-ai-rules`).
10. Update `README.md` project structure and docs sections.
11. Run all automated tests: `bash tests/run.sh`
12. Run all manual tests to check for regressions:
    - `bash tests/manual/test-ansi.sh`
    - `bash tests/manual/test-args.sh -h`
    - `bash tests/manual/test-box.sh`
    - `bash tests/manual/test-box-stack.sh`
