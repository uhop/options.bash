#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
source "$script_dir/../test.sh"
source "$test_lib_dir/box.sh"

echo "box.sh"

# box::make_lines

result=$(box::make_lines "a" "bc" "def")
test::equal "$result" $'a\nbc\ndef' "make_lines: basic"

result=$(box::make_lines "single")
test::equal "$result" "single" "make_lines: single line"

# box::make (normalizes to equal width, left-aligned)

result=$(box::make "a" "bc" "def")
test::equal "$result" $'a  \nbc \ndef' "make: normalizes left"

# box::get_width

test::equal "$(box::get_width $'hello\nworld')" "5" "get_width: equal lines"
test::equal "$(box::get_width "abc")" "3" "get_width: single line"
test::equal "$(box::get_width "")" "0" "get_width: empty"

# box::get_height

test::equal "$(box::get_height $'a\nb\nc')" "3" "get_height: three lines"
test::equal "$(box::get_height "abc")" "1" "get_height: single line"
test::equal "$(box::get_height "")" "0" "get_height: empty"

# box::exec — normalize left

result=$(box::exec $'a\nbc\ndef' normalize left)
test::equal "$result" $'a  \nbc \ndef' "exec normalize left"

# box::exec — normalize right

result=$(box::exec $'a\nbc\ndef' normalize right)
test::equal "$result" $'  a\n bc\ndef' "exec normalize right"

# box::exec — normalize center

result=$(box::exec $'a\nbc\ndef' normalize center)
test::equal "$result" $' a \nbc \ndef' "exec normalize center"

# box::exec — set_pad + normalize

result=$(box::exec $'a\nbc\ndef' set_pad '.' normalize left)
test::equal "$result" $'a..\nbc.\ndef' "exec set_pad + normalize"

# box::exec — pad_lr

result=$(box::exec $'ab\ncd' normalize left pad_lr 1 1)
test::equal "$result" $' ab \n cd ' "exec pad_lr"

result=$(box::exec $'ab\ncd' normalize left set_pad '.' pad_lr 2 2)
test::equal "$result" $'..ab..\n..cd..' "exec pad_lr with dots"

# box::exec — pad_tb

result=$(box::exec "ab" pad_tb 1 1)
test::equal "$result" $'  \nab\n  ' "exec pad_tb"

# box::exec — align_lr

lines=$(box::exec $'ab\ncd' normalize left)
result=$(box::exec "$lines" align_lr left 6)
test::equal "$result" $'ab    \ncd    ' "exec align_lr left"

result=$(box::exec "$lines" align_lr right 6)
test::equal "$result" $'    ab\n    cd' "exec align_lr right"

result=$(box::exec "$lines" align_lr center 6)
test::equal "$result" $'  ab  \n  cd  ' "exec align_lr center"

# box::exec — align_tb (default space padding)

result=$(box::exec "ab" align_tb top 3)
test::equal "$result" $'ab\n  \n  ' "exec align_tb top"

result=$(box::exec "ab" align_tb bottom 3)
test::equal "$result" $'  \n  \nab' "exec align_tb bottom"

result=$(box::exec "ab" align_tb center 3)
test::equal "$result" $'  \nab\n  ' "exec align_tb center"

# box::exec — align_tb with custom pad

result=$(box::exec "ab" set_pad '.' align_tb top 3)
test::equal "$result" $'ab\n..\n..' "exec align_tb top (dots)"

result=$(box::exec "ab" set_pad '.' align_tb center 3)
test::equal "$result" $'..\nab\n..' "exec align_tb center (dots)"

# box::exec — extract

result=$(box::exec $'a\nb\nc\nd' extract 1 2)
test::equal "$result" $'b\nc' "exec extract"

# box::exec — clean

source "$test_lib_dir/ansi.sh"
colored=$(box::exec "${RED}hi${RESET_ALL}" normalize left)
result=$(box::exec "$colored" clean)
test::equal "$result" "hi" "exec clean"

# box::exec — aliases

result=$(box::exec $'a\nbc' sp '.' n l ph 1 1 pv 1 1)
expected=$'....\n.a..\n.bc.\n....'
test::equal "$result" "$expected" "exec aliases: sp n ph pv"

# box::stack_tb

box1=$(box::exec $'ab\ncd' normalize left)
box2=$(box::exec $'ef\ngh' normalize left)
result=$(box::stack_tb "$box1" "$box2")
test::equal "$result" $'ab\ncd\nef\ngh' "stack_tb"

# box::stack_lr

box1=$(box::exec $'ab\ncd' normalize left)
box2=$(box::exec $'ef\ngh' normalize left)
result=$(box::stack_lr "$box1" "$box2")
test::equal "$result" $'abef\ncdgh' "stack_lr"

# box::warn — returns 0, writes to stderr

status=0
box::warn "test warning" 2>/dev/null || status=$?
test::equal "$status" "0" "warn: returns 0"

result=$(box::warn "hello warn" 2>&1)
test::contains "$result" "hello warn" "warn: writes to stderr"

# box::err — returns 1

status=0
box::err "test error" 2>/dev/null || status=$?
test::equal "$status" "1" "err: returns 1"

test::done
