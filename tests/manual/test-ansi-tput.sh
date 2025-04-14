#!/usr/bin/env bash

source "$(dirname "$(realpath "$0")")/../../ansi-tput.sh"

name="$(terminal_name)"

echo "${RED}Red${FG_BG_RESET}"
echo "${GREEN}Green${FG_BG_RESET}"
echo "${BLUE}Blue${FG_BG_RESET}"
echo "${BOLD}${ITALIC}$(fg_true 0 128 64)$(bg_true 255 255 128) ${name} ${FG_BG_RESET}${RESET_ALL}"
