#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

args::option::help() {
  echo "got help"
  exit 0
}

args::option::h() {
  args::option::help
}
