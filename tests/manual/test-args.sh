#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

script_dir="$(dirname "$(readlink -f "$0")")"
script_name=$(basename "$0")

source "$script_dir/../../args.sh"
source "$script_dir/../../args-help.sh"
source "$script_dir/../../args-version.sh"
source "$script_dir/../../box.sh"

args::program "$script_name" "1.0" "Test program"
# args_program_usage="$(box::make "usage example 1" "usage example 2" "usage example 3")"
# args_program_header="Some fancyful\ndescription"
# args_program_footer="Some footer"
# args_program_help_style="list"
# args_program_required_command="no"

args::option "test, t" "Test command" "a b"
args::option "cmd" "Sample command
Sample description"

args::option "-v, --version" "$(box::make_lines "Show version," "in a fancy way")"
args::option "-h, --help" "Show help"
args::option "--option" "Sample long option" arg
args::option "-o" "Sample short option" arg

# args::option "--args, -, -args" "Bad short option"
# args::option "--, -z" "Bad long option"

args::parse "$@"
eval set -- "${args_cleaned}"

echo "Current arguments: $@"
echo "Current command: ${args_command}"

echo "Current options:"
for option in "${!args_options[@]}"; do
  echo "  ${option}: ${args_options[$option]}"
done

declare -n opt=args_options
if [[ -v opt["--option"] ]]; then
  echo "--option: ${opt["--option"]}"
fi
