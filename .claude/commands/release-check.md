---
description: Pre-release verification checklist for options.bash
---

# Release Check

Run through this checklist before tagging a new release.

## Steps

1. Check that `ARCHITECTURE.md` reflects any structural changes.
2. Check that `AGENTS.md` is up to date with any rule or workflow changes.
3. Check that `.windsurfrules`, `.cursorrules`, and `.clinerules` are in sync
   with `AGENTS.md` (run `/sync-ai-rules` if not).
4. Check that `wiki/Home.md` links to all module wiki pages.
5. Check that `llms.txt` is up to date with any API changes.
6. Check that `README.md` reflects the current feature set and examples.
7. Update version and date in `README.md` release history table.
8. Update `wiki/Release‐history.md` with the new release details.
9. Check that all wiki module pages match the current source code.
10. Check that the copyright year in `LICENSE` includes the current year.
11. Run all automated tests: `bash tests/run.sh`
12. Run all manual tests:
    - `bash tests/manual/test-ansi.sh`
    - `bash tests/manual/test-ansi-tput.sh`
    - `bash tests/manual/test-args.sh -h`
    - `bash tests/manual/test-args.sh --required=foo cmd`
    - `bash tests/manual/test-box.sh`
    - `bash tests/manual/test-box-stack.sh`
13. Verify sparse worktree clone works:
    `git clone --filter=blob:none --sparse <repo> test-clone && cd test-clone && git sparse-checkout set --no-cone '/*.sh' '/README.md'`
14. Stop and report — do **not** tag or push without explicit confirmation.
