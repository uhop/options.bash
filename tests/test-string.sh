#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
source "$script_dir/../test.sh"
source "$test_lib_dir/string.sh"

echo "string.sh"

# string::length (without ANSI loaded — raw length)

test::equal "$(string::length 'hello')" "5" "length: plain string"
test::equal "$(string::length '')" "0" "length: empty string"
test::equal "$(string::length 'a b c')" "5" "length: string with spaces"

# string::make_pad

test::equal "$(string::make_pad 0)" "" "make_pad: zero length"
test::equal "$(string::make_pad 5)" "     " "make_pad: spaces"
test::equal "$(string::make_pad 3 '.')" "..." "make_pad: dots"
test::equal "$(string::make_pad 4 '*')" "****" "make_pad: stars"
test::equal "$(string::make_pad 1 '#')" "#" "make_pad: single char"

# string::pad — left align

test::equal "$(string::pad 'hi' 10 l)" "hi        " "pad: left align"
test::equal "$(string::pad 'hi' 10 left)" "hi        " "pad: left (word)"
test::equal "$(string::pad 'hi' 2 l)" "hi" "pad: exact length"

# string::pad — right align

test::equal "$(string::pad 'hi' 10 r)" "        hi" "pad: right align"
test::equal "$(string::pad 'hi' 10 right)" "        hi" "pad: right (word)"

# string::pad — center align

test::equal "$(string::pad 'hi' 10 c)" "    hi    " "pad: center align"
test::equal "$(string::pad 'hi' 10 center)" "    hi    " "pad: center (word)"
test::equal "$(string::pad 'hi' 11 c)" "    hi     " "pad: center odd"

# string::pad — custom pad char

test::equal "$(string::pad 'hi' 6 l '.')" "hi...." "pad: left with dots"
test::equal "$(string::pad 'hi' 6 r '.')" "....hi" "pad: right with dots"
test::equal "$(string::pad 'hi' 6 c '.')" "..hi.." "pad: center with dots"

# string::clean (without ANSI — passthrough)

test::equal "$(string::clean 'hello')" "hello" "clean: plain passthrough"
test::equal "$(string::clean '')" "" "clean: empty passthrough"

# string::length with ANSI module loaded (re-source to get ansi::length)

source "$test_lib_dir/ansi.sh"

test::equal "$(string::length "${RED}hello${RESET_ALL}")" "5" "length: ANSI-aware"
test::equal "$(string::length "${BOLD}${GREEN}ok${RESET_ALL}")" "2" "length: ANSI-aware styled"

# string::clean with ANSI module (strips escape codes)

test::equal "$(string::clean "${RED}hello${RESET_ALL}")" "hello" "clean: strips ANSI"
test::equal "$(string::clean "${BOLD}ok${RESET_ALL}")" "ok" "clean: strips bold"

test::done
