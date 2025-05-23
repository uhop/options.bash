#!/usr/bin/env bash

# ANSI_NO_SIMPLE_COMMAND_NAMES=1
source "$(dirname "$(realpath "$0")")/../../ansi.sh"
# eval "$(ansi::alias_simple_command_names)"

ansi::out "${RED}Red${RESET_ALL}"
ansi::out "${GREEN}Green${RESET_ALL}"
ansi::out "${BLUE}Blue${RESET_ALL}"
ansi::out "$(ansi::make \
  bold italic \
  "$(ansi::fg_true 0 128 64)" \
  "$(ansi::bg_true 255 255 128)") Bold $(ansi::make reset_all)"

# echo -en "$(ansi::screen::scroll_up 3)$(ansi::screen::scroll_down 2)"
