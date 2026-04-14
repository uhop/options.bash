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
args_cleaned=()
args::parse --flag build
test::equal "${args_options["--flag"]}" "" "parse: flag present"
test::equal "$args_command" "build" "parse: command detected"

# args::parse — option with required argument

args_options=()
args_command=""
args_cleaned=()
args::parse --output=myfile.txt build
test::equal "${args_options["--output"]}" "myfile.txt" "parse: required arg value"
test::equal "$args_command" "build" "parse: command after option"

# args::parse — short option

args_options=()
args_command=""
args_cleaned=()
args::parse -o myfile.txt build
test::equal "${args_options["--output"]}" "myfile.txt" "parse: short option -o"

# args::parse — multiple options

args_options=()
args_command=""
args_cleaned=()
args::parse --flag -o out.txt test
test::equal "${args_options["--flag"]}" "" "parse: multi flag"
test::equal "${args_options["--output"]}" "out.txt" "parse: multi output"
test::equal "$args_command" "test" "parse: multi command"

# args::parse — command alias

args_options=()
args_command=""
args_cleaned=()
args::parse t
test::equal "$args_command" "test" "parse: command alias t"

# args::parse — positional arguments after command

args_options=()
args_command=""
args_cleaned=()
args::parse build foo bar
test::contains "${args_cleaned[*]}" "foo" "parse: positional arg foo"
test::contains "${args_cleaned[*]}" "bar" "parse: positional arg bar"

# args::parse — positional arguments with spaces

args_options=()
args_command=""
args_cleaned=()
args::parse build "hello world" "foo bar"
test::equal "${args_cleaned[1]}" "hello world" "parse: positional arg with spaces"
test::equal "${args_cleaned[2]}" "foo bar" "parse: second positional arg with spaces"

# args::parse — positional arguments with special chars

args_options=()
args_command=""
args_cleaned=()
args::parse build "it's" '$HOME'
test::equal "${args_cleaned[1]}" "it's" "parse: positional arg with single quote"
test::equal "${args_cleaned[2]}" '$HOME' "parse: positional arg with dollar sign"

# args::parse — option with optional argument

args_options=()
args_command=""
args_cleaned=()
args::parse --optional-arg=myval build
test::equal "${args_options["--optional-arg"]}" "myval" "parse: optional arg with value"

args_options=()
args_command=""
args_cleaned=()
args::parse --optional-arg build
test::equal "${args_options["--optional-arg"]}" "" "parse: optional arg without value"

# args::try_help

result=$(args::try_help)
test::contains "$result" "--help" "try_help: suggests --help"

# args::on_options — hook before immediate dispatch

_test_on_options_called=0
_test_on_options_fn() { _test_on_options_called=1; }
args::on_options _test_on_options_fn

args_options=()
args_command=""
args_cleaned=()
_test_on_options_called=0
args::parse build
test::equal "$_test_on_options_called" "1" "on_options: hook called after parse"

args_options=()
args_command=""
args_cleaned=()
_test_on_options_called=0
args::parse --flag build
test::equal "$_test_on_options_called" "1" "on_options: hook called with flag"

# args::on_parse — hook registration and dispatch

_test_hook_called=0
_test_hook_fn() { _test_hook_called=1; }
args::on_parse _test_hook_fn

args_options=()
args_command=""
args_cleaned=()
_test_hook_called=0
args::parse build
test::equal "$_test_hook_called" "1" "on_parse: hook called after parse"

_test_hook2_called=0
_test_hook2_fn() { _test_hook2_called=1; }
args::on_parse _test_hook2_fn

args_options=()
args_command=""
args_cleaned=()
_test_hook_called=0
_test_hook2_called=0
args::parse build
test::equal "$_test_hook_called" "1" "on_parse: first hook still called"
test::equal "$_test_hook2_called" "1" "on_parse: second hook called"

# args_program_default_command — default command applied when none given

args_program_default_command="build"

args_options=()
args_command=""
args_cleaned=()
args::parse --flag
test::equal "$args_command" "build" "default_command: applied when no command"

args_options=()
args_command=""
args_cleaned=()
args::parse test
test::equal "$args_command" "test" "default_command: explicit command overrides"

args_options=()
args_command=""
args_cleaned=()
args::parse somefile.txt
test::equal "$args_command" "build" "default_command: non-command arg triggers default"
test::equal "${args_cleaned[0]}" "somefile.txt" "default_command: positional arg preserved"

args_options=()
args_command=""
args_cleaned=()
args::parse --flag test extra1 extra2
test::equal "$args_command" "test" "default_command: explicit with extras"
test::contains "${args_cleaned[*]}" "extra1" "default_command: extras preserved"

# reset default for subsequent test safety
args_program_default_command=""

test::done
