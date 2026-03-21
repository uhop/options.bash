---
description: Pre-release verification checklist for options.bash
---

# Release Check

Run through this checklist before tagging a new release.

## Steps

1. Check that `ARCHITECTURE.md` reflects any structural changes.
2. Check that `AGENTS.md` is up to date with any rule or workflow changes.
3. Check that `.windsurfrules` and `.clinerules` are in sync with `AGENTS.md`.
4. Check that `wiki/Home.md` links to all module wiki pages.
5. Check that `llms.txt` is up to date with any API changes.
6. Check that `README.md` reflects the current feature set and examples.
7. Update version and date in `README.md` release history table.
8. Update `wiki/Release‐history.md` with the new release details.
9. Check that all wiki module pages match the current source code.
10. Check that the copyright year in `LICENSE` includes the current year (e.g., update `2025` → `2025-2026` or `2005-2024` → `2005-2026`).
11. Run all automated tests: `bash tests/run.sh`
    // turbo
12. Run all manual tests:
    // turbo
13. `bash tests/manual/test-ansi.sh`
    // turbo
14. `bash tests/manual/test-ansi-tput.sh`
    // turbo
15. `bash tests/manual/test-args.sh -h`
    // turbo
16. `bash tests/manual/test-args.sh --required=foo cmd`
    // turbo
17. `bash tests/manual/test-box.sh`
    // turbo
18. `bash tests/manual/test-box-stack.sh`
19. Verify sparse worktree clone works:
    `git clone --filter=blob:none --sparse <repo> test-clone && cd test-clone && git sparse-checkout set --no-cone '/*.sh' '/README.md'`
20. Tag the release: `git tag <VERSION>`
