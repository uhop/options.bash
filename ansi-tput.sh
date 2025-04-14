#!/usr/bin/env bash

BLACK="$(tput setaf 0)"
RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
MAGENTA="$(tput setaf 5)"
CYAN="$(tput setaf 6)"
WHITE="$(tput setaf 7)"

BRIGHT_BLACK="$(tput setaf 8)"
BRIGHT_RED="$(tput setaf 9)"
BRIGHT_GREEN="$(tput setaf 10)"
BRIGHT_YELLOW="$(tput setaf 11)"
BRIGHT_BLUE="$(tput setaf 12)"
BRIGHT_MAGENTA="$(tput setaf 13)"
BRIGHT_CYAN="$(tput setaf 14)"
BRIGHT_WHITE="$(tput setaf 15)"

FG_BLACK="$BLACK"
FG_RED="$RED"
FG_GREEN="$GREEN"
FG_YELLOW="$YELLOW"
FG_BLUE="$BLUE"
FG_MAGENTA="$MAGENTA"
FG_CYAN="$CYAN"
FG_WHITE="$WHITE"

FG_BRIGHT_BLACK="$BRIGHT_BLACK"
FG_BRIGHT_RED="$BRIGHT_RED"
FG_BRIGHT_GREEN="$BRIGHT_GREEN"
FG_BRIGHT_YELLOW="$BRIGHT_YELLOW"
FG_BRIGHT_BLUE="$BRIGHT_BLUE"
FG_BRIGHT_MAGENTA="$BRIGHT_MAGENTA"
FG_BRIGHT_CYAN="$BRIGHT_CYAN"
FG_BRIGHT_WHITE="$BRIGHT_WHITE"

BG_BLACK="$(tput setab 0)"
BG_RED="$(tput setab 1)"
BG_GREEN="$(tput setab 2)"
BG_YELLOW="$(tput setab 3)"
BG_BLUE="$(tput setab 4)"
BG_MAGENTA="$(tput setab 5)"
BG_CYAN="$(tput setab 6)"
BG_WHITE="$(tput setab 7)"

BG_BRIGHT_BLACK="$(tput setab 8)"
BG_BRIGHT_RED="$(tput setab 9)"
BG_BRIGHT_GREEN="$(tput setab 10)"
BG_BRIGHT_YELLOW="$(tput setab 11)"
BG_BRIGHT_BLUE="$(tput setab 12)"
BG_BRIGHT_MAGENTA="$(tput setab 13)"
BG_BRIGHT_CYAN="$(tput setab 14)"
BG_BRIGHT_WHITE="$(tput setab 15)"

FG_BG_RESET="$(tput op)"

fg_color() { tput setaf "$1"; }
bg_color() { tput setab "$1"; }

color_code_rgb() {
  local r="$1"
  local g="$2"
  local b="$3"

  local result=0
  if [[ "$r" -ne 0 ]]; then result+=1; fi
  if [[ "$g" -ne 0 ]]; then result+=2; fi
  if [[ "$b" -ne 0 ]]; then result+=4; fi
  echo "$result"
}

color_code_bright() {
  local code="$1"
  echo "$(( $code + 8 ))"
}

color_code_true() {
  local r="$1"
  local g="$2"
  local b="$3"
  echo "$((16 + r * 6 / 256 * 36 + g * 6 / 256 * 6 + b * 6 / 256))"
}

color_code_grey() {
  local intensity="$1"
  echo "$((232 + intensity * 24 / 256))"
}

fg_rgb() { fg_color "$(color_code_rgb "$@")"; }
fg_bright_rgb() { fg_color "$(color_code_bright "$(color_code_rgb "$@")")"; }
fg_true() { fg_color "$(color_code_true "$@")"; }
fg_grey() { fg_color "$(color_code_grey "$@")"; }

bg_rgb() { bg_color "$(color_code_rgb "$@")"; }
bg_bright_rgb() { bg_color "$(color_code_bright "$(color_code_rgb "$@")")"; }
bg_true() { bg_color "$(color_code_true "$@")"; }
bg_grey() { bg_color "$(color_code_grey "$@")"; }

BOLD="$(tput bold)"
DIM="$(tput dim)"
UNDERLINE="$(tput smul)"
RESET_UNDERLINE="$(tput rmul)"
REVERSE="$(tput rev)"
BLINK="$(tput blink)"
INVISIBLE="$(tput invis)"
STANDOUT="$(tput smso)"
RESET_STANDOUT="$(tput rmso)"
ITALIC="$(tput sitm)"
RESET_ITALIC="$(tput ritm)"
STRIKE="$(tput smxx)"
RESET_STRIKE="$(tput rmxx)"
RESET="$(tput sgr0)"
RESET_ALL="${FG_BG_RESET}${RESET}"

# params (bool): standout, underline, reverse, blink, dim, bold, invis, protect, altcharset
sgr() { tput sgr "$@"; }

TEXT_BOLD="$BOLD"
TEXT_DIM="$DIM"
TEXT_UNDERLINE="$UNDERLINE"
TEXT_RESET_UNDERLINE="$RESET_UNDERLINE"
TEXT_REVERSE="$REVERSE"
TEXT_BLINK="$BLINK"
TEXT_INVISIBLE="$INVISIBLE"
TEXT_STANDOUT="$STANDOUT"
TEXT_RESET_STANDOUT="$RESET_STANDOUT"
TEXT_ITALIC="$ITALIC"
TEXT_RESET_ITALIC="$RESET_ITALIC"
TEXT_STRIKE="$STRIKE"
TEXT_RESET_STRIKE="$RESET_STRIKE"
TEXT_RESET_ALL="$RESET_ALL"

text_sgr=$sgr

CURSOR_SAVE="$(tput sc)"
CURSOR_RESTORE="$(tput rc)"
CURSOR_HOME="$(tput home)"
CURSOR_DOWN1="$(tput cud1)"
CURSOR_UP1="$(tput cuu1)"
CURSOR_LEFT1="$(tput cub1)"
CURSOR_RIGHT1="$(tput cuf1)"
CURSOR_INVISIBLE="$(tput civis)"
CURSOR_HIGHLIGHT="$(tput cvvis)"
CURSOR_NORMAL="$(tput cnorm)"
CURSOR_LAST="$(tput ll)"

cursor_pos() { tput cup "$1" "$2"; }
cursor_left() { tput cub "$1"; }
cursor_right() { tput cuf "$1"; }
cursor_insert() { tput ich "$1"; }
cursor_insert_lines() { tput il "$1"; }

SCREEN_SAVE="$(tput smcup)"
SCREEN_RESTORE="$(tput rmcup)"

screen_lines() { tput lines; }
screen_cols() { tput cols; }
screen_colors() { tput colors; }

CLEAR_BOL="$(tput el1)"
CLEAR_EOL="$(tput el)"
CLEAR_EOS="$(tput ed)"
CLEAR_SCREEN="$(tput clear)"

clear() { tput ech "$1"; }
terminal_name() { tput longname; }
