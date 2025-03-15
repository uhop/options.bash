#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

. ./options.bash

define_program "test" "1.0" "Test program"

define_command "test, t" "Test command"
define_command "cmd" "Sample command"

define_command "-v, --version" "Show version"
define_command "-h, --help" "Show help"
define_command "--option" "Sample long option" arg
define_command "-o" "Sample short option" arg

# show_help

# echo ""
# show_version

parse_options "$@"

for option in "${!__options_bash[@]}"; do
  echo "$option: ${__options_bash[$option]}"
done

echo ""
echo "__options_bash_args: ${__options_bash_args}"

declare -n opt=__options_bash
echo ""
echo "--options: ${opt["--option"]}"
