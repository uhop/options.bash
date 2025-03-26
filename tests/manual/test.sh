#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

source ../../options.sh

define_program "test" "1.0" "Test program"

define_command "test, t" "Test command"
define_command "cmd" "Sample command"

define_command "-v, --version" "Show version"
define_command "-h, --help" "Show help"
define_command "--option" "Sample long option" arg
define_command "-o" "Sample short option" arg

# define_command "--args, -, -args" "Bad short option"
# define_command "--, -z" "Bad long option"

# show_help

# echo ""
# show_version

parse_options "$@"
eval set -- "${__options_bash_args}"

echo "Current arguments: $@"
echo "Current command: ${__options_bash_command}"

echo "Current options:"
for option in "${!__options_bash[@]}"; do
  echo "  $option: ${__options_bash[$option]}"
done

declare -n opt=__options_bash
if [[ -v opt["--option"] ]]; then
  echo "--option: ${opt["--option"]}"
fi
