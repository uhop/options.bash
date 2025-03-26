#!/usr/bin/env bash

source "../../box.sh"

lines1=$'a\nbc\ndef'
lines2=$'1zx\n2'

box1=$(box::exec "$lines1" set_pad '*' normalize center set_pad '.' pad_lr 2 2 pad_tb 1 1)
box2=$(box::exec "$lines2" set_pad '*' normalize center set_pad '.' align_lr center 7 align_tb center 4)

box::echo "$(box::stack_tb "$box1" "$box2")"

lines3=$'a\nbc\ndef'
lines4=$'1\n2\n3'

box3=$(box::exec "$lines3" set_pad '*' normalize center set_pad '.' pad_lr 2 2 pad_tb 1 1)
box4=$(box::exec "$lines4" set_pad '*' normalize center set_pad '.' align_lr center 5 align_tb center 5)

box::echo "$(box::stack_lr "$box3" "$box4")"
