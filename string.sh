#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

string::err() {
  local msg="$1"
  echo "$msg" >&2
  return 1
}

string::clean() {
  local string="$1"
  sed 's/\x1B\[[0-9;]*[a-zA-Z]//g' <<< "$string"
}

string::length() {
  local string="$1"
  local string_clean=$(string::clean "$string")
  echo "${#string_clean}"
}

string::make_pad() {
  local length="$1"
  local pad="${2:- }"

  local pad_clean=$(string::clean "$pad")
  if [[ "${#pad_clean}" -ne 1 ]]; then
    string::err "Error: Invalid pad character '$1'"
    return 1
  fi

  if [[ "$pad" == ' ' ]]; then
    printf "%${length}s" ''
  else
    printf "%${length}s" '' | tr ' ' "$pad_clean"
  fi
}

string::pad() {
  local string="$1"
  local length="$2"
  local align="${3:-l}"
  local pad="${4:- }"

  local string_clean=$(string::clean "$string")
  local diff=$((length - ${#string_clean}))

  local pad_left=0
  local pad_right=0

  case "$align" in
    l | left)
      pad_right="$diff"
      ;;
    r | right)
      pad_left="$diff"
      ;;
    c | center)
      pad_left=$((diff / 2))
      pad_right=$((diff - pad_left))
      ;;
  esac

  local pad_left_str=$(string::make_pad "$pad_left" "$pad")
  local pad_right_str=$(string::make_pad "$pad_right" "$pad")

  printf "%s%s%s" "$pad_left_str" "$string_clean" "$pad_right_str"
}
