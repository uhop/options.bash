#!/usr/bin/env bash

source "$(dirname "$(realpath "$0")")/../../box.sh"

# lines=$'a\nbc\ndef'
lines=$(box::make_lines "a" "bc" "def")

# array=("a" "bc" "def")
# lines=$(box::make_lines "${array[@]}")

# box=$(box::exec "$lines")
box=$(box::exec "$lines" set_pad '*' normalize center sp '.' ph 2 2 pv 1 1)
# echo -e "$box"

box::out "$box"

for theme in ascii unicode rounded double heavy; do
  box::out "$(box::exec "$lines" normalize center pad_lr 1 1 frame "$theme")"
done