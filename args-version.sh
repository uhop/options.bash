#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

args::option::version() {
  echo -e "${args_program_name} ${args_program_version}"
  exit 0
}

args::option::v() {
  args::option::version
}
