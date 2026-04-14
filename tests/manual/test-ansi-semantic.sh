#!/usr/bin/env bash

source "$(dirname "$(realpath "$0")")/../../ansi-semantic.sh"

echo "=== Semantic colors ==="
ansi::out "${ERROR} ERROR ${RESET_ALL} This is an error message"
ansi::out "${WARN} WARN ${RESET_ALL} This is a warning message"
ansi::out "${INFO}Info:${RESET_ALL} This is an info message"
ansi::out "${OK}OK:${RESET_ALL} This is a success message"

echo ""
echo "=== Prefixed forms (SEMANTIC_*) ==="
ansi::out "${SEMANTIC_ERROR} ERROR ${RESET_ALL} Using SEMANTIC_ERROR"
ansi::out "${SEMANTIC_WARN} WARN ${RESET_ALL} Using SEMANTIC_WARN"
ansi::out "${SEMANTIC_INFO}Info:${RESET_ALL} Using SEMANTIC_INFO"
ansi::out "${SEMANTIC_OK}OK:${RESET_ALL} Using SEMANTIC_OK"

echo ""
echo "=== Inline with text ==="
ansi::out "Status: ${OK}PASSED${RESET_ALL} — all checks complete"
ansi::out "Status: ${ERROR}FAILED${RESET_ALL} — 3 errors found"
ansi::out "${WARN} NOTE ${RESET_ALL} ${INFO}Retry in 5 seconds${RESET_ALL}"
