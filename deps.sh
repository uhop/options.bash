#!/usr/bin/env bash

if type deps::need > /dev/null 2>&1; then return; fi

set -euo pipefail

deps::need() {
  local prog="${args_program_name:-${0##*/}}" missing=() cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if (( ${#missing[@]} > 0 )); then
    echo "${prog}: required tool(s) not installed: ${missing[*]}" >&2
    exit 1
  fi
}
