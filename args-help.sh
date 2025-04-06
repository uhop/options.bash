#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

_load_dependencies() {
  local script_dir=${BASH_SOURCE:-$0}
  local previous_ANSI_NO_DEFAULT_COMMANDS="${ANSI_NO_DEFAULT_COMMANDS:-}"
  ANSI_NO_DEFAULT_COMMANDS=1
  source "$(dirname "$(realpath "$script_dir")")/ansi-style.sh"
  ANSI_NO_DEFAULT_COMMANDS="$previous_ANSI_NO_DEFAULT_COMMANDS"
}
_load_dependencies
unset _load_dependencies

args_help_bold="$(ansi::style::get bold)"
args_help_italic="$(ansi::style::get italic)"
args_help_reset="$(ansi::style::get reset_all)"

CYAN="$(ansi::style::get cyan)"

args_help_section="${args_help_bold}$(ansi::style::get green)"
args_help_program="${args_help_bold}$CYAN"
args_help_version="$CYAN"
args_help_command="$(ansi::style::get magenta)"
args_help_option="$CYAN"
args_help_arg="${args_help_italic}$CYAN"

unset CYAN

args::option::help() {
  ansi::out "${args_help_program}${args_program_name}${args_help_reset} " \
    "${args_help_version}${args_program_version}${args_help_reset} " \
    "${args_program_description}"
  echo
  ansi::out "${args_help_section}Usage:${args_help_reset}"
  ansi::out "  ${args_help_program}${args_program_name}${args_help_reset}" \
    "${args_help_option}[options]${args_help_reset}" \
    "${args_help_command}[command]${args_help_reset}" \
    "${args_help_arg}[command arguments]${args_help_reset}"
  echo
  ansi::out "${args_help_section}Options:${args_help_reset}"
  for option in "${!args_names[@]}"; do
    if [[ "$option" == "--"* ]]; then continue; fi
    if [[ "$option" != "-"* ]]; then continue; fi
    ansi::out "  ${args_help_bold}${args_help_option}${args_names[$option]}${args_help_reset}"
  done
  for option in "${!args_names[@]}"; do
    if [[ "$option" != "--"* ]]; then continue; fi
    ansi::out "  ${args_help_bold}${args_help_option}${args_names[$option]}${args_help_reset}"
  done
  echo
  ansi::out "${args_help_section}Commands:${args_help_reset}"
  for command in "${!args_names[@]}"; do
    if [[ "$command" == "-"* ]]; then continue; fi
    ansi::out "  ${args_help_bold}${args_help_command}${args_names[$command]}${args_help_reset}"
  done
  exit 0
}

args::option::h() {
  args::option::help
}
