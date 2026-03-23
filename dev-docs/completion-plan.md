# Completion implementation plan

## Overview

New module `args-completion.sh` that generates bash completion scripts from `args.sh` registration data. Provides a `--bash-completion` handler (explicit opt-in per tool, like `--help` and `--version`) and bootstrap-level auto-registration via an `args::parse` wrapper.

## Available data

After `args::option` calls, these `args.sh` globals contain everything needed to generate completions:

| Variable | Type | Content |
|----------|------|---------|
| `args_program_name` | string | Program name |
| `args_list` | indexed array | Primary option/command names in registration order |
| `args_names` | assoc array | Primary name → full names string (e.g., `"-v, --version"`) |
| `args_aliases` | assoc array | Every name → primary name |
| `args_option_has_arg` | assoc array | Primary name → arg name (empty = flag) |
| `args_option_arg_optional` | assoc array | Primary name → non-empty if arg is optional |
| `args_check_command` | integer | `0` if any commands are defined |

## Module: `args-completion.sh`

### Conventions

Follows all project conventions:

- Include guard: `args::option::completion`
- `set -euo pipefail`
- Depends on `args.sh` (auto-loaded)
- Function namespace: `args::completion::` (public API), `args::option::completion` (handler)
- No external dependencies

### Public API

#### `args::completion::generate`

Generates a bash completion script and prints it to stdout. Reads registered options and commands from `args.sh` globals. The generated script contains:

1. A completion function `_complete_<name>`
2. A `complete -F` registration
3. An `_fzf_complete_<name>` function for fzf integration

#### `args::completion::register`

Writes the completion script to `~/.local/share/bash-completion/completions/<name>`. Skips the write if the completion file already exists and is newer than the tool script (timestamp check via `-nt`). Creates the directory if needed. Fails silently (returns 0) if the directory is not writable — completion is a convenience, not a requirement.

Uses `BASH_SOURCE` to find the calling tool script's path for the timestamp comparison.

#### `args::option::completion`

Immediate option handler for `--bash-completion`. Calls `args::completion::generate` and exits with code 0.

### Explicit opt-in (follows `args-help.sh` / `args-version.sh` pattern)

The module does **not** auto-register `--bash-completion` as an option. It only provides the handler function and utilities. Each tool that wants completion support must explicitly declare the option, just like `--help` and `--version`:

```bash
args::option "--bash-completion" "Output bash completion script"
args::option "-v, --version" "Show version"
args::option "-h, --help" "Show help"
```

This follows the established pattern in existing utilities (`arx`, `upd`, `cln`, `jot`), where every tool explicitly declares the options it supports. The module is sourced from `bootstrap.sh` (bootstrap) and available to all tools, but enabling the `--bash-completion` option is a conscious per-tool decision.

### Immediate option registration

`--bash-completion` is added to the `args_immediate_options` default list in `args.sh`, alongside `--help` and `--version`:

```bash
declare -a args_immediate_options=("-h" "--help" "-v" "--version" "--bash-completion")
```

This means the handler `args::option::completion` is dispatched automatically when `--bash-completion` is present in parsed options — no `args::immediate` call needed in tools or in `args-completion.sh`.

### Handler dispatch

The `args.sh` immediate option dispatch uses `${option##*-}` to derive the handler name. For `--bash-completion`, this yields `completion`, so the handler is `args::option::completion`.

## Generated completion script

### Standard completion function

```bash
_complete_<name>() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=()

  # If typing an option, suggest options
  if [[ "$cur" == -* ]]; then
    COMPREPLY=($(compgen -W "<all option names>" -- "$cur"))
    return
  fi

  # If commands are defined and none typed yet, suggest commands
  local has_command=0
  for ((i=1; i<COMP_CWORD; i++)); do
    case "${COMP_WORDS[i]}" in
      <command1>|<command2>|...) has_command=1; break ;;
    esac
  done

  if [[ $has_command -eq 0 ]]; then
    COMPREPLY=($(compgen -W "<all commands>" -- "$cur"))
    # Also offer file completion if no command matches
    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
      COMPREPLY=($(compgen -f -- "$cur"))
    fi
    return
  fi

  # Default: file completion
  COMPREPLY=($(compgen -f -- "$cur"))
}

complete -o bashdefault -o default -F _complete_<name> <name>
```

Key behaviors:

- **`-o bashdefault -o default`** — falls back to default completion (files, directories) when the function produces no matches.
- **Options** — all registered option names (both short and long forms) are suggested when the current word starts with `-`.
- **Commands** — suggested when no command has been typed yet. Command aliases (e.g., `t` for `test`) are included.
- **Files** — default fallback after a command is present, or when the tool has no commands.

### Option argument awareness

When the previous word is an option that takes a required argument, the completion function should offer file completion (not other options). For options with optional arguments (`--color[=when]`), both options and files are valid.

The generated function includes a `case` on `$prev` for options that take arguments:

```bash
  # Handle options that expect an argument
  case "$prev" in
    --env|-e) COMPREPLY=($(compgen -f -- "$cur")); return ;;
    --timeout|-t) COMPREPLY=($(compgen -f -- "$cur")); return ;;
  esac
```

### fzf completion function

When fzf's completion system is loaded (user has sourced fzf's `completion.bash`), defining `_fzf_complete_<name>` enables fuzzy completion via fzf's trigger (default: `**<Tab>`).

```bash
_fzf_complete_<name>() {
  _fzf_complete --height=40% --reverse -- "$@" < <(
    printf '%s\n' <all options> <all commands>
  )
}
```

