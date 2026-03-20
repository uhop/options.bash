#!/usr/bin/env bash

if type test::equal > /dev/null 2>&1; then return; fi

set -euo pipefail

_load_dependencies() {
  local script_dir=${BASH_SOURCE:-$0}
  script_dir="$(dirname "$(realpath "$script_dir")")"
  source "${script_dir}/ansi.sh"
}
if ! type ansi::out >/dev/null 2>&1; then
  _load_dependencies
fi
unset _load_dependencies

test_lib_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

test_pass=0
test_fail=0
test_total=0
test_name=""

test::name() {
  test_name="$1"
}

test::equal() {
  local actual="$1"
  local expected="$2"
  local msg="${3:-}"
  test_total=$((test_total + 1))
  if [[ "$actual" == "$expected" ]]; then
    test_pass=$((test_pass + 1))
    echo -e "  ${GREEN}ok${RESET_ALL} ${test_total} ${msg}"
  else
    test_fail=$((test_fail + 1))
    echo -e "  ${RED}FAIL${RESET_ALL} ${test_total} ${msg}"
    echo -e "    expected: ${expected@Q}"
    echo -e "    actual:   ${actual@Q}"
  fi
}

test::not_equal() {
  local actual="$1"
  local expected="$2"
  local msg="${3:-}"
  test_total=$((test_total + 1))
  if [[ "$actual" != "$expected" ]]; then
    test_pass=$((test_pass + 1))
    echo -e "  ${GREEN}ok${RESET_ALL} ${test_total} ${msg}"
  else
    test_fail=$((test_fail + 1))
    echo -e "  ${RED}FAIL${RESET_ALL} ${test_total} ${msg}"
    echo -e "    expected anything other than: ${expected@Q}"
  fi
}

test::match() {
  local actual="$1"
  local pattern="$2"
  local msg="${3:-}"
  test_total=$((test_total + 1))
  if [[ "$actual" =~ $pattern ]]; then
    test_pass=$((test_pass + 1))
    echo -e "  ${GREEN}ok${RESET_ALL} ${test_total} ${msg}"
  else
    test_fail=$((test_fail + 1))
    echo -e "  ${RED}FAIL${RESET_ALL} ${test_total} ${msg}"
    echo -e "    value:   ${actual@Q}"
    echo -e "    pattern: ${pattern@Q}"
  fi
}

test::contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-}"
  test_total=$((test_total + 1))
  if echo "$haystack" | grep -qF "$needle"; then
    test_pass=$((test_pass + 1))
    echo -e "  ${GREEN}ok${RESET_ALL} ${test_total} ${msg}"
  else
    test_fail=$((test_fail + 1))
    echo -e "  ${RED}FAIL${RESET_ALL} ${test_total} ${msg}"
    echo -e "    value:    ${haystack@Q}"
    echo -e "    expected: ${needle@Q}"
  fi
}

test::ok() {
  local msg="${1:-}"
  test_total=$((test_total + 1))
  test_pass=$((test_pass + 1))
  echo -e "  ${GREEN}ok${RESET_ALL} ${test_total} ${msg}"
}

test::fail_() {
  local msg="${1:-}"
  test_total=$((test_total + 1))
  test_fail=$((test_fail + 1))
  echo -e "  ${RED}FAIL${RESET_ALL} ${test_total} ${msg}"
}

test::done() {
  echo ""
  if [[ "$test_fail" -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All ${test_pass} tests passed.${RESET_ALL}"
  else
    echo -e "${RED}${BOLD}${test_fail} of ${test_total} tests failed.${RESET_ALL}"
  fi
  if [[ "$test_fail" -gt 0 ]]; then
    exit 1
  fi
  exit 0
}
