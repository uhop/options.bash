#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"
source "$script_dir/../test.sh"

echo "args-help.sh"

# Helper: capture help output (args::option::help calls exit, so run in subshell)
_capture_help() {
  bash -c '
    set -euo pipefail
    source "'"$script_dir"'/../args.sh"
    source "'"$script_dir"'/../args-help.sh"
    '"$1"'
    args::option "-h, --help" "Show help"
    args::parse -h
  ' 2>&1 || true
}

# help: footer only

output=$(_capture_help '
  args::program "tool" "1.0" "Desc"
  args_program_footer="My footer"
')
test::contains "$output" "My footer" "help: footer shown"

# help: URL only

output=$(_capture_help '
  args::program "tool" "1.0" "Desc" "https://example.com"
')
test::contains "$output" "https://example.com" "help: URL shown"

# help: both footer and URL

output=$(_capture_help '
  args::program "tool" "1.0" "Desc" "https://example.com"
  args_program_footer="My footer"
')
test::contains "$output" "My footer" "help: footer shown when both set"
test::contains "$output" "https://example.com" "help: URL shown when both set"

# help: neither footer nor URL

output=$(_capture_help '
  args::program "tool" "1.0" "Desc"
')
# Should not contain "For more information" since no URL is set
lines=$(echo "$output" | grep -c "For more information" || true)
test::equal "$lines" "0" "help: no URL line when URL not set"

# help: default command annotation

output=$(_capture_help '
  args::program "tool" "1.0" "Desc"
  args_program_default_command="edit"
  args::option "edit" "Edit stuff"
  args::option "list" "List stuff"
')
test::contains "$output" "(default)" "help: default command annotated"
test::contains "$output" "[command]" "help: usage shows optional command"

# help: no annotation without default

output=$(_capture_help '
  args::program "tool" "1.0" "Desc"
  args::option "edit" "Edit stuff"
  args::option "list" "List stuff"
')
lines=$(echo "$output" | grep -c "(default)" || true)
test::equal "$lines" "0" "help: no annotation without default_command"

test::done
