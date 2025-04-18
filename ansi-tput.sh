#!/usr/bin/env bash

# if type ansi::style::get > /dev/null 2>&1; then return; fi

set -o errexit -o pipefail -o nounset -o noclobber

if [[ -z "$BASH_VERSION" ]]; then
  echo "This script requires bash."
  exit 1
fi

if [[ "$BASH_VERSION" < "4.0" ]]; then
  echo "This script requires bash version 4.0 or higher."
  if [[ "$(uname -s)" == "Darwin"* ]]; then
    echo "You can install it with Homebrew: brew install bash"
  fi
  exit 1
fi

ansi::tput::__define_constants() {
  declare -g -A ansi_tput_colors=(
    [black]=0
    [red]=1
    [green]=2
    [yellow]=3
    [blue]=4
    [magenta]=5
    [cyan]=6
    [white]=7
  )
  declare -g -A ansi_tput_styles=(
    [bold]='bold'
    [dim]='dim'
    [italic]='sitm'
    [underline]='smul'
    [blink]='blink'
    [reverse]='rev'
    [hidden]='invis'
    [strike]='smxx'
    [standout]='smso'
  )
  declare -g -A ansi_tput_reset_styles=(
    [bold]='sgr 0 0 0 0 0 1 0 0 0'
    [dim]='sgr 0 0 0 0 1 0 0 0 0'
    [italic]='ritm'
    [underline]='rmul'
    [blink]='sgr 0 0 0 1 0 0 0 0 0'
    [reverse]='sgr 0 0 1 0 0 0 0 0 0'
    [hidden]='sgr 0 0 0 0 0 0 1 0 0'
    [strike]='rmxx'
    [standout]='rmso'
  )

  ansi::tput::define_colors() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    for color in "${!ansi_tput_colors[@]}"; do
      local code=$(tput setaf ${ansi_tput_colors[$color]} || true)
      if [[ -n "$code" ]]; then echo "${prefix}FG_${color^^}=${code@Q}"; fi
      local code=$(tput setaf $((${ansi_tput_colors[$color]} + 8)) || true)
      if [[ -n "$code" ]]; then echo "${prefix}FG_BRIGHT_${color^^}=${code@Q}"; fi
      local code=$(tput setab ${ansi_tput_colors[$color]} || true)
      if [[ -n "$code" ]]; then echo "${prefix}BG_${color^^}=${code@Q}"; fi
      local code=$(tput setab $((${ansi_tput_colors[$color]} + 8)) || true)
      if [[ -n "$code" ]]; then echo "${prefix}BG_BRIGHT_${color^^}=${code@Q}"; fi
    done

    local code=$(tput op || true)
    echo "${prefix}FG_BG_RESET=${code@Q}"
  }

  ansi::tput::alias_simple_color_names() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    for color in "${!ansi_tput_colors[@]}"; do
      echo "${prefix}${color^^}=\"\${${prefix}FG_${color^^}:-}\""
      echo "${prefix}BRIGHT_${color^^}=\"\${${prefix}FG_BRIGHT_${color^^}:-}\""
    done
  }

  ansi::tput::define_styles() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    for style in "${!ansi_tput_styles[@]}"; do
      local code=$(tput ${ansi_tput_styles[$style]} || true)
      if [[ -n "$code" ]]; then echo "${prefix}TEXT_${style^^}=${code@Q}"; fi
      local code=$(tput ${ansi_tput_reset_styles[$style]} || true)
      if [[ -n "$code" ]]; then echo "${prefix}TEXT_RESET_${style^^}=${code@Q}"; fi
    done

    local code=$(tput sgr0 || true)
    echo "${prefix}TEXT_RESET=${code@Q}"
    echo "${prefix}TEXT_RESET_ALL=\"\${${prefix}FG_BG_RESET}\${${prefix}TEXT_RESET}\""
  }

  ansi::tput::alias_simple_style_names() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    for style in "${!ansi_tput_styles[@]}"; do
      echo "${prefix}${style^^}=\"\${${prefix}TEXT_${style^^}:-}\""
      echo "${prefix}RESET_${style^^}=\"\${${prefix}TEXT_RESET_${style^^}:-}\""
    done

    echo "${prefix}RESET=\"\${${prefix}RESET:-}\""
    echo "${prefix}RESET_ALL=\"\${${prefix}TEXT_RESET_ALL:-}\""
  }
}
ansi::tput::__define_constants
unset -f ansi::tput::__define_constants

ansi_tput_simple_color_names=""
ansi_tput_simple_style_names=""
if [ -z "${ANSI_TPUT_NO_SIMPLE_NAMES:-}" ]; then
  ansi_tput_simple_color_names="$(ansi::tput::alias_simple_color_names)"
  ansi_tput_simple_style_names="$(ansi::tput::alias_simple_style_names)"
fi
eval "$(printf '%s\n%s\n%s\n%s\n' "$(ansi::tput::define_colors)" "${ansi_tput_simple_color_names}" "$(ansi::tput::define_styles)" "${ansi_tput_simple_style_names}")"
unset ansi_tput_simple_color_names
unset ansi_tput_simple_style_names

fg_color() { tput setaf "$1" || true; }
bg_color() { tput setab "$1" || true; }

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

# params (bool): standout, underline, reverse, blink, dim, bold, invis, protect, altcharset
text_sgr() { tput sgr "$@" || true; }

alias sgr=text_sgr

CURSOR_SAVE="$(tput sc || true)"
CURSOR_RESTORE="$(tput rc || true)"
CURSOR_HOME="$(tput home || true)"
CURSOR_DOWN1="$(tput cud1 || true)"
CURSOR_UP1="$(tput cuu1 || true)"
CURSOR_LEFT1="$(tput cub1 || true)"
CURSOR_RIGHT1="$(tput cuf1 || true)"
CURSOR_INVISIBLE="$(tput civis || true)"
CURSOR_HIGHLIGHT="$(tput cvvis || true)"
CURSOR_NORMAL="$(tput cnorm || true)"
CURSOR_LAST="$(tput ll || true)"

cursor_pos() { tput cup "$1" "$2" || true; }
cursor_left() { tput cub "$1" || true; }
cursor_right() { tput cuf "$1" || true; }
cursor_insert() { tput ich "$1" || true; }
cursor_insert_lines() { tput il "$1" || true; }

SCREEN_SAVE="$(tput smcup || true)"
SCREEN_RESTORE="$(tput rmcup || true)"

screen_lines() { tput lines || true; }
screen_cols() { tput cols || true; }
screen_colors() { tput colors || true; }

CLEAR_BOL="$(tput el1 || true)"
CLEAR_EOL="$(tput el || true)"
CLEAR_EOS="$(tput ed || true)"
CLEAR_SCREEN="$(tput clear || true)"

clear() { tput ech "$1" || true; }
terminal_name() { tput longname || true; }
