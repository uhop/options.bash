#!/usr/bin/env bash

if type ansi::control::get > /dev/null 2>&1; then return; fi

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

ansi::control::__define_constants() {
  declare -g -A ansi_control_sequences=(
    # cursor movement
    [cursor_up1]='\e[A'
    [cursor_down1]='\e[B'
    [cursor_right1]='\e[C'
    [cursor_left1]='\e[D'
    [cursor_next_line1]='\e[E'
    [cursor_prev_line1]='\e[F'
    [cursor_column1]='\e[G'
    [cursor_home]='\e[H'
    [cursor_forward1]='\e[C'
    [cursor_backward1]='\e[D'
    # cursor management
    [cursor_save]='\e[s'
    [cursor_restore]='\e[u'
    [cursor_get_position]='\e[6n'
    [cursor_normal]='\e[?25h'
    [cursor_hidden]='\e[?25l'
    # clear screen
    [clear_eos]='\e[J'
    [clear_bos]='\e[1J'
    [clear_screen]='\e[2J'
    [clear_screen_all]='\e[3J'
    [clear_eol]='\e[K'
    [clear_bol]='\e[1K'
    [clear_line]='\e[2K'
    # screen management
    [screen_scroll_up1]='\e[S'
    [screen_scroll_down1]='\e[T'
    [screen_save]='\e[?47h'
    [screen_restore]='\e[?47l'
    [screen_alt_on]='\e[?1049h'
    [screen_alt_off]='\e[?1049l'
    [screen_report_focus_on]='\e[?1004h'
    [screen_report_focus_off]='\e[?1004l'
    # csi miscellaneous
    [wrapping_on]='\e[=7h'
    [wrapping_off]='\e[=7l'
    [bracketed_paste_on]='\e[=2004h'
    [bracketed_paste_off]='\e[=2004l'
    # miscellaneous
    [esc]='\e'
    [cursor_delete]='\177'
    [cursor_go_up1]='\033M'
    [cursor_save]='\0337'
    [cursor_restore]='\0338'
  )

  ansi::control::define_commands() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    for sequence in "${!ansi_control_sequences[@]}"; do
      echo "${prefix}${sequence^^}='${ansi_control_sequences[$sequence]}'"
    done
  }

  ansi::control::get() {
    local name="$1"
    if [ -v ansi_control_sequences["$name"] ]; then
      echo "\e[${ansi_control_sequences["$name"]}m"
    fi
  }
}
ansi::control::__define_constants
unset -f ansi::control::__define_constants

if [ -z "${ANSI_NO_DEFAULT_COMMANDS:-}" ] && [ -z "${ANSI_NO_DEFAULT_CONTROL_COMMANDS:-}" ]; then eval "$(ansi::control::define_commands)"; fi

ansi::cursor::up() {
  echo "\e[${1:-1}A"
}
ansi::cursor::down() {
  echo "\e[${1:-1}B"
}
ansi::cursor::right() {
  echo "\e[${1:-1}C"
}
ansi::cursor::left() {
  echo "\e[${1:-1}D"
}
ansi::cursor::next_line() {
  echo "\e[${1:-1}E"
}
ansi::cursor::prev_line() {
  echo "\e[${1:-1}F"
}
ansi::cursor::column() {
  echo "\e[${1:-1}G"
}
ansi::cursor::forward() {
  echo "\e[${1:-1}C"
}
ansi::cursor::backward() {
  echo "\e[${1:-1}D"
}
ansi::cursor::set_position() {
  echo "\e[${1:-};${2:-}H"
}
ansi::cursor::set_position_alt() {
  # HVP
  echo "\e[${1:-};${2:-}f"
}

ansi::screen::scroll_up() {
  echo "\e[${1:-1}S"
}
ansi::screen::scroll_down() {
  echo "\e[${1:-1}T"
}

ansi::hyperlink() {
  # OSC 8: https://github.com/Alhadis/OSC8-Adoption
  local url="$1"
  local text="${2:-$1}"
  echo "\e]8;;${url}\e\\${text}\e]8;;\e\\"
}
