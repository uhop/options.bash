#!/usr/bin/env bash

set -o errexit -o pipefail -o nounset -o noclobber

names=()
input=''
while true; do
  if [[ $# -eq 0 ]]; then break; fi
  arg="$1"
  shift
  echo "Arg: $arg"
  names+=("$arg")
  input+="${arg}\nlongname\n"
done

delimiter="$(tput longname)"
replacement=$'\x01'  # A non-printing character (you can use others)

output="$(tput -S <<< $(echo -e "$input"))"

# Escape the backslashes in the string for proper replacement
escaped_string="${output//'\\'/'\\\\'}"

# Replace delimiter with a single character that's not in the string
modified_string="${escaped_string//$delimiter/$replacement}"

set +e
IFS="$replacement" read -rd '' -a array <<< "$modified_string"
set -e

# Output the resulting array
for i in "${!names[@]}"; do
  echo "${names[$i]}: ${array[$i]@Q}"
done
