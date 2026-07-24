#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
source "$script_dir/../test.sh"
source "$test_lib_dir/box.sh"
source "$test_lib_dir/ansi.sh"
source "$test_lib_dir/args-completion.sh"

echo "scoping"

# Library calls must not clobber caller variables (leaked loop iterators).
# Calls are direct (not $(...)): command substitution runs in a subshell and
# would hide the leak.

i='S'; line='S'; arg='S'; name='S'; color='S'; style='S'
option='S'; command='S'; key='S'; n='S'

box::make_lines "a" "b" > /dev/null
box::exec $'a\nbc' normalize center pad_lr 1 1 pad_tb 1 1 frame rounded > /dev/null
box::stack_lr $'a\nb' $'c\nd' > /dev/null
box::stack_tb "ab" "cd" > /dev/null
box::out "x" > /dev/null
string::out "x" > /dev/null
ansi::make bold red > /dev/null
ansi::out "x" > /dev/null
ansi::alias_simple_command_names > /dev/null
args::program "scoping-test" "1.0.0" "leak test"
args::option "-x, --xx" "an option"
args::completion::generate > /dev/null

snapshot=()
for v in i line arg name color style option command key n; do
  snapshot+=("${v}=${!v}")
done
for pair in "${snapshot[@]}"; do
  test::equal "${pair#*=}" "S" "caller's \$${pair%%=*} intact"
done

test::done
