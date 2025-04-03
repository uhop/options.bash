#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

args::version() {
  echo "got version"
  exit 0
}

args::v() {
  args::version
}
