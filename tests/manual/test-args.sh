#!/usr/bin/env bash

set -euo pipefail

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

args::option "cmd" "Sample command
Sample description"
args::option "test, t" "Test command" "a b"

args::option "--optional" "Sample long option\nwith two lines" arg optional
args::option "--required" "Sample long option\nwith two lines" arg
args::option "-o" "Sample short option with optional argument" arg optional
args::option "-x" "Sample short option with required argument" arg
args::option "-v, --version" "$(box::make_lines "Show version," "in a fancy way")"
args::option "-h, --help" "Show help"
args::option "--long" "Some long option"
args::option "-s, --short" "Sample option"
args::option "-z, --zoom" "Sample option with argument" arg optional

# args::option "--args, -, -args" "Bad short option"
# args::option "--, -z" "Bad long option"

echo "Original arguments ($#): $@"
for arg in "$@"; do
    echo "  ${arg}"
done

args::parse "$@"
eval set -- "${args_cleaned}"

echo "Current arguments ($#): $@"
for arg in "$@"; do
    echo "  ${arg}"
done
echo "Current command: ${args_command}"

echo "Current options:"
for option in "${!args_options[@]}"; do
  echo "  ${option}: ${args_options[$option]}"
done
echo "No more options"

declare -n opt=args_options
if [[ -v opt["--optional"] ]]; then
  echo "--optional: ${opt["--optional"]}"
fi
if [[ -v opt["--required"] ]]; then
  echo "--required: ${opt["--required"]}"
fi
