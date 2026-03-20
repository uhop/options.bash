# options.bash

A pure Bash library for building CLI utilities with rich terminal output and option parsing. Bash 4.0+, zero external dependencies beyond coreutils and `getopt`.

The JavaScript sibling project is [console-toolkit](https://github.com/uhop/console-toolkit) — it mirrors the ansi, box, and string concepts in ESM.

## Features

- **Rich terminal output** — colors, styles, cursor control, hyperlinks, true color.
- **Option parsing** — wraps `getopt` with a clean API for options, commands, and arguments.
- **Auto-generated help** — colored help screens built from your option definitions.
- **Box layout engine** — normalize, pad, align, and stack multi-line text blocks.
- **Terminal-aware output** — ANSI codes are automatically stripped when output is piped.
- **Zero dependencies** — pure Bash, no Python, no Node, no compiled binaries.
- **Self-contained modules** — include guards, auto-dependency resolution, independently sourceable.

## Quick start

Clone the full repo:

```bash
git clone git@github.com:uhop/options.bash.git
```

Or add as a sparse worktree (only `.sh` files — ideal for consuming in your projects):

```bash
mkdir -p ~/.local/share/libs
cd ~/.local/share/libs
git clone --filter=blob:none --sparse git@github.com:uhop/options.bash scripts
cd scripts
git sparse-checkout set --no-cone '/*.sh' '/README.md'
```

Source the modules you need in your script:

```bash
#!/usr/bin/env bash
set -euo pipefail

LIB_DIR="/path/to/options.bash"
source "${LIB_DIR}/args.sh"
source "${LIB_DIR}/args-help.sh"
source "${LIB_DIR}/args-version.sh"

args::program "my-tool" "1.0.0" "Does useful things"
args::option "-v, --version" "Show version"
args::option "-h, --help" "Show help"
args::option "--output, -o" "Output file" "file"
args::option "build" "Build the project"
args::option "test" "Run tests"

args::parse "$@"

# Use parsed results
case "$args_command" in
  build) echo "Building..." ;;
  test)  echo "Testing..." ;;
esac

if [[ -v args_options["--output"] ]]; then
  echo "Output: ${args_options["--output"]}"
fi
```

Run it:

```
$ my-tool --help
my-tool 1.0.0 Does useful things

Usage:
  my-tool [options] command [command arguments]

Options:
  -v, --version       Show version
  -h, --help          Show help
  -o, --output=<file> Output file

Commands:
  build               Build the project
  test                Run tests
```

## Bootstrap pattern

A common pattern is a bootstrap file that auto-updates and sources the core modules. Create `~/.local/libs/main.sh`:

```bash
# include options.bash
command -v git &> /dev/null && git -C ~/.local/share/libs/scripts pull > /dev/null || true

. ~/.local/share/libs/scripts/ansi.sh
. ~/.local/share/libs/scripts/args.sh
. ~/.local/share/libs/scripts/args-version.sh
. ~/.local/share/libs/scripts/args-help.sh

# echo the first argument and run
echoRun() {
  echo -e "\033[36m$@\033[0m"
  eval "$@"
}

echoRunBold() {
  echo -e "\033[1;36m$@\033[0m"
  eval "$@"
}
```

Then your scripts just source it and go:

```bash
#!/usr/bin/env bash
set -euCo pipefail
shopt -s expand_aliases

. ~/.local/libs/main.sh

script_name=$(basename "$0")
args::program "$script_name" "1.0" "Update software with available package managers"

args::option "-c, --clean" "Run the cleanup script ${BOLD}cln${RESET_ALL} after updating"
args::option "-y, --yes" "Assume \"yes\" to all prompts"
args::option "-v, --version" "Show version"
args::option "-h, --help" "Show help"

args::parse "$@"

WARN="${BOLD}${BRIGHT_WHITE}${BG_BLUE}"
echoRunBold sudo apt update
echoRunBold sudo apt upgrade

if [[ -v args_options["-c"] ]]; then
  ansi::out "\n${BOLD}${FG_CYAN}Clean up...${RESET_ALL}\n"
  cln
fi
```

## Project structure

```
options.bash/
├── ansi.sh           # ANSI escape codes: colors, styles, cursor, screen control
├── ansi-tput.sh      # Alternative ANSI implementation using tput (bash 4.3+)
├── ansi-utils.sh     # Shared ANSI utilities: color math, strip, make, output helpers
├── args.sh           # CLI option/command parsing (wraps getopt)
├── args-help.sh      # Auto-generated colored help screen from args definitions
├── args-version.sh   # --version / -v handler
├── box.sh            # Text box layout engine: normalize, pad, align, stack
├── string.sh         # String utilities: pad, clean, length, output helpers
├── test.sh           # Built-in test harness: assertions, colored output, runner
├── tests/            # Automated tests (test-string.sh, test-ansi.sh, etc.)
├── tests/manual/     # Manual test scripts (visual inspection)
└── wiki/             # GitHub wiki documentation (submodule)
```

## Docs

The full documentation is in the [wiki](https://github.com/uhop/options.bash/wiki):

- [ansi.sh](https://github.com/uhop/options.bash/wiki/ansi.sh) — ANSI escape codes (primary module)
- [ansi-tput.sh](https://github.com/uhop/options.bash/wiki/ansi‐tput.sh) — tput-based alternative
- [ansi-utils.sh](https://github.com/uhop/options.bash/wiki/ansi‐utils.sh) — shared ANSI utilities
- [args.sh](https://github.com/uhop/options.bash/wiki/args.sh) — option and command parsing
- [args-help.sh](https://github.com/uhop/options.bash/wiki/args‐help.sh) — auto-generated help screen
- [args-version.sh](https://github.com/uhop/options.bash/wiki/args‐version.sh) — version handler
- [box.sh](https://github.com/uhop/options.bash/wiki/box.sh) — text box layout engine
- [string.sh](https://github.com/uhop/options.bash/wiki/string.sh) — string utilities
- [test.sh](https://github.com/uhop/options.bash/wiki/test.sh) — built-in test harness

For AI assistants: see [llms.txt](https://github.com/uhop/options.bash/blob/main/llms.txt) for LLM-optimized documentation.

## Module layers

```
┌─────────────┐  ┌───────────────┐
│  args-help  │  │ args-version  │    ← high-level: help/version handlers
├─────────────┤  └───────┬───────┘
│   args.sh   │          │            ← option/command parsing
├─────┬───────┘          │
│     │                  │
│  ┌──┴──────┐  ┌───────┘
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

`ansi.sh` and `ansi-tput.sh` are **mutually exclusive** — source only one.

## Option parsing

Define options and commands with `args::option`, then call `args::parse "$@"`:

```bash
source "${LIB_DIR}/args.sh"

args::program "deploy" "2.0.0" "Deploy to servers"

# Flags
args::option "-n, --dry-run" "Preview without executing"

# Options with arguments
args::option "--env, -e" "Target environment" "name"

# Options with optional arguments
args::option "--color" "Color output" "when" optional

# Commands
args::option "start" "Start the deployment"
args::option "status" "Check deployment status"

args::parse "$@"

# Results:
#   args_options   — associative array of parsed options
#   args_command   — matched command name
#   args_cleaned   — remaining positional arguments
```

See [args.sh wiki](https://github.com/uhop/options.bash/wiki/args.sh) for the full API including error hooks and configuration globals.

## Colored output

```bash
source "${LIB_DIR}/ansi.sh"

# Use predefined globals
ansi::out "${RED}Error:${RESET_ALL} something went wrong"
ansi::out "${BOLD}${GREEN}✓${RESET_ALL} All checks passed"

# Compose styles
header="$(ansi::make bold underline cyan)"
ansi::out "${header}Section Title${RESET_ALL}"

# True color
ansi::out "$(ansi::fg_true 255 165 0)Orange text${RESET_ALL}"
```

Output is terminal-aware — ANSI codes are automatically stripped when piped to a file.

## Box layout

```bash
source "${LIB_DIR}/box.sh"

# Create and format a box
lines=$(box::make_lines "Hello" "World" "!")
box=$(box::exec "$lines" normalize center pad_lr 2 2 pad_tb 1 1)
box::out "$box"

# Stack boxes
left=$(box::exec "$(box::make "A" "B")" pad_lr 1 1)
right=$(box::exec "$(box::make "1" "2")" pad_lr 1 1)
box::out "$(box::stack_lr "$left" "$right")"
```

See [box.sh wiki](https://github.com/uhop/options.bash/wiki/box.sh) for the full command pipeline reference.

## Requirements

- **Bash 4.0+** for most modules.
- **Bash 4.3+** for `ansi-tput.sh` only.
- **`getopt`** (enhanced version) for `args.sh`.
- **coreutils** (`sed`, `dirname`, `realpath`, `basename`).

On macOS, the system Bash is 3.x. Install a modern version:

```bash
brew install bash
```

## License

BSD 3-Clause. See [LICENSE](./LICENSE).
