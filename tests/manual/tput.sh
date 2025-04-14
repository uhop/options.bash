#!/usr/bin/env bash

cap_name="$1"
string="$(tput "$@")"

# lines="$(printf "op\nsetab 1\nsetaf 2\nsgr0\n")"
# string="$(tput -S <<< "$lines")"

encode() {
  local escaped="${1@Q}"
  echo "${escaped:2:-1}"
}

echo "$@: $(encode "$string")"
