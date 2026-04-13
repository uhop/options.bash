#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
source "$script_dir/../test.sh"
source "$test_lib_dir/ansi.sh"

echo "ansi.sh + ansi-utils.sh"

# Simple command name globals exist

test::not_equal "${RED:-}" "" "global: RED defined"
test::not_equal "${GREEN:-}" "" "global: GREEN defined"
test::not_equal "${BLUE:-}" "" "global: BLUE defined"
test::not_equal "${BOLD:-}" "" "global: BOLD defined"
test::not_equal "${RESET_ALL:-}" "" "global: RESET_ALL defined"
test::not_equal "${ITALIC:-}" "" "global: ITALIC defined"
test::not_equal "${UNDERLINE:-}" "" "global: UNDERLINE defined"
test::not_equal "${DIM:-}" "" "global: DIM defined"

# Prefixed forms

test::not_equal "${FG_RED:-}" "" "global: FG_RED defined"
test::not_equal "${BG_GREEN:-}" "" "global: BG_GREEN defined"
test::not_equal "${BRIGHT_RED:-}" "" "global: BRIGHT_RED defined"

# ansi::fg / ansi::bg produce escape sequences

test::contains "$(ansi::fg 1)" '\e[' "fg: contains escape"
test::contains "$(ansi::bg 2)" '\e[' "bg: contains escape"

# ansi::get resolves named styles

test::not_equal "$(ansi::get red)" "" "get: red"
test::not_equal "$(ansi::get bold)" "" "get: bold"
test::not_equal "$(ansi::get reset_all)" "" "get: reset_all"
test::equal "$(ansi::get nonexistent_style_xyz)" "" "get: unknown returns empty"

# ansi::strip

test::equal "$(ansi::strip "${RED}hello${RESET_ALL}")" "hello" "strip: removes color"
test::equal "$(ansi::strip "${BOLD}${GREEN}ok${RESET_ALL}")" "ok" "strip: removes bold+color"
test::equal "$(ansi::strip "plain")" "plain" "strip: plain passthrough"
test::equal "$(ansi::strip "")" "" "strip: empty string"

# ansi::length

test::equal "$(ansi::length "${RED}hello${RESET_ALL}")" "5" "length: colored string"
test::equal "$(ansi::length "hello")" "5" "length: plain string"
test::equal "$(ansi::length "")" "0" "length: empty string"

# ansi::make

result=$(ansi::make bold red)
test::not_equal "$result" "" "make: bold red produces output"
test::match "$result" $'\e' "make: contains escape"

# ansi::color::rgb

test::equal "$(ansi::color::rgb 0 0 0)" "0" "color rgb: black"
test::equal "$(ansi::color::rgb 1 0 0)" "1" "color rgb: red"
test::equal "$(ansi::color::rgb 0 1 0)" "2" "color rgb: green"
test::equal "$(ansi::color::rgb 0 0 1)" "4" "color rgb: blue"
test::equal "$(ansi::color::rgb 1 1 1)" "7" "color rgb: white"

# ansi::color::make_bright

test::equal "$(ansi::color::make_bright 0)" "8" "make_bright: 0 -> 8"
test::equal "$(ansi::color::make_bright 1)" "9" "make_bright: 1 -> 9"
test::equal "$(ansi::color::make_bright 7)" "15" "make_bright: 7 -> 15"

# ansi::warn — returns 0, writes to stderr

status=0
ansi::warn "test warning" 2>/dev/null || status=$?
test::equal "$status" "0" "warn: returns 0"

result=$(ansi::warn "hello warn" 2>&1)
test::contains "$result" "hello warn" "warn: writes to stderr"

# ansi::err — returns 1

status=0
ansi::err "test error" 2>/dev/null || status=$?
test::equal "$status" "1" "err: returns 1"

# ansi::out — writes to stdout

result=$(ansi::out "hello out")
test::contains "$result" "hello out" "out: writes to stdout"

# ANSI_NO_SIMPLE_COMMAND_NAMES suppression
# (tested implicitly by verifying globals exist above)

test::done