This coexists with standard completion:

- **Regular Tab** → standard `complete -F` function (always works)
- **`**<Tab>`** → fzf fuzzy picker (only when fzf completion is loaded)

No runtime fzf detection is needed. If fzf's system is not loaded, `_fzf_complete_<name>` is never called — it just sits harmlessly as a defined function.

### Sanitized function names

Program names may contain characters invalid in bash function names (e.g., `.`, `-`). The function name is sanitized: `_complete_${name//[^a-zA-Z0-9_]/_}`. The `complete -F` registration uses the original program name.

## Bootstrap integration

### Registration mechanism

The bootstrap file (`bootstrap.sh`) wraps `args::parse` to auto-register completions after every parse. When `args-completion.sh` is sourced after `args.sh`, it saves a reference to the original `args::parse` and installs a wrapper:

```bash
# args-completion.sh installs the wrapper on source:
eval "$(declare -f args::parse | sed '1s/args::parse/__args_parse_impl/')"

args::parse() {
  __args_parse_impl "$@"
  args::completion::register
}
```

This is transparent to tool authors — no extra code needed in individual tools. The wrapper calls `args::completion::register` after every successful parse. Since `register` checks timestamps and exits early when the completion file is current, the overhead is negligible (a single `stat` comparison).

Edge cases:

- **`--help`, `--version`, `--bash-completion`** — these call `exit` inside `__args_parse_impl`. The wrapper's `register` call is never reached. Correct behavior: no registration needed during these exits.
- **Parse errors** — `args::parse` calls `exit 1`. Same as above: wrapper is not reached.
- **First run** — completion file does not exist. `register` creates it.
- **Tool updated** — tool script is newer than completion file. `register` regenerates it.
- **Unwritable directory** — `register` fails silently.

### Bootstrap `bootstrap.sh` changes

```bash
# Add to bootstrap.sh after existing module sources:
. ~/.local/share/libs/scripts/args-completion.sh
```

No other changes needed. The wrapping happens automatically when `args-completion.sh` is sourced.

### Tools that don't use the bootstrap

Tools that source `args-completion.sh` directly get the same wrapping behavior. Tools that don't source it at all are unaffected.

### Manual registration

For users who prefer explicit control:

```bash
# Option A: eval into current shell
eval "$(my-tool --bash-completion)"

# Option B: write to lazy-load directory
my-tool --bash-completion > ~/.local/share/bash-completion/completions/my-tool

# Option C: write to legacy eager-load directory
my-tool --bash-completion > /etc/bash_completion.d/my-tool
```

## Testing

### Automated tests: `tests/test-args-completion.sh`

1. Source `args.sh` and `args-completion.sh`.
2. Register a set of options and commands.
3. Call `args::completion::generate` and capture output.
4. Verify the output contains the expected function name.
5. Verify all registered options appear in the completion word list.
6. Verify all registered commands appear in the completion word list.
7. Verify `complete -F` registration line is present.
8. Verify fzf function is defined.
9. `eval` the generated script and verify the completion function is callable.

### Manual test: `tests/manual/test-args-completion.sh`

1. Define a sample program with options and commands.
2. Generate and print the completion script.
3. Instructions for the user to eval and test Tab completion interactively.

### Integration test

1. Source the generated completion in a subshell.
2. Simulate `COMP_WORDS` and `COMP_CWORD` and call the completion function.
3. Verify `COMPREPLY` contains expected values for various scenarios:
   - Partial option: `--ou` → `--output`
   - Option prefix: `-` → all short options
   - Command: empty word → all commands
   - After command: file completion

## File changes summary

| File | Change |
|------|--------|
| `args.sh` | Add `"--bash-completion"` to `args_immediate_options` default list. |
| `args-completion.sh` | **New module.** |
| `tests/test-args-completion.sh` | **New test file.** |
| `tests/manual/test-args-completion.sh` | **New manual test.** |
| `tests/run.sh` | Add `test-args-completion.sh` to the runner. |
| `ARCHITECTURE.md` | Add `args-completion.sh` to project layout and dependency graph. |
| `AGENTS.md` | Add `args-completion.sh` to architecture reference. |
| `.windsurfrules` / `.clinerules` / `.cursorrules` | Sync with AGENTS.md. |
| `wiki/args‐completion.sh.md` | **New wiki page.** |
| `wiki/Home.md` | Add link to args-completion.sh wiki page. |
| `llms.txt` | Add args-completion.sh API reference. |
| `README.md` | Add completion mention to features list. Remove "Planned features" from ARCHITECTURE.md. |

## Implementation order

1. **`args-completion.sh`** — core module with `generate`, `register`, handler, and `args::parse` wrapper.
2. **`tests/test-args-completion.sh`** — automated tests.
3. **`tests/manual/test-args-completion.sh`** — manual test.
4. **Update `tests/run.sh`** — add new test.
5. **Docs** — ARCHITECTURE.md, AGENTS.md, rule files, wiki, llms.txt, README.md.

## Future: `args-fzf.sh`

A separate module for runtime fzf integration inside scripts (unrelated to Tab completion):

- **Interactive picker** — prompt the user to select from a list when arguments are missing.
- **File/directory browser** — embedded fuzzy file selection within a tool's flow.
- **Multi-select** — choose multiple items from a list.
- **Preview panes** — show context for each choice.

This is tracked in `completion-feature.md` and will be implemented separately.
