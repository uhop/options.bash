#!/usr/bin/env bash

if type ansi::fg > /dev/null 2>&1; then return; fi

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

_load_dependencies() {
  local script_dir=${BASH_SOURCE:-$0}
  script_dir="$(dirname "$(realpath "$script_dir")")"
  source "${script_dir}/ansi-utils.sh"
}
if ! type string::err >/dev/null 2>&1; then
  _load_dependencies
fi
unset -f _load_dependencies

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
  # default colors
  [fg_default]='setaf 9'
  [bg_default]='setab 9'

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

ansi::tput::populate_colors() {
  for color in "${!ansi_tput_colors[@]}"; do
    ansi_tput_color_codes["fg_${color}"]="setaf ${ansi_tput_colors[$color]}"
    ansi_tput_color_codes["bg_${color}"]="setab ${ansi_tput_colors[$color]}"
    local bright_color=$((${ansi_tput_colors[$color]} + 8))
    ansi_tput_color_codes["fg_bright_${color}"]="setaf $bright_color"
    ansi_tput_color_codes["bg_bright_${color}"]="setab $bright_color"
  done
  ansi_tput_color_codes["fg_bg_reset"]="op"
}
ansi::tput::populate_colors
unset -f ansi::tput::populate_colors

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

ansi::alias_simple_command_names() {
  echo "$(ansi::tput::alias_simple_color_names "$@")"
  echo "$(ansi::tput::alias_simple_style_names "$@")"
}

ansi::fg() { tput setaf "$1" || true; }
ansi::bg() { tput setab "$1" || true; }

# params (bool): standout, underline, reverse, blink, dim, bold, invis, protect, altcharset
ansi::tput::sgr() { tput sgr "$@" || true; }

ansi::cursor::pos() { tput cup "$1" "$2" || true; }
ansi::cursor::left() { tput cub "$1" || true; }
ansi::cursor::right() { tput cuf "$1" || true; }
ansi::cursor::insert() { tput ich "$1" || true; }
ansi::cursor::insert_lines() { tput il "$1" || true; }

ansi::screen::lines() { tput lines || true; }
ansi::screen::cols() { tput cols || true; }
ansi::screen::colors() { tput colors || true; }

ansi::terminal::name() { tput longname || true; }

ansi_tput_simple_names=""
if [ -z "${ANSI_NO_SIMPLE_COMMAND_NAMES:-}" ]; then
  ansi_tput_simple_names="$(ansi::alias_simple_command_names)"
fi
eval "$(printf '%s\n%s\n%s\n' \
  "$(ansi::tput::define_colors)" \
  "$(ansi::tput::define_controls)" \
  "${ansi_tput_simple_names}")"
unset ansi_tput_simple_names
