#!/usr/bin/env bash

if type args::program > /dev/null 2>&1; then return; fi

set -euo pipefail

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

# Help section
args_program_name=""
args_program_version=""
args_program_description=""
args_program_url=""
args_program_usage=""
args_program_header=""
args_program_footer=""
args_program_required_command="yes"
args_program_help_style="grid" # grid, list

# Internal data structures
declare -a args_list
declare -A args_names
declare -A args_descriptions
declare -A args_option_has_arg
declare -A args_option_arg_optional
declare -A args_aliases
declare -a args_immediate_options=("-h" "--help" "-v" "--version" "--bash-completion")
args_check_command=1

declare -a args_on_options=()
declare -a args_on_parse=()

# External data structures
declare -A args_options
args_cleaned=()
args_command=""

args::program() {
  # name version description
  args_program_name="$1"
  args_program_version="$2"
  args_program_description="${3:-}"
  args_program_url="${4:-}"
}

args::option() {
  # names description has_arg arg_optional
  # has_arg: "" - no argument
  # has_arg: "arg" - argument, where "arg" is the name of the argument
  # arg_optional: "" - required argument
  # arg_optional: "opt" - optional argument, where "opt" is a non-empty string

  local names
  IFS=', ' read -ra names <<< "$1"
  args_names["${names[0]}"]="$1"
  args_list+=("${names[0]}")
  args_descriptions["${names[0]}"]="${2:-}"
  args_option_has_arg["${names[0]}"]="${3:-}"
  args_option_arg_optional["${names[0]}"]="${4:-}"

  for name in "${names[@]}"; do
    if [[ "$name" == "--"* ]]; then
      if [[ "$name" == "--" ]]; then
        if type -t "args::error::invalid_long_option" &> /dev/null; then
          args::error::invalid_long_option "$name"
        else
          echo "Error: Invalid long option '$name'"
        fi
        exit 1
      fi
    elif [[ "$name" == "-"* ]]; then
      if [[ ! "$name" =~ ^-[a-zA-Z0-9]$ ]]; then
        if type -t "args::error::invalid_short_option" &> /dev/null; then
          args::error::invalid_short_option "$name"
        else
          echo "Error: Invalid short option '$name'"
        fi
        exit 1
      fi
    else
      args_check_command=0
    fi
    args_aliases["$name"]="${names[0]}"
  done
}

args::immediate() {
  args_immediate_options+=("$@")
}

args::on_options() {
  args_on_options+=("$1")
}

args::on_parse() {
  args_on_parse+=("$1")
}

args::try_help() {
  if [[ -v args_aliases["--help"] ]]; then
    echo "Try '${args_program_name} --help' for more information."
  elif [[ -v args_aliases["-h"] ]]; then
    echo "Try '${args_program_name} -h' for more information."
  elif [ -n "$args_program_url" ]; then
    ansi::out "Visit $(ansi::hyperlink "$args_program_url") for more information."
  fi
}

args::parse() {
  local long_options=""
  local short_options=""

  for option in "${!args_aliases[@]}"; do
    local command="${args_aliases[$option]}"
    if [[ "$option" == "--"* ]]; then
      if [[ -n "$long_options" ]]; then long_options+=","; fi
      long_options+="${option#--}"
      if [[ -n "${args_option_has_arg[$command]}" ]]; then
        if [[ -z "${args_option_arg_optional[$command]}" ]]; then
          long_options+=":"
        else
          long_options+="::"
        fi
      fi
    elif [[ "$option" == "-"* ]]; then
      short_options+="${option#-}"
      if [[ -n "${args_option_has_arg[$command]}" ]]; then
        if [[ -z "${args_option_arg_optional[$command]}" ]]; then
          short_options+=":"
        else
          short_options+="::"
        fi
      fi
    fi
  done

  local escaped_args=()
  for arg in "$@"; do
    if [[ "${arg}" == -* ]]; then
      escaped_args+=("${arg}")
    else
      escaped_args+=("$(printf '%q' "${arg}")")
    fi
  done

  local parsed
  local status=0
  parsed=$(getopt -o "${short_options}" -l "${long_options}" -n "${args_program_name}" -- "${escaped_args[@]}") || status=$?

  if [[ $status -ne 0 ]]; then
    if type -t "args::error::getopt" &> /dev/null; then
      args::error::getopt
    else
      echo "Error: getopt cannot parse options"
      args::try_help
    fi
    exit 1
  fi

  eval set -- "$parsed"

  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--" ]]; then
      shift
      break
    fi
    local option="${args_aliases["$1"]}"
    if [[ -z "$option" ]]; then
      if type -t "args::error::unknown_option" &> /dev/null; then
        args::error::unknown_option "$1"
      else
        echo "Error: Unknown option '$1'"
        args::try_help
      fi
      exit 1
    fi
    shift
    args_options["$option"]=""
    if [[ -n "${args_option_has_arg[$option]}" ]]; then
      args_options["$option"]="$1"
      shift
    fi
  done

  args_cleaned=("$@")

  for _args_hook in "${args_on_options[@]+"${args_on_options[@]}"}"; do
    "$_args_hook"
  done

  if [[ "${#args_immediate_options[@]}" -gt 0 ]]; then
    for option in "${args_immediate_options[@]}"; do
      if [[ -v args_options["$option"] ]]; then
        local name="${option##*-}"
        if type -t "args::option::$name" &> /dev/null; then
          "args::option::$name"
        fi
      fi
    done
  fi

  if [[ ${args_check_command} -eq 0 ]]; then
    if [ "$#" -eq 0 ] && [[ ${args_program_required_command} == "yes" ]]; then
      if type -t "args::error::no_command" &> /dev/null; then
        args::error::no_command
      else
        echo "Error: No command specified"
        args::try_help
      fi
      exit 1
    fi
    local command_found=0
    local current_command="${1:-}"
    for command in "${!args_aliases[@]}"; do
      if [[ "$command" == "-"* ]]; then continue; fi
      if [[ "$command" == "$current_command" ]]; then
        command_found=1
        break
      fi
    done
    if [[ $command_found -eq 0 ]]; then
      if  [[ ${args_program_required_command} == "yes" ]]; then
        if type -t "args::error::unknown_command" &> /dev/null; then
          args::error::unknown_command "$current_command"
        else
          echo "Error: Unknown command '$current_command'"
          args::try_help
        fi
        exit 1
      fi
    else
      args_command="${args_aliases[$current_command]}"
    fi
  fi

  for _args_hook in "${args_on_parse[@]+"${args_on_parse[@]}"}"; do
    "$_args_hook"
  done
}
