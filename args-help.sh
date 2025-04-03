#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

args::help() {
  echo "got help"
  exit 0
}

args::h() {
  args::help
}
