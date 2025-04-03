#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

args::option::version() {
  echo "got version"
  exit 0
}

args::option::v() {
  args::option::version
}
