#!/usr/bin/env bash

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

ansi::sgr() {
  local string='\033['
  for arg in "$@"; do
    string+="$arg;"
  done
  string="${string%;}m"
  echo "$string"
}

ansi::__define_constants() {
  declare -g -A ansi_sgr_commands=(
    # commands
    [reset_all]=0
    [bold]=1
    [dim]=2
    [italic]=3
    [underline]=4
    [blink]=5
    [rapid_blink]=6
    [reverse]=7
    [hidden]=8
    [strike_through]=9
    [default_font]=10
    [reset_bold]=22
    [reset_dim]=22
    [reset_italic]=23
    [reset_underline]=24
    [reset_blink]=25
    [reset_rapid_blink]=25
    [reset_reverse]=27
    [reset_hidden]=28
    [reset_strike_through]=29
    [curly_underline]='4:3'
    [reset_curly_underline]=24
    [double_underline]=21
    [reset_double_underline]=24
    [extended_color]=38
    [fg_extended_color]=38
    [bg_extended_color]=48
    [default_color]=39
    [fg_default_color]=39
    [bg_default_color]=49
    [reset_color]=39
    [reset_fg_color]=39
    [reset_bg_color]=49
    [overline]=53
    [reset_overline]=55
    [decoration_color]=58
    [decoration_default_color]=59
    [reset_decoration_color]=59
    # colors
    [black]=30
    [red]=31
    [green]=32
    [yellow]=33
    [blue]=34
    [magenta]=35
    [cyan]=36
    [white]=37
    [default]=39
    # foreground colors
    [fg_black]=30
    [fg_red]=31
    [fg_green]=32
    [fg_yellow]=33
    [fg_blue]=34
    [fg_magenta]=35
    [fg_cyan]=36
    [fg_white]=37
    [fg_default]=39
    # background colors
    [bg_black]=40
    [bg_red]=41
    [bg_green]=42
    [bg_yellow]=43
    [bg_blue]=44
    [bg_magenta]=45
    [bg_cyan]=46
    [bg_white]=47
    [bg_default]=49
    # bright colors
    [bright_black]=90
    [bright_red]=91
    [bright_green]=92
    [bright_yellow]=93
    [bright_blue]=94
    [bright_magenta]=95
    [bright_cyan]=96
    [bright_white]=97
    [bright_default]=99
    # bright foreground colors
    [fg_bright_black]=90
    [fg_bright_red]=91
    [fg_bright_green]=92
    [fg_bright_yellow]=93
    [fg_bright_blue]=94
    [fg_bright_magenta]=95
    [fg_bright_cyan]=96
    [fg_bright_white]=97
    [fg_bright_default]=99
    # bright background colors
    [bg_bright_black]=100
    [bg_bright_red]=101
    [bg_bright_green]=102
    [bg_bright_yellow]=103
    [bg_bright_blue]=104
    [bg_bright_magenta]=105
    [bg_bright_cyan]=106
    [bg_bright_white]=107
    [bg_bright_default]=109
  )

  declare -g -A ansi_sgr_extended_commands=(
    [extended_color]=1
    [fg_extended_color]=1
    [bg_extended_color]=1
    [decoration_color]=1
  )

  declare -g -A ansi_sequences=(
    # cursor movement
    [cursor_up1]='\033[A'
    [cursor_down1]='\033[B'
    [cursor_right1]='\033[C'
    [cursor_left1]='\033[D'
    [cursor_next_line1]='\033[E'
    [cursor_prev_line1]='\033[F'
    [cursor_column1]='\033[G'
    [cursor_home]='\033[H'
    [cursor_forward1]='\033[C'
    [cursor_backward1]='\033[D'
    # cursor management
    [cursor_save]='\033[s'
    [cursor_restore]='\033[u'
    [cursor_get_position]='\033[6n'
    [cursor_normal]='\033[?25h'
    [cursor_hidden]='\033[?25l'
    # clear screen
    [clear_eos]='\033[J'
    [clear_bos]='\033[1J'
    [clear_screen]='\033[2J'
    [clear_screen_all]='\033[3J'
    [clear_eol]='\033[K'
    [clear_bol]='\033[1K'
    [clear_line]='\033[2K'
    # screen management
    [screen_scroll_up1]='\033[S'
    [screen_scroll_down1]='\033[T'
    [screen_save]='\033[?47h'
    [screen_restore]='\033[?47l'
    [screen_alt_on]='\033[?1049h'
    [screen_alt_off]='\033[?1049l'
    [screen_report_focus_on]='\033[?1004h'
    [screen_report_focus_off]='\033[?1004l'
    # csi miscellaneous
    [wrapping_on]='\033[=7h'
    [wrapping_off]='\033[=7l'
    [bracketed_paste_on]='\033[=2004h'
    [bracketed_paste_off]='\033[=2004l'
    # miscellaneous
    [esc]='\033'
    [cursor_delete]='\177'
    [cursor_go_up1]='\033M'
    [cursor_save]='\0337'
    [cursor_restore]='\0338'
  )

  # color bases
  # local decor_color=0
  # local decor_bright=100

  ansi::define_commands() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    for command in "${!ansi_sgr_commands[@]}"; do
      if [ -v ansi_sgr_extended_commands["$command"] ]; then continue; fi
      echo "${prefix}${command^^}='\033[${ansi_sgr_commands[$command]}m'"
    done

    for sequence in "${!ansi_sequences[@]}"; do
      echo "${prefix}${sequence^^}='${ansi_sequences[$sequence]}'"
    done
  }

  ansi::make_sgr() {
    local string="\033["
    for arg in "$@"; do
      if [ -v ansi_sgr_commands["$arg"] ]; then
        string+="${ansi_sgr_commands["$arg"]};"
      elif [[ "$arg" =~ ^[0-9] ]]; then
        string+="$arg;"
      else
        local regex='^(\\033|\033)\[([0-9\;:]+)m$'
        if [[ "$arg" =~ $regex ]]; then
          string+="${BASH_REMATCH[2]%;};"
        else
          local result=""
          for (( i=0; i<${#arg}; ++i )); do
            local char="${arg:$i:1}"
            local code="$(printf '%02x ' "$char")"
            if [[ $code -lt 32 ]]; then
              result+="\\x${code}"
            else
              result+="$char"
            fi
          done
          echo "Error: Invalid command (${#arg} characters): '$result'"
          exit 1
        fi
      fi
    done
    echo "${string%;}m"
  }

  ansi::fg_color() {
    # local fg_color=30
    echo "$((30 + $1))"
  }
  ansi::bg_color() {
    # local bg_color=40
    echo "$((40 + $1))"
  }

  ansi::fg_bright() {
    # local fg_bright=90
    echo "$((90 + $1))"
  }
  ansi::bg_bright() {
    # local bg_bright=100
    echo "$((100 + $1))"
  }

  ansi::raw_c256() {
    # c256 format: 5;C
    echo "5;${1}"
  }
  ansi::fg_c256() {
    echo "\033[${ansi_sgr_commands["fg_extended_color"]};$(ansi::raw_c256 "$@")m"
  }
  ansi::bg_c256() {
    echo "\033[${ansi_sgr_commands["bg_extended_color"]};$(ansi::raw_c256 "$@")m"
  }

  ansi::raw_true() {
    local r="$1"
    local g="$2"
    local b="$3"
    # true color format: 2;R;G;B
    echo "2;${r};${g};${b}"
  }
  ansi::fg_true() {
    echo "\033[${ansi_sgr_commands["fg_extended_color"]};$(ansi::raw_true "$@")m"
  }
  ansi::bg_true() {
    echo "\033[${ansi_sgr_commands["bg_extended_color"]};$(ansi::raw_true "$@")m"
  }

  ansi::decoration_c256() {
    echo "\033[${ansi_sgr_commands["decoration_color"]};$(ansi::raw_c256 "$@")m"
  }
  ansi::decoration_true() {
    echo "\033[${ansi_sgr_commands["decoration_color"]};$(ansi::raw_true "$@")m"
  }
}
ansi::__define_constants
unset -f ansi::__define_constants

if [[ -z "${ANSI_NO_DEFAULT_COMMANDS:-}" ]]; then eval "$(ansi::define_commands)"; fi

ansi::color::rgb() {
  local r="$1"
  local g="$2"
  local b="$3"

  local result=0
  if [[ "$r" -ne 0 ]]; then result+=1; fi
  if [[ "$g" -ne 0 ]]; then result+=2; fi
  if [[ "$b" -ne 0 ]]; then result+=4; fi
  echo "$result"
}

ansi::c256::raw_std_bright() {
  local color="$1"
  echo "$(ansi::raw_c256 "$((8 + $color))")"
}

ansi::c256::raw_true() {
  local r="$1"
  local g="$2"
  local b="$3"
  echo "$(ansi::raw_c256 $((16 + r * 6 / 256 * 36 + g * 6 / 256 * 6 + b * 6 / 256)))"
}

ansi::c256::raw_grey() {
  local intensity="$1"
  echo "$(ansi::raw_c256 $((232 + intensity * 24 / 256)))"
}

ansi::c256::fg() {
  echo "\033[${ansi_sgr_commands["fg_extended_color"]};$(ansi::raw_c256 "$@")m"
}

ansi::c256::fg_std() {
  echo "\033[${ansi_sgr_commands["fg_extended_color"]};$(ansi::raw_c256 "$@")m"
}

ansi::c256::fg_std_bright() {
  echo "\033[${ansi_sgr_commands["fg_extended_color"]};$(ansi::c256::raw_std_bright "$@")m"
}

ansi::c256::fg_true() {
  echo "\033[${ansi_sgr_commands["fg_extended_color"]};$(ansi::c256::raw_true "$@")m"
}

ansi::c256::fg_grey() {
  echo "\033[${ansi_sgr_commands["fg_extended_color"]};$(ansi::c256::raw_grey "$@")m"
}

ansi::c256::bg() {
  echo "\033[${ansi_sgr_commands["bg_extended_color"]};$(ansi::raw_std "$@")m"
}

ansi::c256::bg_std() {
  echo "\033[${ansi_sgr_commands["bg_extended_color"]};$(ansi::raw_std "$@")m"
}

ansi::c256::bg_std_bright() {
  echo "\033[${ansi_sgr_commands["bg_extended_color"]};$(ansi::c256::raw_std_bright "$@")m"
}

ansi::c256::bg_true() {
  echo "\033[${ansi_sgr_commands["bg_extended_color"]};$(ansi::c256::raw_true "$@")m"
}

ansi::c256::bg_grey() {
  echo "\033[${ansi_sgr_commands["bg_extended_color"]};$(ansi::c256::raw_grey "$@")m"
}

ansi::true::fg() {
  echo "\033[${ansi_sgr_commands["fg_extended_color"]};$(ansi::raw_true "$@")m"
}

ansi::true::bg() {
  echo "\033[${ansi_sgr_commands["bg_extended_color"]};$(ansi::raw_true "$@")m"
}

ansi::strip() {
  local string="$1"
  sed 's/\x1B\[[0-9;:]*[a-zA-Z]//g' <<< "$string"
}

ansi::extract_sgr_commands() {
  local command="$1"
  local regex='^\\033\[([0-9\;:]+)m$'
  if [[ "$command" =~ $regex ]]; then
    echo "${BASH_REMATCH[1]%;}"
    return 0
  fi
  echo "Error: Invalid command (${#command} characters): '$command'"
  return 1
}

ansi::out() {
  if [[ -t 1 ]]; then
    echo -e "$@"
    return 0
  fi

  local args=()
  for arg in "$@"; do
    args+=("$(ansi::strip "$arg")")
  done
  echo "${args[@]}"
  return 0
}

ansi::cursor::up() {
  echo "\033[${1:-1}A"
}
ansi::cursor::down() {
  echo "\033[${1:-1}B"
}
ansi::cursor::right() {
  echo "\033[${1:-1}C"
}
ansi::cursor::left() {
  echo "\033[${1:-1}D"
}
ansi::cursor::next_line() {
  echo "\033[${1:-1}E"
}
ansi::cursor::prev_line() {
  echo "\033[${1:-1}F"
}
ansi::cursor::column() {
  echo "\033[${1:-1}G"
}
ansi::cursor::forward() {
  echo "\033[${1:-1}C"
}
ansi::cursor::backward() {
  echo "\033[${1:-1}D"
}
ansi::cursor::set_position() {
  echo "\033[${1:-};${2:-}H"
}
ansi::cursor::set_position_alt() {
  # HVP
  echo "\033[${1:-};${2:-}f"
}

ansi::screen::scroll_up() {
  echo "\033[${1:-1}S"
}
ansi::screen::scroll_down() {
  echo "\033[${1:-1}T"
}
