#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
source "$script_dir/../test.sh"
source "$test_lib_dir/args.sh"

echo "args.sh"

# args::program

args::program "test-tool" "1.0.0" "A test tool"
test::equal "$args_program_name" "test-tool" "program: name"
test::equal "$args_program_version" "1.0.0" "program: version"
test::equal "$args_program_description" "A test tool" "program: description"

# args::program with URL

args::program "test-tool" "2.0" "Desc" "https://example.com"
test::equal "$args_program_url" "https://example.com" "program: url"

# args::option — register options

args::option "-v, --version" "Show version"
args::option "-h, --help" "Show help"
args::option "--output, -o" "Output file" "file"
args::option "--flag" "A flag"
args::option "--optional-arg" "Optional argument" "val" "optional"

test::equal "${args_descriptions["-v"]}" "Show version" "option: description stored"
test::equal "${args_aliases["--version"]}" "-v" "option: alias --version -> -v"
test::equal "${args_aliases["-v"]}" "-v" "option: alias -v -> -v"
test::equal "${args_option_has_arg["--output"]}" "file" "option: has_arg"
test::equal "${args_option_arg_optional["--output"]}" "" "option: arg not optional"
test::not_equal "${args_option_arg_optional["--optional-arg"]}" "" "option: arg is optional"

# args::option — register commands

args::option "build" "Build the project"
args::option "test, t" "Run tests"

test::equal "${args_aliases["build"]}" "build" "option: command alias"
test::equal "${args_aliases["t"]}" "test" "option: command alias t -> test"

# args::parse — basic flag

args_options=()
args_command=""
args_cleaned=""
args::parse --flag build
test::equal "${args_options["--flag"]}" "" "parse: flag present"
test::equal "$args_command" "build" "parse: command detected"

# args::parse — option with required argument

args_options=()
args_command=""
args_cleaned=""
args::parse --output=myfile.txt build
test::equal "${args_options["--output"]}" "myfile.txt" "parse: required arg value"
test::equal "$args_command" "build" "parse: command after option"

# args::parse — short option

args_options=()
args_command=""
args_cleaned=""
args::parse -o myfile.txt build
test::equal "${args_options["--output"]}" "myfile.txt" "parse: short option -o"

# args::parse — multiple options

args_options=()
args_command=""
args_cleaned=""
args::parse --flag -o out.txt test
test::equal "${args_options["--flag"]}" "" "parse: multi flag"
test::equal "${args_options["--output"]}" "out.txt" "parse: multi output"
test::equal "$args_command" "test" "parse: multi command"

# args::parse — command alias

args_options=()
args_command=""
args_cleaned=""
args::parse t
test::equal "$args_command" "test" "parse: command alias t"

# args::parse — positional arguments after command

args_options=()
args_command=""
args_cleaned=""
args::parse build foo bar
test::contains "$args_cleaned" "foo" "parse: positional arg foo"
test::contains "$args_cleaned" "bar" "parse: positional arg bar"

test::done
