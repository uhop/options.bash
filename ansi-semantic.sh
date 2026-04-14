#!/usr/bin/env bash

if type ansi::semantic::define > /dev/null 2>&1; then return; fi

set -euo pipefail

_load_dependencies() {
  local script_dir=${BASH_SOURCE:-$0}
  script_dir="$(dirname "$(realpath "$script_dir")")"
  source "${script_dir}/ansi.sh"
}
if ! type ansi::fg >/dev/null 2>&1; then
  _load_dependencies
fi
unset -f _load_dependencies

# Semantic color globals — composed from prefixed ANSI names (always available).
# Override before sourcing: set ANSI_SEMANTIC_ERROR, ANSI_SEMANTIC_WARN, etc.
declare -g SEMANTIC_ERROR="${ANSI_SEMANTIC_ERROR:-${TEXT_BOLD}${FG_BRIGHT_WHITE}${BG_RED}}"
declare -g SEMANTIC_WARN="${ANSI_SEMANTIC_WARN:-${TEXT_BOLD}${FG_BRIGHT_WHITE}${BG_BLUE}}"
declare -g SEMANTIC_INFO="${ANSI_SEMANTIC_INFO:-${TEXT_BOLD}${FG_CYAN}}"
declare -g SEMANTIC_OK="${ANSI_SEMANTIC_OK:-${TEXT_BOLD}${FG_GREEN}}"

ansi::semantic::define() {
  local prefix="${1:-}"
  prefix="${prefix^^}"

  echo "${prefix}ERROR=\"\${SEMANTIC_ERROR}\""
  echo "${prefix}WARN=\"\${SEMANTIC_WARN}\""
  echo "${prefix}INFO=\"\${SEMANTIC_INFO}\""
  echo "${prefix}OK=\"\${SEMANTIC_OK}\""
}

if [ -z "${ANSI_NO_SEMANTIC_NAMES:-}" ]; then
  eval "$(ansi::semantic::define)"
fi
