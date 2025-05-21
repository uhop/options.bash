#!/usr/bin/env bash

if type ansi::out > /dev/null 2>&1; then return; fi

set -euo pipefail

ansi::color::rgb() {
  local r="$1"
  local g="$2"
  local b="$3"

  local result=0
  if [[ "$r" -ne 0 ]]; then result+=1; fi
  if [[ "$g" -ne 0 ]]; then result+=2; fi
  if [[ "$b" -ne 0 ]]; then result+=4; fi
  echo "$result"
}

ansi::color::make_bright() {
  local code="$1"
  echo "$(( $code + 8 ))"
}

ansi::color::true() {
  local r="$1"
  local g="$2"
  local b="$3"
  echo "$((16 + r * 6 / 256 * 36 + g * 6 / 256 * 6 + b * 6 / 256))"
}

ansi::color::grey() {
  local intensity="$1"
  echo "$((232 + intensity * 24 / 256))"
}

ansi::fg::rgb() { ansi::fg "$(ansi::color::rgb "$@")"; }
ansi::fg::bright_rgb() { ansi::fg "$(ansi::color::make_bright "$(ansi::color::rgb "$@")")"; }
ansi::fg::true() { ansi::fg "$(ansi::color::true "$@")"; }
ansi::fg::grey() { ansi::fg "$(ansi::color::grey "$@")"; }

ansi::bg::rgb() { ansi::bg "$(ansi::color::rgb "$@")"; }
ansi::bg::bright_rgb() { ansi::bg "$(ansi::color::make_bright "$(ansi::color::rgb "$@")")"; }
ansi::bg::true() { ansi::bg "$(ansi::color::true "$@")"; }
ansi::bg::grey() { ansi::bg "$(ansi::color::grey "$@")"; }

ansi::extract_sgr_commands() {
  local command="$1"
  if [[ "$command" =~ ^($'\e'|\e|\\e|\\033|\\x1B|\\x1b)\[([^m]+)m$ ]]; then
    echo "${BASH_REMATCH[2]%;}"
    return 0
  fi
  echo "Error: Invalid command: ${command@Q}" >&2
  return 1
}

ansi::make() {
  local string=""
  for arg in "$@"; do
    local code="$(ansi::get "$arg")"
    if [ -n "$code" ]; then
      string+="$code"
    elif [[ "$arg" =~ ^[0-9] ]]; then
      string+="\e[${arg%;}m"
    else
      string+="$arg"
    fi
  done
  echo "${string}"
}

ansi::strip() {
  local string="$1"
  sed 's/\(\x1B\|\\e\|\\x1B\|\\033\)\[[0-9;:]*[a-z]//gi' <<< "$string"
}

ansi::length() {
  local string="$1"
  local string_clean=$(ansi::strip "$string")
  echo "${#string_clean}"
}

ansi::err() {
  if [[ -t 2 || -z "$TERM" ]]; then
    echo -e "$@" >&2
    return 1
  fi

  local -a args=()
  for arg in "$@"; do
    args+=("$(ansi::strip "$arg")")
  done
  echo -e "${args[@]}" >&2
  return 1
}

ansi::out() {
  if [[ -t 1 || -z "$TERM" ]]; then
    echo -e "$@"
    return 0
  fi

  local -a args=()
  for arg in "$@"; do
    args+=("$(ansi::strip "$arg")")
  done
  echo -e "${args[@]}"
  return 0
}

ansi::prompt() {
  if [[ -t 1 || -z "$TERM" ]]; then
    echo -en "$@"
    return 0
  fi

  local -a args=()
  for arg in "$@"; do
    args+=("$(ansi::strip "$arg")")
  done
  echo -en "${args[@]}"
  return 0
}
