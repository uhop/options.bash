# Architecture

`options.bash` is a pure Bash library for building CLI utilities. It has **zero external dependencies** beyond coreutils and `getopt`. Every module is independently sourceable — dependencies are auto-resolved relative to `BASH_SOURCE`.

## Project layout

```
ansi.sh               # ANSI escape codes via raw escape sequences (bash 4.0+)
ansi-tput.sh          # Alternative ANSI implementation via tput (bash 4.3+)
ansi-utils.sh         # Shared ANSI utilities: color math, strip, make, output helpers
ansi-semantic.sh      # Semantic color globals: ERROR, WARN, INFO, OK
args.sh               # CLI option/command parsing (wraps getopt)
args-help.sh          # Auto-generated colored help screen from args definitions
args-version.sh       # --version / -v handler (prints name + version, exits)
args-completion.sh    # Bash completion script generation from args definitions
box.sh                # Text box layout engine: normalize, pad, align, stack
string.sh             # String utilities: pad, clean, length, output helpers
tests/manual/         # Manual test scripts (visual inspection)
├── test-ansi.sh      # Test ansi.sh colors and styles
├── test-ansi-semantic.sh # Test semantic color globals
├── test-ansi-tput.sh # Test ansi-tput.sh colors and styles
├── test-args.sh      # Test option/command parsing with help screen
├── test-args-completion.sh # Test completion generation
├── test-box.sh       # Test box layout operations
├── test-box-stack.sh # Test box stacking (horizontal and vertical)
└── tput.sh           # Low-level tput batch query helper
examples/             # Code samples (bootstrap, simple tool, cleanup utility, rich output)
wiki/                 # GitHub wiki documentation (git submodule)
```

## Module dependency graph

```
string.sh             ← no dependencies (lowest level)
ansi-utils.sh         ← no dependencies (shared helpers for ansi.sh / ansi-tput.sh)
    ↑
ansi.sh               ← loads ansi-utils.sh (raw escape sequences)
ansi-tput.sh          ← loads ansi-utils.sh (tput-based, alternative to ansi.sh)
    ↑
ansi-semantic.sh      ← loads ansi.sh (semantic color globals)
    ↑
box.sh                ← loads string.sh
    ↑
args.sh               ← standalone (no library dependencies)
    ↑
args-help.sh          ← loads ansi.sh, string.sh, box.sh
args-version.sh       ← standalone (uses globals from args.sh)
args-completion.sh    ← loads args.sh (registers args::on_options hook)
```

### Source-time dependencies (what gets loaded when you source a module)

| Module | Auto-loads |
|---|---|
| `string.sh` | _(nothing)_ |
| `ansi-utils.sh` | _(nothing)_ |
| `ansi.sh` | `ansi-utils.sh` |
| `ansi-tput.sh` | `ansi-utils.sh` |
| `ansi-semantic.sh` | `ansi.sh` |
| `box.sh` | `string.sh` |
| `args.sh` | _(nothing)_ |
| `args-help.sh` | `ansi.sh`, `string.sh`, `box.sh` |
| `args-version.sh` | _(nothing, uses `args_program_*` globals)_ |
| `args-completion.sh` | `args.sh` |

## Core concepts

### Include guards

Every module checks for a sentinel function at the top and returns early if already loaded:

```bash
if type ansi::fg > /dev/null 2>&1; then return; fi
```

This means modules can be sourced multiple times safely, and dependency loading is idempotent.

### Namespace convention

- **Functions**: `module::submodule::name` — e.g., `ansi::fg`, `ansi::cursor::pos`, `box::exec`, `string::pad`.
- **Global variables**: `module_prefix` — e.g., `ansi_style_colors`, `args_program_name`, `args_options`.
- **Internal functions**: prefixed with `_` and unset after use (e.g., `_load_dependencies`).

### Terminal-aware output

Output functions detect whether stdout/stderr is a terminal:
- **Terminal**: output includes ANSI escape codes.
- **Pipe/file**: escape codes are automatically stripped.

Stdout functions (`::out`): check `[[ -t 1 || -z "$TERM" ]]`. Stderr functions (`::err`, `::warn`): check `[[ -t 2 || -z "$TERM" ]]`. `::err` returns 1 (signals failure); `::warn` returns 0 (safe under `set -e`).

### ANSI implementations

`ansi.sh` and `ansi-tput.sh` are **mutually exclusive alternatives**. They export the same core API:

| Function | Purpose |
|---|---|
| `ansi::fg N` | Set foreground color by number |
| `ansi::bg N` | Set background color by number |
| `ansi::get NAME` | Get escape sequence by name |
| `ansi::make STYLE...` | Compose multiple styles |
| `ansi::alias_simple_command_names` | Define short global names (`RED`, `BOLD`, etc.) |

`ansi.sh` uses raw `\e[...m` sequences and works on bash 4.0+. `ansi-tput.sh` queries the `tput` database and works on bash 4.3+. Usually `ansi.sh` is the right choice.

### Simple command names

