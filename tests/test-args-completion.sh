#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
source "$script_dir/../test.sh"
source "$test_lib_dir/args-completion.sh"

echo "args-completion.sh"

# --- Setup: register a sample program ---

args::program "my-tool" "1.0.0" "A test tool"

args::option "-v, --version" "Show version"
args::option "-h, --help" "Show help"
args::option "--bash-completion" "Output bash completion script"
args::option "--output, -o" "Output file" "file"
args::option "--timeout, -t" "Timeout value" "seconds"
args::option "--color" "Color mode" "when" "optional"

args::option "build, b" "Build the project"
args::option "test, t" "Run tests"
args::option "deploy" "Deploy"

# --- Generate and capture ---

output="$(args::completion::generate)"

# --- Test: function name ---

test::contains "$output" "_complete_my_tool()" "generate: function name"

# --- Test: complete registration ---

test::contains "$output" "complete -o bashdefault -o default -F _complete_my_tool my-tool" "generate: complete registration"

# --- Test: options in word list ---

test::contains "$output" "-v" "generate: short option -v"
test::contains "$output" "--version" "generate: long option --version"
test::contains "$output" "-h" "generate: short option -h"
test::contains "$output" "--help" "generate: long option --help"
test::contains "$output" "--output" "generate: long option --output"
test::contains "$output" "-o" "generate: short option -o"
test::contains "$output" "--bash-completion" "generate: --bash-completion option"

# --- Test: commands in word list ---

test::contains "$output" "build" "generate: command build"
test::contains "$output" "test" "generate: command test"
test::contains "$output" "deploy" "generate: command deploy"
test::contains "$output" "b" "generate: command alias b"
test::contains "$output" "t" "generate: command alias t"

# --- Test: command detection case ---

test::contains "$output" "build|b|test|t|deploy" "generate: command case pattern"

# --- Test: arg-taking option case ---

test::contains "$output" '--output|-o)' "generate: arg option --output case"
test::contains "$output" '--timeout|-t)' "generate: arg option --timeout case"

# --- Test: signature ---

test::contains "$output" "# options.bash-completion v${args_completion_format_version}" "generate: format version signature"

# --- Test: generated script is valid bash ---

eval "$output"
test::equal "$(type -t _complete_my_tool)" "function" "generate: function is callable"

# --- Test: completion function produces results ---

COMP_WORDS=("my-tool" "--o")
COMP_CWORD=1
COMPREPLY=()
_complete_my_tool
test::contains "${COMPREPLY[*]}" "--output" "completion: partial option --o matches --output"

COMP_WORDS=("my-tool" "-")
COMP_CWORD=1
COMPREPLY=()
_complete_my_tool
test::contains "${COMPREPLY[*]}" "-v" "completion: dash prefix lists -v"
test::contains "${COMPREPLY[*]}" "-h" "completion: dash prefix lists -h"
test::contains "${COMPREPLY[*]}" "-o" "completion: dash prefix lists -o"

COMP_WORDS=("my-tool" "b")
COMP_CWORD=1
COMPREPLY=()
_complete_my_tool
test::contains "${COMPREPLY[*]}" "build" "completion: command prefix b matches build"
test::contains "${COMPREPLY[*]}" "b" "completion: command prefix b matches b"

COMP_WORDS=("my-tool" "de")
COMP_CWORD=1
COMPREPLY=()
_complete_my_tool
test::contains "${COMPREPLY[*]}" "deploy" "completion: command prefix de matches deploy"

# --- Test: after command, no more commands suggested ---

COMP_WORDS=("my-tool" "build" "")
COMP_CWORD=2
COMPREPLY=()
_complete_my_tool
has_build=0
for r in "${COMPREPLY[@]+"${COMPREPLY[@]}"}"; do
  if [[ "$r" == "build" ]]; then has_build=1; fi
done
test::equal "$has_build" "0" "completion: no commands after command"

# --- Test: register writes file ---

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
HOME="$tmpdir" args::completion::register
test::equal "$(test -f "$tmpdir/.local/share/bash-completion/completions/my-tool" && echo yes || echo no)" "yes" "register: writes completion file"

reg_content="$(cat "$tmpdir/.local/share/bash-completion/completions/my-tool")"
test::contains "$reg_content" "_complete_my_tool()" "register: file contains function"

# --- Test: register skips if file is newer and same version ---

touch -d "2099-01-01" "$tmpdir/.local/share/bash-completion/completions/my-tool"
local_before="$(cat "$tmpdir/.local/share/bash-completion/completions/my-tool")"
HOME="$tmpdir" args::completion::register
local_after="$(cat "$tmpdir/.local/share/bash-completion/completions/my-tool")"
test::equal "$local_before" "$local_after" "register: skips when file is newer"

# --- Test: register regenerates if format version differs ---

comp_file="$tmpdir/.local/share/bash-completion/completions/my-tool"
touch -d "2099-01-01" "$comp_file"
sed -i '1s/.*/# options.bash-completion v0/' "$comp_file"
HOME="$tmpdir" args::completion::register
regen_first_line="$(head -1 "$comp_file")"
test::equal "$regen_first_line" "# options.bash-completion v${args_completion_format_version}" "register: regenerates on version mismatch"

# --- Test: args::parse wrapper calls register ---

tmpdir2="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir" "$tmpdir2"' EXIT

args_options=()
args_command=""
args_cleaned=()
HOME="$tmpdir2" args::parse build
test::equal "$(test -f "$tmpdir2/.local/share/bash-completion/completions/my-tool" && echo yes || echo no)" "yes" "on_options: auto-registers"

test::done
