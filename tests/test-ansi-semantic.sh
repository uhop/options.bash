#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
source "$script_dir/../test.sh"
source "$test_lib_dir/ansi-semantic.sh"

echo "ansi-semantic.sh"

# Prefixed globals always defined

test::not_equal "${SEMANTIC_ERROR:-}" "" "global: SEMANTIC_ERROR defined"
test::not_equal "${SEMANTIC_WARN:-}" "" "global: SEMANTIC_WARN defined"
test::not_equal "${SEMANTIC_INFO:-}" "" "global: SEMANTIC_INFO defined"
test::not_equal "${SEMANTIC_OK:-}" "" "global: SEMANTIC_OK defined"

# Simple names defined (ANSI_NO_SEMANTIC_NAMES not set)

test::not_equal "${ERROR:-}" "" "global: ERROR defined"
test::not_equal "${WARN:-}" "" "global: WARN defined"
test::not_equal "${INFO:-}" "" "global: INFO defined"
test::not_equal "${OK:-}" "" "global: OK defined"

# Simple names match prefixed forms

test::equal "$ERROR" "$SEMANTIC_ERROR" "ERROR equals SEMANTIC_ERROR"
test::equal "$WARN" "$SEMANTIC_WARN" "WARN equals SEMANTIC_WARN"
test::equal "$INFO" "$SEMANTIC_INFO" "INFO equals SEMANTIC_INFO"
test::equal "$OK" "$SEMANTIC_OK" "OK equals SEMANTIC_OK"

# Globals contain escape sequences (not empty strings)

test::match "$SEMANTIC_ERROR" $'\e' "SEMANTIC_ERROR contains escape"
test::match "$SEMANTIC_WARN" $'\e' "SEMANTIC_WARN contains escape"
test::match "$SEMANTIC_INFO" $'\e' "SEMANTIC_INFO contains escape"
test::match "$SEMANTIC_OK" $'\e' "SEMANTIC_OK contains escape"

# ansi::semantic::define produces eval-able output

output=$(ansi::semantic::define)
test::contains "$output" "ERROR" "define: contains ERROR"
test::contains "$output" "WARN" "define: contains WARN"
test::contains "$output" "INFO" "define: contains INFO"
test::contains "$output" "OK" "define: contains OK"

# ansi::semantic::define with prefix

output=$(ansi::semantic::define "MY_")
test::contains "$output" "MY_ERROR" "define prefix: MY_ERROR"
test::contains "$output" "MY_WARN" "define prefix: MY_WARN"
test::contains "$output" "MY_INFO" "define prefix: MY_INFO"
test::contains "$output" "MY_OK" "define prefix: MY_OK"

# Custom override via SEMANTIC_* reassignment

original_ok="$SEMANTIC_OK"
SEMANTIC_OK="${TEXT_BOLD}${FG_BRIGHT_YELLOW}"
eval "$(ansi::semantic::define)"
test::equal "$OK" "$SEMANTIC_OK" "override: OK tracks SEMANTIC_OK"
test::not_equal "$OK" "$original_ok" "override: OK changed from default"
SEMANTIC_OK="$original_ok"
eval "$(ansi::semantic::define)"

# Suppression test via subshell

suppressed_error=$(ANSI_NO_SEMANTIC_NAMES=1 bash -c "
  source \"$test_lib_dir/ansi-semantic.sh\"
  echo \"\${ERROR:-unset}\"
")
test::equal "$suppressed_error" "unset" "suppression: ERROR not defined with ANSI_NO_SEMANTIC_NAMES"

suppressed_semantic=$(ANSI_NO_SEMANTIC_NAMES=1 bash -c "
  source \"$test_lib_dir/ansi-semantic.sh\"
  echo \"\${SEMANTIC_ERROR:-unset}\"
")
test::not_equal "$suppressed_semantic" "unset" "suppression: SEMANTIC_ERROR still defined"

test::done
