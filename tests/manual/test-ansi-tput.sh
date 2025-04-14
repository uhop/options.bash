#!/usr/bin/env bash

source "$(dirname "$(realpath "$0")")/../../ansi-tput.sh"

echo "${RED}Red${RESET_ALL}"
echo "${GREEN}Green${RESET_ALL}"
echo "${BLUE}Blue${RESET_ALL}"
echo "${BOLD}${ITALIC}${CYAN}${BG_BRIGHT_YELLOW}Bold${RESET_ALL}"