By default, sourcing `ansi.sh` or `ansi-tput.sh` defines uppercase globals:
- **Colors**: `RED`, `GREEN`, `BLUE`, `BRIGHT_RED`, etc.
- **Styles**: `BOLD`, `DIM`, `ITALIC`, `UNDERLINE`, `RESET_ALL`, etc.
- **Prefixed forms**: `FG_RED`, `BG_GREEN`, `TEXT_BOLD`, etc.

Set `ANSI_NO_SIMPLE_COMMAND_NAMES=1` before sourcing to suppress these.

### Option parsing flow

1. `args::program NAME VERSION DESCRIPTION [URL]` — set program metadata.
2. `args::option "NAMES" "DESCRIPTION" [ARG_NAME] [OPTIONAL]` — register options and commands.
   - Names: comma/space-separated (e.g., `"-v, --version"`).
   - Options start with `-`; commands are bare words.
   - `ARG_NAME`: if non-empty, the option takes an argument.
   - `OPTIONAL`: if non-empty, the argument is optional.
3. `args::parse "$@"` — parse via `getopt`, populate:
   - `args_options` — associative array of parsed options.
   - `args_command` — the matched command (if any, or the default command).
   - `args_cleaned` — array of remaining positional arguments.
4. Registered `args::on_options` hooks run.
5. Immediate options (`-h`, `-v`, `--bash-completion` by default) trigger `args::option::help` / `args::option::version` / `args::option::completion` and exit.
6. If no command matched and `args_program_default_command` is set, it is applied.
7. Registered `args::on_parse` hooks run after successful completion.

### Box layout engine

`box::exec` processes a multi-line string through a pipeline of commands:

| Command | Alias | Arguments | Effect |
|---|---|---|---|
| `normalize` | `n` | `ALIGN` | Normalize lines to equal width |
| `pad_lr` | `ph` | `LEFT RIGHT` | Add horizontal padding |
| `pad_tb` | `pv` | `TOP BOTTOM` | Add vertical padding |
| `align_lr` | `ah` | `ALIGN WIDTH` | Align within a horizontal space |
| `align_tb` | `av` | `ALIGN HEIGHT` | Align within a vertical space |
| `set_pad` | `sp` | `CHAR` | Change the pad character |
| `clean` | `c` | _(none)_ | Strip ANSI codes from all lines |
| `extract` | `e` | `FROM COUNT` | Extract a range of lines |

Alignment values: `left`/`l`, `right`/`r`, `center`/`c` (horizontal); `top`/`t`, `bottom`/`b`, `center`/`c` (vertical).

Boxes can be composed with `box::stack_lr` (side-by-side, must have equal height) and `box::stack_tb` (vertical, must have equal width).

## Bootstrap pattern

A common deployment pattern is a bootstrap file (e.g., `~/.local/libs/bootstrap.sh`) that:
1. Auto-updates the library from git on every invocation.
2. Sources the core modules (`ansi.sh`, `args.sh`, `args-version.sh`, `args-help.sh`).
3. Defines helper functions (`echoRun`, `echoRunBold`) for colored command execution.
4. Sets up environment aliases (e.g., `doas` → `sudo`).

Scripts then source this bootstrap with `. ~/.local/libs/bootstrap.sh` and immediately have access to all library functions, color globals (`RED`, `BOLD`, `RESET_ALL`, etc.), and helper utilities. This pattern is used by real-world CLI tools like `upd` (system updater), `cln` (cleanup), `arx` (archive viewer/extractor), `jot` (encrypted S3 notes), and `goup` (recursive directory command runner).

## Testing

### Automated tests

The project includes a built-in test harness (`test.sh`) and automated tests in `tests/`:

```bash
bash tests/run.sh                     # Run all automated tests
bash tests/test-string.sh             # string.sh tests
bash tests/test-ansi.sh               # ansi.sh + ansi-utils.sh tests
bash tests/test-ansi-semantic.sh      # ansi-semantic.sh tests
bash tests/test-box.sh                # box.sh tests
bash tests/test-args.sh               # args.sh tests
bash tests/test-args-completion.sh    # args-completion.sh tests
```

The test harness (`test.sh`) follows the same conventions as library modules: include guard, `set -euo pipefail`, `test::` namespace, auto-loads `ansi.sh` for colored output. It provides assertions: `test::equal`, `test::not_equal`, `test::match`, `test::contains`, `test::ok`, `test::fail_`. Each test file calls `test::done` at the end to print a summary and exit with 0 (pass) or 1 (fail).

### Manual tests

Visual inspection tests live in `tests/manual/`:

```bash
bash tests/manual/test-ansi.sh        # ANSI colors and styles
bash tests/manual/test-ansi-semantic.sh  # Semantic color globals
bash tests/manual/test-ansi-tput.sh   # tput-based colors and styles
bash tests/manual/test-args.sh -h     # Help screen
bash tests/manual/test-args.sh -v     # Version
bash tests/manual/test-args.sh --required=foo cmd  # Option parsing
bash tests/manual/test-box.sh         # Box layout
bash tests/manual/test-box-stack.sh   # Box stacking
bash tests/manual/test-args-completion.sh --bash-completion  # Completion script
```
