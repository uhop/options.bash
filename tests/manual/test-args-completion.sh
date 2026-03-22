#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$(readlink -f "$0")")"
script_name=$(basename "$0")

source "$script_dir/../../args.sh"
source "$script_dir/../../args-completion.sh"
source "$script_dir/../../args-help.sh"
source "$script_dir/../../args-version.sh"

args::program "$script_name" "1.0" "Test completion generation"

args_program_required_command="no"

args::option "build, b" "Build the project"
args::option "test, t" "Run tests" "filter"
args::option "deploy" "Deploy to production"

args::option "--output, -o" "Output file" "file"
args::option "--timeout" "Timeout in seconds" "seconds"
args::option "--color" "Color mode" "when" "optional"
args::option "--verbose" "Verbose output"
args::option "--bash-completion" "Output bash completion script"
args::option "-v, --version" "Show version"
args::option "-h, --help" "Show help"

args::parse "$@"
