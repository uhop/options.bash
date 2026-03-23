# AGENTS.md — options.bash

> `options.bash` is a Bash library for building CLI utilities with rich terminal output and option parsing. It requires Bash 4.0+ and has zero external dependencies beyond coreutils and `getopt`.

The JavaScript sibling project is [console-toolkit](https://github.com/uhop/console-toolkit) — it mirrors the ansi, box, and string concepts in ESM.

For project structure and module dependencies see [ARCHITECTURE.md](./ARCHITECTURE.md).
For detailed module docs see the [wiki](https://github.com/uhop/options.bash/wiki).

## Setup

This project uses a git submodule for the wiki:

```bash
git clone --recursive git@github.com:uhop/options.bash.git
cd options.bash
```

To use in your project, clone as a sparse worktree:

```bash
mkdir -p ~/.local/share/libs
cd ~/.local/share/libs
git clone --filter=blob:none --sparse git@github.com:uhop/options.bash scripts
cd scripts
git sparse-checkout set --no-cone '/*.sh' '/README.md'
```

Then source from your scripts:

```bash
LIB_DIR="$HOME/.local/share/libs/scripts"
source "${LIB_DIR}/args.sh"
```

A common pattern is a bootstrap file (e.g., `~/.local/libs/bootstrap.sh`) that auto-updates and sources the core modules:

```bash
# include options.bash
command -v git &> /dev/null && git -C ~/.local/share/libs/scripts pull > /dev/null || true

. ~/.local/share/libs/scripts/ansi.sh
. ~/.local/share/libs/scripts/args.sh
. ~/.local/share/libs/scripts/args-version.sh
. ~/.local/share/libs/scripts/args-help.sh
. ~/.local/share/libs/scripts/args-completion.sh

# echo the first argument and run
echoRun() {
  ansi::out "${CYAN}$@${RESET_ALL}"
  eval "$@"
}

echoRunBold() {
  ansi::out "${BOLD}${CYAN}$@${RESET_ALL}"
  eval "$@"
}
```

Scripts then source it with `. ~/.local/libs/bootstrap.sh` and immediately have access to all library functions, color globals, and helper utilities.

## Project structure

```
options.bash/
├── ansi.sh           # ANSI escape codes: colors, styles, cursor, screen control
├── ansi-tput.sh      # Alternative ANSI implementation using tput (bash 4.3+)
├── ansi-utils.sh     # Shared ANSI utilities: color math, strip, make, output helpers
├── args.sh           # CLI option/command parsing (wraps getopt)
├── args-help.sh      # Auto-generated colored help screen from args definitions
├── args-version.sh   # --version / -v handler
├── args-completion.sh # Bash completion script generation
├── box.sh            # Text box layout engine: normalize, pad, align, stack
├── string.sh         # String utilities: pad, clean, length, output helpers
├── test.sh           # Built-in test harness: assertions, colored output, runner
├── tests/            # Automated tests (test-string.sh, test-ansi.sh, etc.)
├── tests/manual/     # Manual test scripts (visual inspection)
├── examples/         # Code samples (bootstrap, simple tool, cleanup utility)
├── wiki/             # GitHub wiki documentation (submodule)
├── LICENSE           # BSD 3-Clause
└── README.md
```

## Code style

- **Pure Bash** — no Python, no Node, no compiled binaries.
- **Bash 4.0+** minimum for most modules; `ansi-tput.sh` requires **Bash 4.3+**.
- **`set -euo pipefail`** at the top of every module.
- **Namespace convention**: functions use `module::submodule::name` style (e.g., `ansi::fg`, `box::exec`, `string::pad`).
- **Global variables** use `module_name` prefix (e.g., `ansi_style_colors`, `args_program_name`).
- **Include guards**: every module checks for a sentinel function at the top and returns early if already loaded.
- **Auto-dependency loading**: modules resolve their own dependencies relative to `BASH_SOURCE`.
- **No simple command name pollution** by default can be disabled by setting `ANSI_NO_SIMPLE_COMMAND_NAMES=1` before sourcing.

## Architecture

### Module layers

```
┌─────────────┐  ┌───────────────┐  ┌─────────────────┐
│  args-help  │  │ args-version  │  │ args-completion │  ← high-level handlers
├─────────────┤  └───────┬───────┘  └─────────────────┘
│   args.sh   │          │                               ← option/command parsing
├─────┬───────┘          │
│     │                  │
│  ┌──┴──────┐  ┌────────┘
│  │ box.sh  │  │
│  ├─────────┤  │
│  │ ansi.sh │  │                     ← terminal output (pick one)
│  │   —or—  │  │
│  │ ansi-   │  │
│  │ tput.sh │  │
│  ├─────────┤  │
│  │ ansi-   │◄─┘                     ← shared ANSI utilities
│  │ utils.sh│
│  ├─────────┤
│  │string.sh│                        ← string primitives
│  └─────────┘
```

- **`string.sh`** is the lowest-level module. It has no dependencies and is loaded by `box.sh`.
- **`ansi-utils.sh`** provides color math, escape-code stripping, and terminal-aware output. Loaded by both `ansi.sh` and `ansi-tput.sh`.
- **`ansi.sh`** and **`ansi-tput.sh`** are **alternative** ANSI implementations. Source one, never both. They export the same core API (`ansi::fg`, `ansi::bg`, `ansi::get`, `ansi::make`, `ansi::alias_simple_command_names`).
- **`box.sh`** is a text layout engine operating on multi-line strings. Depends on `string.sh`.
- **`args.sh`** handles option/command parsing via `getopt`. It is standalone.
- **`args-help.sh`** generates a colorized help screen. It sources `ansi.sh`, `string.sh`, and `box.sh`.
- **`args-version.sh`** prints version and exits. It uses globals set by `args::program`.
- **`args-completion.sh`** generates bash completion scripts from `args.sh` registration data. It registers an `args::on_options` hook for auto-registration.

### How option parsing works

1. Call `args::program` to set program name, version, description.
2. Call `args::option` for each option/command with names, description, argument spec.
3. Call `args::parse "$@"` to invoke `getopt` and populate `args_options` (associative array) and `args_command`.
4. Registered `args::on_options` hooks run.
5. Immediate options (`-h`, `-v`, `--bash-completion`) trigger handler functions (`args::option::help`, `args::option::version`, `args::option::completion`) and exit.
6. Registered `args::on_parse` hooks run after successful completion.
7. Remaining arguments are in `args_cleaned` (array).

### How ANSI output works

1. Source `ansi.sh` (or `ansi-tput.sh`) to populate shell variables with escape sequences.
2. By default, simple command names (`RED`, `BOLD`, `RESET_ALL`, etc.) are defined as globals.
3. Use `ansi::out` / `ansi::err` for terminal-aware output that auto-strips escape codes when piped.
4. Use `ansi::make` to compose multiple styles into a single escape sequence.

### How box layout works

1. Create a multi-line string with `box::make_lines` or `box::make`.
2. Pipe through `box::exec` with a chain of commands: `normalize`, `pad_lr`, `pad_tb`, `align_lr`, `align_tb`, `set_pad`, `clean`, `extract`.
3. Stack boxes with `box::stack_lr` or `box::stack_tb`.
4. Output with `box::out` (terminal-aware, strips ANSI when piped).

## Using in a script

```bash
#!/usr/bin/env bash
set -euo pipefail

# Resolve the library location
LIB_DIR="/path/to/options.bash"

# Source what you need
source "${LIB_DIR}/args.sh"
source "${LIB_DIR}/args-help.sh"
source "${LIB_DIR}/args-version.sh"

# Define your CLI
args::program "my-tool" "1.0.0" "Does useful things"
args::option "-v, --version" "Show version"
args::option "-h, --help" "Show help"
args::option "--output, -o" "Output file" "file"
args::option "build" "Build the project"
args::option "test" "Run tests"

# Parse and use
args::parse "$@"
```

## Key conventions

- Do not add external dependencies — the library is intentionally self-contained.
- Every module is independently sourceable (dependencies are auto-resolved).
- `ansi.sh` and `ansi-tput.sh` are mutually exclusive — source only one.
- Use `ansi::out` / `box::out` / `string::out` instead of raw `echo` for terminal-safe output.
- Error output functions (`ansi::err`, `box::err`, `string::err`) write to stderr and return 1.
- Wiki documentation lives in the `wiki/` submodule.
- Automated tests live in `tests/` — run with `bash tests/run.sh`.
- Manual tests (visual inspection) live in `tests/manual/`.
