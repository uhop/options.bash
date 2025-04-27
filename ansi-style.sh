#!/usr/bin/env bash

if type ansi::fg > /dev/null 2>&1; then return; fi

set -o errexit -o pipefail -o nounset -o noclobber

if [[ -z "$BASH_VERSION" ]]; then
  echo "This script requires bash."
  exit 1
fi

if [[ "$BASH_VERSION" < "4.0" ]]; then
  echo "This script requires bash version 4.0 or higher."
  if [[ "$(uname -s)" == "Darwin"* ]]; then
    echo "You can install it with Homebrew: brew install bash"
  fi
  exit 1
fi

_load_dependencies() {
  local script_dir=${BASH_SOURCE:-$0}
  script_dir="$(dirname "$(realpath "$script_dir")")"
  source "${script_dir}/ansi-utils.sh"
}
if ! type string::err >/dev/null 2>&1; then
  _load_dependencies
fi
unset -f _load_dependencies

declare -g -A ansi_style_colors=(
  [black]=0
  [red]=1
  [green]=2
  [yellow]=3
  [blue]=4
  [magenta]=5
  [cyan]=6
  [white]=7
)
declare -g -A ansi_style_sgr_commands=(
  # commands
  [text_reset_all]=$'\e[0m'
  [text_bold]=$'\e[1m'
  [text_dim]=$'\e[2m'
  [text_italic]=$'\e[3m'
  [text_underline]=$'\e[4m'
  [text_blink]=$'\e[5m'
  [text_rapid_blink]=$'\e[6m'
  [text_reverse]=$'\e[7m'
  [text_hidden]=$'\e[8m'
  [text_strike_through]=$'\e[9m'
  [text_default_font]=$'\e[10m'
  [text_reset_bold]=$'\e[22m'
  [text_reset_dim]=$'\e[22m'
  [text_reset_italic]=$'\e[23m'
  [text_reset_underline]=$'\e[24m'
  [text_reset_blink]=$'\e[25m'
  [text_reset_rapid_blink]=$'\e[25m'
  [text_reset_reverse]=$'\e[27m'
  [text_reset_hidden]=$'\e[28m'
  [text_reset_strike_through]=$'\e[29m'
  [text_curly_underline]=$'\e[4:3m'
  [text_reset_curly_underline]=$'\e[24m'
  [text_double_underline]=$'\e[21m'
  [text_reset_double_underline]=$'\e[24m'
  [fg_default]=$'\e[39m'
  [bg_default]=$'\e[49m'
  [text_reset_color]=$'\e[39m'
  [text_reset_fg_color]=$'\e[39m'
  [text_reset_bg_color]=$'\e[49m'
  [text_overline]=$'\e[53m'
  [text_reset_overline]=$'\e[55m'
  [text_decoration_default]=$'\e[59m'
  [text_reset_decoration_color]=$'\e[59m'
)

ansi::style::populate_colors() {
  for color in "${!ansi_style_colors[@]}"; do
    ansi_style_sgr_commands["fg_${color}"]="\e[$((${ansi_style_colors[$color]} + 30))m"
    ansi_style_sgr_commands["bg_${color}"]="\e[$((${ansi_style_colors[$color]} + 40))m"
    ansi_style_sgr_commands["fg_bright_${color}"]="\e[$((${ansi_style_colors[$color]} + 90))m"
    ansi_style_sgr_commands["bg_bright_${color}"]="\e[$((${ansi_style_colors[$color]} + 100))m"
  done
}
ansi::style::populate_colors
unset -f ansi::style::populate_colors

declare -g -A ansi_style_sgr_extended_colors=(
  [fg]=38
  [bg]=48
  [decoration]=58
)

ansi::style::define_commands() {
  local prefix="${1:-}"
  prefix="${prefix^^}"

  for command in "${!ansi_style_sgr_commands[@]}"; do
    echo "${prefix}${command^^}='${ansi_style_sgr_commands[$command]}'"
  done
}

ansi::style::alias_simple_command_names() {
  local prefix="${1:-}"
  prefix="${prefix^^}"

  for color in "${!ansi_style_colors[@]}"; do
    echo "${prefix}${color^^}=\"\${${prefix}FG_${color^^}:-}\""
    echo "${prefix}BRIGHT_${color^^}=\"\${${prefix}FG_BRIGHT_${color^^}:-}\""
  done

  for name in "${!ansi_style_sgr_commands[@]}"; do
    if ! [[ "$name" =~ ^text_ ]]; then continue; fi
    local short_name="${name#text_}"
    echo "${prefix}${short_name^^}=\"\${${prefix}${name^^}:-}\""
  done
}

ansi::get() {
  local name="$1"
  if [ -v ansi_style_sgr_commands["$name"] ]; then
    echo "${ansi_style_sgr_commands["$name"]}"
  elif [ -v ansi_style_sgr_commands["text_$name"] ]; then
    echo "${ansi_style_sgr_commands["text_$name"]}"
  elif [ -v ansi_style_sgr_commands["fg_$name"] ]; then
    echo "${ansi_style_sgr_commands["fg_$name"]}"
  fi
}

ansi::style::make() {
  local string=""
  for arg in "$@"; do
    local code="$(ansi::get "$arg")"
    if [ -n "$code" ]; then
      string+="$(ansi::extract_sgr_commands "$code");"
    elif [[ "$arg" =~ ^[0-9] ]]; then
      string+="$arg;"
    else
      string+="$(ansi::extract_sgr_commands "$arg");"
    fi
  done
  echo "\e[${string%;}m"
}

ansi::fg() {
  local -i color="$1"
  if [[ "$color" -lt 8 ]]; then
    echo "\e[$((color + 30))m"
  elif [[ "$color" -lt 16 ]]; then
    echo "\e[$((color + 82))m"
  else
    echo "\e[${ansi_style_sgr_extended_colors["fg"]};5;${color}m"
  fi
}

ansi::bg() {
  local -i color="$1"
  if [[ "$color" -lt 8 ]]; then
    echo "\e[$((color + 40))m"
  elif [[ "$color" -lt 16 ]]; then
    echo "\e[$((color + 92))m"
  else
    echo "\e[${ansi_style_sgr_extended_colors["bg"]};5;${color}m"
  fi
}

ansi::code::fg() { echo "$((30 + $1))"; }
ansi::code::bg() { echo "$((40 + $1))"; }
ansi::code::fg_bright() { echo "$((90 + $1))"; }
ansi::code::bg_bright() { echo "$((100 + $1))"; }

ansi::fg_true() {
  local r="$1"
  local g="$2"
  local b="$3"
  echo "\e[${ansi_style_sgr_extended_colors["fg"]};2;${r};${g};${b}m"
}
ansi::bg_true() {
  local r="$1"
  local g="$2"
  local b="$3"
  echo "\e[${ansi_style_sgr_extended_colors["bg"]};2;${r};${g};${b}m"
}

ansi::decoration() {
  local -i color="$1"
  echo "\e[${ansi_style_sgr_extended_colors["decoration"]};5;${color}m"
}
ansi::decoration_true() {
  local r="$1"
  local g="$2"
  local b="$3"
  echo "\e[${ansi_style_sgr_extended_colors["decoration"]};2;${r};${g};${b}m"
}

ansi_style_simple_command_names=""
if [ -z "${ANSI_NO_SIMPLE_COMMAND_NAMES:-}" ]; then
  ansi_style_simple_command_names="$(ansi::style::alias_simple_command_names)"
fi
eval "$(printf '%s\n%s\n' \
  "$(ansi::style::define_commands)" \
  "${ansi_style_simple_command_names}")"
unset ansi_style_simple_command_names
