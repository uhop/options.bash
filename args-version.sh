#!/usr/bin/env bash

if type args::option::version > /dev/null 2>&1; then return; fi

set -euo pipefail

args::option::version() {
  echo -e "${args_program_name} ${args_program_version}"
  exit 0
}

args::option::v() {
  args::option::version
}
