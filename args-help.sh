#!/usr/bin/env bash

if type args::option::help > /dev/null 2>&1; then return; fi

set -o errexit -o pipefail -o nounset -o noclobber

_load_dependencies() {
  local script_dir=${BASH_SOURCE:-$0}
  script_dir="$(dirname "$(realpath "$script_dir")")"
  local previous_ANSI_NO_DEFAULT_COMMANDS="${ANSI_NO_DEFAULT_COMMANDS:-}"
  ANSI_NO_DEFAULT_COMMANDS=1
  source "${script_dir}/ansi-style.sh"
  source "${script_dir}/ansi-control.sh"
  source "${script_dir}/string.sh"
  source "${script_dir}/box.sh"
  ANSI_NO_DEFAULT_COMMANDS="$previous_ANSI_NO_DEFAULT_COMMANDS"
}
_load_dependencies
unset _load_dependencies

args_help_bold="$(ansi::style::get bold)"
args_help_italic="$(ansi::style::get italic)"
args_help_reset="$(ansi::style::get reset_all)"

CYAN="$(ansi::style::get cyan)"

args_help_section="${args_help_bold}$(ansi::style::get green)"
args_help_program="${args_help_bold}${CYAN}"
args_help_version="${CYAN}"
args_help_command="$(ansi::style::get magenta)"
args_help_option="${CYAN}"
args_help_arg="${args_help_italic}${CYAN}"

unset CYAN

args::option::help() {
  ansi::out "${args_help_program}${args_program_name}${args_help_reset} " \
    "${args_help_version}${args_program_version}${args_help_reset} " \
    "${args_program_description}"

  if [ -n "$args_program_header" ]; then
    echo
    ansi::out "${args_program_header}"
  fi

  echo
  ansi::out "${args_help_section}Usage:${args_help_reset}"
  if [ -z "$args_program_usage" ]; then
    ansi::out "  ${args_help_program}${args_program_name}${args_help_reset}" \
      "${args_help_option}[options]${args_help_reset}" \
      "${args_help_command}[command]${args_help_reset}" \
      "${args_help_arg}[command arguments]${args_help_reset}"
  else
    ansi::out "$(box::exec "${args_program_usage}" pad_lr 2 0)"
  fi

  local -a left=()
  local -a right=()

  for option in "${!args_names[@]}"; do
    if [[ "$option" == "--"* ]]; then continue; fi
    if [[ "$option" != "-"* ]]; then continue; fi
    local text="  ${args_help_bold}${args_help_option}${args_names[$option]}${args_help_reset}"
    if [ -n "${args_option_has_arg[$option]}" ]; then
      text+=" ${args_help_arg}<${args_option_has_arg[$option]}>${args_help_reset}"
    fi
    left+=("$text")
    local desc="${args_descriptions[$option]}"
    if [ -z "$desc" ]; then
      desc="${args_help_italic}no description available${args_help_reset}"
    fi
    right+=("$desc")
  done
  for option in "${!args_names[@]}"; do
    if [[ "$option" != "--"* ]]; then continue; fi
    local text="  ${args_help_bold}${args_help_option}${args_names[$option]}${args_help_reset}"
    if [ -n "${args_option_has_arg[$option]}" ]; then
      text+=" ${args_help_arg}<${args_option_has_arg[$option]}>${args_help_reset}"
    fi
    left+=("$text")
    local desc="${args_descriptions[$option]}"
    if [ -z "$desc" ]; then
      desc="${args_help_italic}no description available${args_help_reset}"
    fi
    right+=("$desc")
  done

  local option_length="${#left[@]}"

  for command in "${!args_names[@]}"; do
    if [[ "$command" == "-"* ]]; then continue; fi
    local text="  ${args_help_bold}${args_help_command}${args_names[$command]}${args_help_reset}"
    if [ -n "${args_option_has_arg[$command]}" ]; then
      text+=" ${args_help_arg}<${args_option_has_arg[$command]}>${args_help_reset}"
    fi
    left+=("$text")
    local desc="${args_descriptions[$command]}"
    if [ -z "$desc" ]; then
      desc="${args_help_italic}no description available${args_help_reset}"
    fi
    right+=("$desc")
  done

  local command_length="${#left[@]}"

  local left_length=0
  for ((i=0; i<command_length; ++i)); do
    local line_length="$(ansi::length "${left[$i]}")"
    if [[ "$left_length" -lt "$line_length" ]]; then
      left_length="$line_length"
    fi
  done
  for ((i=0; i<command_length; ++i)); do
    left[$i]="$(string::pad "${left[$i]}" $left_length left)"
  done

  if [[ "$option_length" -gt 0 ]]; then
    echo
    ansi::out "${args_help_section}Options:${args_help_reset}"
    for ((i=0; i<option_length; ++i)); do
      local option_text="${left[$i]}"
      local option_desc="${right[$i]}"
      ansi::out "${option_text}    ${option_desc}"
    done
  fi

  if [[ "$command_length" -gt "$option_length" ]]; then
    echo
    ansi::out "${args_help_section}Commands:${args_help_reset}"
    for ((i=option_length; i<command_length; ++i)); do
      local command_text="${left[$i]}"
      local command_desc="${right[$i]}"
      ansi::out "${command_text}    ${command_desc}"
    done
  fi

  if [ -n "$args_program_footer" ]; then
    echo
    ansi::out "${args_program_footer}"
  elif [ -n "$args_program_url" ]; then
    echo
    ansi::out "For more information visit: $(ansi::hyperlink "$args_program_url")"
  fi

  exit 0
}

args::option::h() {
  args::option::help
}
