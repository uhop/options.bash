#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

if [[ -z "$(command -v getopt)" ]]; then
  echo "getopt is not installed. Please install it and try again."
  exit 1
fi

getopt --test > /dev/null && true
if [[ $? -ne 4 ]]; then
  echo "I'm sorry, \"getopt --test\" has failed in this environment."
  echo "Please install the newer version of getopt and try again."
  exit 1
fi

__options_bash_skip_help=false
__options_bash_skip_version=false

__options_bash_program_name=""
__options_bash_program_version=""
__options_bash_program_description=""

declare -A __options_bash_command_names
declare -A __options_bash_command_descriptions
declare -A __options_bash_command_has_arg
declare -A __options_bash_command_aliases

declare -A __options_bash
__options_bash_args=""

define_program() {
  # name version description
  __options_bash_program_name="$1"
  __options_bash_program_version="$2"
  __options_bash_program_description="$3"
}

define_command() {
  # names description has_arg
  # has_arg: "" - no argument
  # has_arg: "arg" - required argument

  local names
  IFS=', ' read -ra names <<< "$1"
  __options_bash_command_names["${names[0]}"]="$1"
  __options_bash_command_descriptions["${names[0]}"]="${2:-}"
  __options_bash_command_has_arg["${names[0]}"]="${3:-}"

  for name in "${names[@]}"; do
    __options_bash_command_aliases["$name"]="${names[0]}"
  done
}

parse_options() {
  local long_options=""
  local short_options=""

  for option in "${!__options_bash_command_aliases[@]}"; do
    local command="${__options_bash_command_aliases[$option]}"
    if [[ "$option" == "--"* ]]; then
      if [[ -n "$long_options" ]]; then long_options+=","; fi
      long_options+="${option#--}"
      if [[ "${__options_bash_command_has_arg[$command]}" == "arg" ]]; then long_options+=":"; fi
    elif [[ "$option" == "-"* ]]; then
      short_options+="${option#-}"
      if [[ "${__options_bash_command_has_arg[$command]}" == "arg" ]]; then short_options+=":"; fi
    fi
  done

  local parsed
  local status=0
  parsed=$(getopt -o "$short_options" -l "$long_options" -n "${__options_bash_program_name}" -- "$@") || status=$?
  
  if [[ $status -ne 0 ]]; then
    echo "Try '${__options_bash_program_name} --help' for more information."
    exit 2
  fi

  eval set -- "$parsed"
  while true; do
    if [[ "$1" == "--" ]]; then
      shift
      break
    fi
    local option="${__options_bash_command_aliases["$1"]}"
    if [[ -z "$option" ]]; then
      echo "Error: Unknown option '$1'"
      echo "Try '${__options_bash_program_name} --help' for more information."
      exit 2
    fi
    shift
    if [[ "${__options_bash_command_has_arg[$option]}" == "arg" ]]; then
      __options_bash["$option"]="$1"
      shift
    else
      __options_bash["$option"]=""
    fi
  done

  __options_bash_args="$@"
}

show_help() {
  echo "${__options_bash_program_name} ${__options_bash_program_version}"
  echo "${__options_bash_program_description}"
  echo ""
  echo "Usage: ${__options_bash_program_name} [options] [command] [command options]"
  echo ""
  echo "Options:"
  for option in "${!__options_bash_command_names[@]}"; do
    if [[ "$option" == "--"* ]]; then continue; fi
    if [[ "$option" != "-"* ]]; then continue; fi
    echo "  ${__options_bash_command_names[$option]}"
  done
  for option in "${!__options_bash_command_names[@]}"; do
    if [[ "$option" != "--"* ]]; then continue; fi
    echo "  ${__options_bash_command_names[$option]}"
  done
  echo ""
  echo "Commands:"
  for command in "${!__options_bash_command_names[@]}"; do
    if [[ "$command" == "-"* ]]; then continue; fi
    echo "  ${__options_bash_command_names[$command]}"
  done
}

show_version() {
  echo "${__options_bash_program_name} ${__options_bash_program_version}"
}
