# fzf tab completion — research and decision

## Problem

We initially generated an `_fzf_complete_<name>` function alongside the standard `_complete_<name>` function in completion scripts. This did not work.

## Findings

### bash `complete` only accepts one function per command

```bash
complete -F _complete_my_tool my-tool     # standard Tab
complete -F _fzf_complete_my_tool my-tool # fzf — replaces the above
```

Only the last `complete` registration takes effect. You cannot register both.

### fzf's `**<Tab>` trigger requires `complete` registration in bash

From the [fzf docs](https://github.com/junegunn/fzf?tab=readme-ov-file#custom-fuzzy-completion):

> "zsh will automatically pick up the function using the naming convention but in bash you have to manually associate the function with the command using the `complete` command."

So `_fzf_complete_my_tool` must be registered with `complete -F` to be invoked — even for the `**<Tab>` trigger. But registering it replaces the standard completion.

### fzf trigger is 3 keystrokes

The default fzf completion trigger is `**<Tab>` (two asterisks + Tab). This is configurable via `FZF_COMPLETION_TRIGGER` but always requires a prefix before Tab. There is no single-keystroke alternative.

### If registered via `complete`, fzf handles ALL Tab presses

Registering `_fzf_complete_my_tool` with `complete` means every Tab press goes through fzf's `_fzf_complete` helper. This:
- Requires fzf to be installed and its shell integration loaded
- Breaks completion entirely if fzf is not available
- Changes the UX for all Tab presses, not just `**<Tab>`

## Decision

**Ditch fzf tab completion.** The two approaches are mutually exclusive in bash, the trigger is unintuitive, and we cannot assume fzf is installed.

Our standard `complete -F` completion works everywhere with zero dependencies.

## Alternatives considered

1. **Wrapper function** that checks for fzf and dispatches — adds complexity, still can't offer both standard and fzf simultaneously for the same Tab press.
2. **Generate two separate scripts** (standard and fzf) — user picks one. Over-engineered for the benefit.
3. **Runtime fzf menus** (`args-fzf.sh`) — a future module for in-script interactive selection, unrelated to Tab completion. Still viable.

## Future

A separate `args-fzf.sh` module could provide runtime interactive menus (pickers, multi-select, preview panes) inside scripts. This is orthogonal to shell Tab completion and does not have the `complete` registration conflict.
