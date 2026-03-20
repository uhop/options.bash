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
7. Check that all wiki module pages match the current source code.
8. Run all manual tests:
   // turbo
9. `bash tests/manual/test-ansi.sh`
   // turbo
10. `bash tests/manual/test-ansi-tput.sh`
    // turbo
11. `bash tests/manual/test-args.sh -h`
    // turbo
12. `bash tests/manual/test-args.sh --required=foo cmd`
    // turbo
13. `bash tests/manual/test-box.sh`
    // turbo
14. `bash tests/manual/test-box-stack.sh`
15. Verify sparse worktree clone works:
    `git clone --filter=blob:none --sparse <repo> test-clone && cd test-clone && git sparse-checkout set --no-cone '/*.sh' '/README.md'`
16. Tag the release: `git tag -a v<VERSION> -m "Release v<VERSION>"`
