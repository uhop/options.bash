#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
source "$script_dir/../test.sh"
source "$test_lib_dir/deps.sh"

echo "deps.sh"

# deps::need — all tools present

status=0
output=$(deps::need bash ls 2>&1) || status=$?
test::equal "$status" "0" "need: all present exits 0"
test::equal "$output" "" "need: all present silent"

# deps::need — zero-arg

status=0
output=$(deps::need 2>&1) || status=$?
test::equal "$status" "0" "need: zero-arg exits 0"
test::equal "$output" "" "need: zero-arg silent"

# deps::need — single missing

status=0
output=$(deps::need __missing_tool_abc 2>&1) || status=$?
test::equal "$status" "1" "need: single missing exits 1"
test::contains "$output" "required tool(s) not installed: __missing_tool_abc" "need: single missing stderr"

# deps::need — multiple missing, order preserved, one line

status=0
output=$(deps::need __missing_a __missing_b __missing_c 2>&1) || status=$?
test::equal "$status" "1" "need: multiple missing exits 1"
test::contains "$output" "required tool(s) not installed: __missing_a __missing_b __missing_c" "need: multiple missing aggregated in order"

# deps::need — mixed present/missing lists only missing

status=0
output=$(deps::need bash __missing_x ls __missing_y 2>&1) || status=$?
test::equal "$status" "1" "need: mixed exits 1"
test::contains "$output" "required tool(s) not installed: __missing_x __missing_y" "need: mixed lists only missing"

# program name — falls back to ${0##*/} when args_program_name is unset

status=0
output=$(deps::need __missing_z 2>&1) || status=$?
test::match "$output" "^test-deps\.sh:" "need: fallback uses \${0##*/}"

# program name — uses args_program_name when set

args_program_name="my-tool"
status=0
output=$(deps::need __missing_z 2>&1) || status=$?
test::match "$output" "^my-tool:" "need: uses args_program_name when set"

test::done
