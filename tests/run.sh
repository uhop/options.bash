#!/usr/bin/env bash

set -euo pipefail

script_dir="$(dirname "$(realpath "$0")")"

total_pass=0
total_fail=0
total_files=0
failed_files=()

for test_file in "$script_dir"/test-*.sh; do
  if [[ ! -f "$test_file" ]]; then continue; fi
  total_files=$((total_files + 1))
  name=$(basename "$test_file")
  echo ""
  echo "--- ${name} ---"
  set +e
  bash "$test_file"
  status=$?
  set -e
  if [[ $status -ne 0 ]]; then
    failed_files+=("$name")
  fi
done

echo ""
echo "==============================="
echo "Ran ${total_files} test files."
if [[ "${#failed_files[@]}" -eq 0 ]]; then
  echo "All passed."
  exit 0
else
  echo "Failed: ${failed_files[*]}"
  exit 1
fi
