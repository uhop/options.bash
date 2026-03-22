# Completion feature

## Idea

`args.sh` already registers options and commands. We can use that data to generate bash completion scripts.

When the user types a partial option (starting with `-`), suggest available options.
For commands, suggest available commands based on the current prefix.
When a command is already filled or not required, fall back to file completion — the standard behavior for most bash utilities.

## Implementation

A new module `args-completion.sh` generates bash completion scripts from `args.sh` data.

The completion script is printed to stdout via a `--bash-completion` immediate option (like `--help` and `--version`). This follows established conventions (`pip completion --bash`, `kubectl completion bash`, `rustup completions bash`). No generic `--bash` option — there is no precedent for one, and the name is too vague.

Use standard bash completion patterns: `complete -F`, `compgen`, `COMPREPLY`.

## Registration

Manually registering completion for every tool is tedious and error-prone. Two mechanisms:

**`--bash-completion` option** — manual fallback. The user runs `my-tool --bash-completion > ~/.local/share/bash-completion/completions/my-tool` or `eval "$(my-tool --bash-completion)"`.

**Bootstrap-level auto-registration** — the primary mechanism. The bootstrap file (`main.sh`) calls a helper that generates and writes completion files to `~/.local/share/bash-completion/completions/` for all registered tools. A timestamp check avoids redundant writes: the completion file is regenerated only when the tool script is newer.

This leverages bash-completion's lazy loading (2.0+): files in `~/.local/share/bash-completion/completions/` are loaded on demand, keyed by command name.

## fzf integration

### Tab completion (in `args-completion.sh`)

When `fzf` is available, the generated completion function pipes options and commands through `fzf` for fuzzy interactive selection instead of flat `COMPREPLY` lists. Without `fzf`, it falls back to standard completion transparently.

### Runtime interactive menus (future `args-fzf.sh`)

A separate module for using `fzf` inside scripts at runtime — unrelated to Tab completion:

- **Interactive picker** — prompt the user to select from a list when arguments are missing (e.g., "no target specified, pick one").
- **File/directory browser** — embedded fuzzy file selection within a tool's flow.
- **Multi-select** — choose multiple items from a list.
- **Preview panes** — show context for each choice.

These are in-script UX features, not shell completion. The two modules are independent.
