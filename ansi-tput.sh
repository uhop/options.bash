#!/usr/bin/env bash

# if type ansi::style::get > /dev/null 2>&1; then return; fi

set -o errexit -o pipefail -o nounset -o noclobber

if [[ -z "$BASH_VERSION" ]]; then
  echo "This script requires bash."
  exit 1
fi

if [[ "$BASH_VERSION" < "4.3" ]]; then
  echo "This script requires bash version 4.3 or higher."
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
  declare -g -a ansi_tput_text_styles=(
    bold dim italic underline blink reverse hidden strike standout
    reset_bold reset_dim reset_italic reset_underline reset_blink
    reset_reverse reset_hidden reset_strike reset_standout
    reset
  )
  declare -g -A ansi_tput_controls=(
    # turn on_styles
    [text_bold]='bold'
    [text_dim]='dim'
    [text_italic]='sitm'
    [text_underline]='smul'
    [text_blink]='blink'
    [text_reverse]='rev'
    [text_hidden]='invis'
    [text_strike]='smxx'
    [text_standout]='smso'

    # turn off_styles
    [text_reset_bold]='sgr 0 0 0 0 0 1 0 0 0'
    [text_reset_dim]='sgr 0 0 0 0 1 0 0 0 0'
    [text_reset_italic]='ritm'
    [text_reset_underline]='rmul'
    [text_reset_blink]='sgr 0 0 0 1 0 0 0 0 0'
    [text_reset_reverse]='sgr 0 0 1 0 0 0 0 0 0'
    [text_reset_hidden]='sgr 0 0 0 0 0 0 1 0 0'
    [text_reset_strike]='rmxx'
    [text_reset_standout]='rmso'

    [text_reset]='sgr0'

    # cursor operations
    [cursor_up1]='cuu1'
    [cursor_down1]='cud1'
    [cursor_left1]='cub1'
    [cursor_right1]='cuf1'
    [cursor_home]='home'
    [cursor_save]='sc'
    [cursor_restore]='rc'
    [cursor_hide]='civis'
    [cursor_show]='cnorm'
    # [cursor_last]='ll'

    # screen operations
    [screen_save]='smcup'
    [screen_restore]='rmcup'

    # clear operations
    [clear_bol]='el1'
    [clear_eol]='el'
    [clear_eos]='ed'
    [clear_screen]='clear'
  )
  declare -g -A ansi_tput_color_codes=()

  for color in "${!ansi_tput_colors[@]}"; do
    ansi_tput_color_codes["fg_${color}"]="setaf ${ansi_tput_colors[$color]}"
    ansi_tput_color_codes["bg_${color}"]="setab ${ansi_tput_colors[$color]}"
    local bright_color=$((${ansi_tput_colors[$color]} + 8))
    ansi_tput_color_codes["fg_bright_${color}"]="setaf $bright_color"
    ansi_tput_color_codes["bg_bright_${color}"]="setab $bright_color"
  done
  ansi_tput_color_codes["fg_bg_reset"]="op"

  ansi_tput_longname="$(tput longname)"

  ansi::tput::collect_codes() {
    local -n assoc="$1"
    local prefix="${2:-}"
    prefix="${prefix^^}"

    local names=()
    local string=""
    for name in "${!assoc[@]}"; do
      names+=("$name")
      string+="${assoc[$name]}\nlongname\n"
    done

    local result="$(tput -S <<< "$(echo -e "$string")" || true)"
    if [[ -z "$result" ]]; then return 1; fi

    local delimiter="${ansi_tput_longname}"
    local replacement=$'\x01'
    local escaped_result="${result//'\\'/'\\\\'}"
    local modified_result="${escaped_result//$delimiter/$replacement}"
    local -a values
    set +e
    IFS="$replacement" read -rd '' -a values <<< "$modified_result" # Split into an array
    set -e

    if [[ ${#values[@]} -ne $((${#names[@]} + 1)) ]]; then return 1; fi

    for i in "${!names[@]}"; do
      echo "${prefix}${names[$i]^^}=${values[$i]@Q}"
    done
  }

  ansi::tput::define_colors() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    local fast_result="$(ansi::tput::collect_codes ansi_tput_color_codes)"
    if [[ -n "$fast_result" ]]; then
      echo "$fast_result"
      return
    fi

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

  ansi::tput::define_controls() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    local fast_result="$(ansi::tput::collect_codes ansi_tput_controls)"
    if [[ -n "$fast_result" ]]; then
      echo "$fast_result"
      echo "${prefix}TEXT_RESET_ALL=\"\${${prefix}FG_BG_RESET}\${${prefix}TEXT_RESET}\""
      return
    fi

    for style in "${!ansi_tput_controls[@]}"; do
      local code=$(tput ${ansi_tput_controls[$style]} || true)
      if [[ -n "$code" ]]; then echo "${prefix}${style^^}=${code@Q}"; fi
    done

    echo "${prefix}TEXT_RESET_ALL=\"\${${prefix}FG_BG_RESET}\${${prefix}TEXT_RESET}\""
  }

  ansi::tput::alias_simple_style_names() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    for name in "${ansi_tput_text_styles[@]}"; do
      echo "${prefix}${name^^}=\"\${${prefix}TEXT_${name^^}:-}\""
    done

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
eval "$(printf '%s\n%s\n%s\n%s\n%s\n' \
  "$(ansi::tput::define_colors)" \
  "${ansi_tput_simple_color_names}" \
  "$(ansi::tput::define_controls)" \
  "${ansi_tput_simple_style_names}")"
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

cursor_pos() { tput cup "$1" "$2" || true; }
cursor_left() { tput cub "$1" || true; }
cursor_right() { tput cuf "$1" || true; }
cursor_insert() { tput ich "$1" || true; }
cursor_insert_lines() { tput il "$1" || true; }

screen_lines() { tput lines || true; }
screen_cols() { tput cols || true; }
screen_colors() { tput colors || true; }

clear() { tput ech "$1" || true; }
terminal_name() { tput longname || true; }
