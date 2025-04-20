#!/usr/bin/env bash

# ANSI_NO_SIMPLE_COMMAND_NAMES=1
source "$(dirname "$(realpath "$0")")/../../ansi-tput.sh"
# eval "$(ansi::style::alias_simple_command_names)"

name="$(terminal_name)"

echo "${RED}Red${FG_BG_RESET}"
echo "${GREEN}Green${FG_BG_RESET}"
echo "${BLUE}Blue${FG_BG_RESET}"
echo "${BOLD}${ITALIC}$(fg_true 0 128 64)$(bg_true 255 255 128) ${name} ${RESET_ALL}"
