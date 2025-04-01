#!/usr/bin/env bash

# ANSI_NO_DEFAULT_COMMANDS=1
source "$(dirname "$(realpath "$0")")/../../ansi-style.sh"
source "$(dirname "$(realpath "$0")")/../../ansi-control.sh"
# eval "$(ansi::define_commands)"

ansi::out "${RED}Red${RESET_ALL}"
ansi::out "${GREEN}Green${RESET_ALL}"
ansi::out "${BLUE}Blue${RESET_ALL}"
ansi::out "$(ansi::style::make \
  bold italic \
  "$(ansi::c256::fg_true 0 128 64)" \
  "$(ansi::c256::bg_true 255 255 128)")Bold$(ansi::style::make reset_all)"

# echo -en "$(ansi::screen::scroll_up 3)$(ansi::screen::scroll_down 2)"
