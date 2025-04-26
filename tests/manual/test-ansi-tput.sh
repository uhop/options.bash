#!/usr/bin/env bash

# ANSI_NO_SIMPLE_COMMAND_NAMES=1
source "$(dirname "$(realpath "$0")")/../../ansi-tput.sh"
# eval "$(ansi::alias_simple_command_names)"

name="$(ansi::terminal::name)"

echo "${RED}Red${FG_BG_RESET}"
echo "${GREEN}Green${FG_BG_RESET}"
echo "${BLUE}Blue${FG_BG_RESET}"
echo "${BOLD}${ITALIC}$(ansi::fg::true 0 128 64)$(ansi::bg::true 255 255 128) ${name} ${RESET_ALL}"
