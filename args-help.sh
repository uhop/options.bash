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

args_help_bold="$(ansi::get bold)"
args_help_italic="$(ansi::get italic)"
args_help_reset="$(ansi::get reset_all)"

TEMP_CYAN="$(ansi::get cyan)"

args_help_section="${args_help_bold}$(ansi::get green)"
args_help_program="${args_help_bold}${TEMP_CYAN}"
args_help_version="${TEMP_CYAN}"
args_help_command="$(ansi::get magenta)"
args_help_command_arg="${args_help_italic}${args_help_command}"
args_help_option="${TEMP_CYAN}"
args_help_option_arg="${args_help_italic}${args_help_option}"

unset TEMP_CYAN

args::option::help() {
  ansi::out "${args_help_program}${args_program_name}${args_help_reset} " \
    "${args_help_version}${args_program_version}${args_help_reset} " \
    "${args_program_description}"

  if [ -n "$args_program_header" ]; then
    echo
    ansi::out "${args_program_header}"
  fi

  local -a left=()
  local -a right=()

  for option in "${args_list[@]}"; do
    if [[ "$option" == "--"* ]]; then continue; fi
    if [[ "$option" != "-"* ]]; then continue; fi
    local text="  ${args_help_bold}${args_help_option}${args_names[$option]}${args_help_reset}"
    if [ -n "${args_option_has_arg[$option]}" ]; then
      text+=" ${args_help_option_arg}<${args_option_has_arg[$option]}>${args_help_reset}"
    fi
    left+=("$text")
    local desc="${args_descriptions[$option]}"
    if [ -z "$desc" ]; then
      desc="${args_help_italic}no description available${args_help_reset}"
    fi
    right+=("$desc")
  done
  for option in "${args_list[@]}"; do
    if [[ "$option" != "--"* ]]; then continue; fi
    local text="  ${args_help_bold}${args_help_option}${args_names[$option]}${args_help_reset}"
    if [ -n "${args_option_has_arg[$option]}" ]; then
      text+=" ${args_help_option_arg}<${args_option_has_arg[$option]}>${args_help_reset}"
    fi
    left+=("$text")
    local desc="${args_descriptions[$option]}"
    if [ -z "$desc" ]; then
      desc="${args_help_italic}no description available${args_help_reset}"
    fi
    right+=("$desc")
  done

  local option_length="${#left[@]}"

  for command in "${args_list[@]}"; do
    if [[ "$command" == "-"* ]]; then continue; fi
    local text="  ${args_help_bold}${args_help_command}${args_names[$command]}${args_help_reset}"
    if [ -n "${args_option_has_arg[$command]}" ]; then
      text+=" ${args_help_command_arg}<${args_option_has_arg[$command]}>${args_help_reset}"
    fi
    left+=("$text")
    local desc="${args_descriptions[$command]}"
    if [ -z "$desc" ]; then
      desc="${args_help_italic}no description available${args_help_reset}"
    fi
    right+=("$desc")
  done

  local command_length="${#left[@]}"

  echo
  ansi::out "${args_help_section}Usage:${args_help_reset}"
  if [ -z "$args_program_usage" ]; then
    local text="  ${args_help_program}${args_program_name}${args_help_reset}"
    if [[ "$option_length" -gt 0 ]]; then
      text+=" ${args_help_option}[options]${args_help_reset}"
    fi
    if [[ "$command_length" -gt "$option_length" ]]; then
      if [[ "$args_program_required_command" == "yes" ]]; then
        text+=" ${args_help_command}command${args_help_reset} ${args_help_command_arg}[command arguments]${args_help_reset}"
      else
        text+=" ${args_help_command}[command]${args_help_reset} ${args_help_command_arg}[command arguments]${args_help_reset}"
      fi
    else
      text+=" ${args_help_command_arg}[script arguments]${args_help_reset}"
    fi
    ansi::out "$text"
  else
    ansi::out "$(box::exec "${args_program_usage}" pad_lr 2 0)"
  fi

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
      if [[ "$args_program_help_style" == "list" ]]; then
        ansi::out "${option_text}"
        ansi::out "$(box::exec "${option_desc}" pad_lr 4 0)"
      else
        local height="$(box::get_height "${option_desc}")"
        if [[ "$height" -gt 1 ]]; then
          option_text="$(box::exec "${option_text}" pad_lr 0 4 pad_tb 0 $((height - 1)))"
          local text="$(box::stack_lr "${option_text}" "${option_desc}")"
          ansi::out "$text"
        else
          ansi::out "${option_text}    ${option_desc}"
        fi
      fi
    done
  fi

  if [[ "$command_length" -gt "$option_length" ]]; then
    echo
    ansi::out "${args_help_section}Commands:${args_help_reset}"
    for ((i=option_length; i<command_length; ++i)); do
      local command_text="${left[$i]}"
      local command_desc="${right[$i]}"
      if [[ "$args_program_help_style" == "list" ]]; then
        ansi::out "${command_text}"
        ansi::out "$(box::exec "${command_desc}" pad_lr 4 0)"
      else
        local height="$(box::get_height "${command_desc}")"
        if [[ "$height" -gt 1 ]]; then
          command_text="$(box::exec "${command_text}" pad_lr 0 4 pad_tb 0 $((height - 1)))"
          local text="$(box::stack_lr "${command_text}" "${command_desc}")"
          ansi::out "$text"
        else
          ansi::out "${command_text}    ${command_desc}"
        fi
      fi
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
