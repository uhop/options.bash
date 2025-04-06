#!/usr/bin/env bash

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

args_program_name=""
args_program_version=""
args_program_description=""
args_program_url=""
args_program_usage=""
args_program_header=""
args_program_footer=""

declare -A args_names
declare -A args_descriptions
declare -A args_option_has_arg
declare -A args_aliases
declare -a args_immediate_options=("-h" "--help" "-v" "--version")
args_check_command=1

declare -A args_options
args_cleaned=""
args_command=""

args::program() {
  # name version description
  args_program_name="$1"
  args_program_version="$2"
  args_program_description="${3:-}"
  args_program_url="${4:-}"
}

args::option() {
  # names description has_arg
  # has_arg: "" - no argument
  # has_arg: "arg" - required argument, where "arg" is the name of the argument

  local names
  IFS=', ' read -ra names <<< "$1"
  args_names["${names[0]}"]="$1"
  args_descriptions["${names[0]}"]="${2:-}"
  args_option_has_arg["${names[0]}"]="${3:-}"

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

args::try_help() {
  if [[ -v args_options["--help"] ]]; then
    echo "Try '${args_program_name} --help' for more information."
  elif [[ -v args_options["-h"] ]]; then
    echo "Try '${args_program_name} -h' for more information."
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
      if [[ -n "${args_option_has_arg[$command]}" ]]; then long_options+=":"; fi
    elif [[ "$option" == "-"* ]]; then
      short_options+="${option#-}"
      if [[ -n "${args_option_has_arg[$command]}" ]]; then short_options+=":"; fi
    fi
  done

  local parsed
  local status=0
  parsed=$(getopt -o "$short_options" -l "$long_options" -n "${args_program_name}" -- "$@") || status=$?

  if [[ $status -ne 0 ]]; then
    if type -t "args::error::getops" &> /dev/null; then
      args::error::getops
    else
      echo "Error: getopt cannot parse options"
      args::try_help
    fi
    exit 1
  fi

  eval set -- "$parsed"
  while true; do
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
    if [[ -n "${args_option_has_arg[$option]}" ]]; then
      args_options["$option"]="$1"
      shift
    else
      args_options["$option"]=""
    fi
  done

  args_cleaned="$@"

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
    if [ "$#" -eq 0 ]; then
      if type -t "args::error::no_command" &> /dev/null; then
        args::error::no_command
      else
        echo "Error: No command specified"
        args::try_help
      fi
      exit 1
    fi
    local unknown_command=0
    for command in "${!args_aliases[@]}"; do
      if [[ "$command" == "-"* ]]; then continue; fi
      if [[ "$command" == "$1" ]]; then
        unknown_command=1
        break
      fi
    done
    if [[ $unknown_command -eq 0 ]]; then
      if type -t "args::error::unknown_command" &> /dev/null; then
        args::error::unknown_command "$1"
      else
        echo "Error: Unknown command '$1'"
        args::try_help
      fi
      exit 1
    else
      args_command="${args_aliases[$1]}"
    fi
  fi
}
