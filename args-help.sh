#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

args::option::help() {
  echo "${args_program_name} ${args_program_version}"
  echo "${args_program_description}"
  echo ""
  echo "Usage: ${args_program_name} [options] [command] [command options]"
  echo ""
  echo "Options:"
  for option in "${!args_names[@]}"; do
    if [[ "$option" == "--"* ]]; then continue; fi
    if [[ "$option" != "-"* ]]; then continue; fi
    echo "  ${args_names[$option]}"
  done
  for option in "${!args_names[@]}"; do
    if [[ "$option" != "--"* ]]; then continue; fi
    echo "  ${args_names[$option]}"
  done
  echo ""
  echo "Commands:"
  for command in "${!args_names[@]}"; do
    if [[ "$command" == "-"* ]]; then continue; fi
    echo "  ${args_names[$command]}"
  done
  exit 0
}

args::option::h() {
  args::option::help
}
