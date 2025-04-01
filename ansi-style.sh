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

ansi::style::sgr() {
  local string='\e['
  for arg in "$@"; do
    string+="$arg;"
  done
  string="${string%;}m"
  echo "$string"
}

ansi::style::__define_constants() {
  declare -g -A ansi_style_sgr_commands=(
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

  declare -g -A ansi_style_sgr_extended_commands=(
    [extended_color]=1
    [fg_extended_color]=1
    [bg_extended_color]=1
    [decoration_color]=1
  )

  ansi::style::define_commands() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    for command in "${!ansi_style_sgr_commands[@]}"; do
      if [ -v ansi_style_sgr_extended_commands["$command"] ]; then continue; fi
      echo "${prefix}${command^^}='\e[${ansi_style_sgr_commands[$command]}m'"
    done
  }

  ansi::style::make() {
    local string="\e["
    for arg in "$@"; do
      if [ -v ansi_style_sgr_commands["$arg"] ]; then
        string+="${ansi_style_sgr_commands["$arg"]};"
      elif [[ "$arg" =~ ^[0-9] ]]; then
        string+="$arg;"
      else
        local regex='^(\e|\\e|\\033|\\x1B|\\x1b)\[([0-9\;:]+)m$'
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
    echo "\e[${ansi_style_sgr_commands["fg_extended_color"]};$(ansi::raw_c256 "$@")m"
  }
  ansi::bg_c256() {
    echo "\e[${ansi_style_sgr_commands["bg_extended_color"]};$(ansi::raw_c256 "$@")m"
  }

  ansi::raw_true() {
    local r="$1"
    local g="$2"
    local b="$3"
    # true color format: 2;R;G;B
    echo "2;${r};${g};${b}"
  }
  ansi::fg_true() {
    echo "\e[${ansi_style_sgr_commands["fg_extended_color"]};$(ansi::raw_true "$@")m"
  }
  ansi::bg_true() {
    echo "\e[${ansi_style_sgr_commands["bg_extended_color"]};$(ansi::raw_true "$@")m"
  }

  ansi::decoration_c256() {
    echo "\e[${ansi_style_sgr_commands["decoration_color"]};$(ansi::raw_c256 "$@")m"
  }
  ansi::decoration_true() {
    echo "\e[${ansi_style_sgr_commands["decoration_color"]};$(ansi::raw_true "$@")m"
  }
}
ansi::style::__define_constants
unset -f ansi::style::__define_constants

if [ -z "${ANSI_NO_DEFAULT_COMMANDS:-}" ] && [ -z "${ANSI_NO_DEFAULT_STYLE_COMMANDS:-}" ]; then eval "$(ansi::style::define_commands)"; fi

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
  echo "\e[${ansi_style_sgr_commands["fg_extended_color"]};$(ansi::raw_c256 "$@")m"
}

ansi::c256::fg_std() {
  echo "\e[${ansi_style_sgr_commands["fg_extended_color"]};$(ansi::raw_c256 "$@")m"
}

ansi::c256::fg_std_bright() {
  echo "\e[${ansi_style_sgr_commands["fg_extended_color"]};$(ansi::c256::raw_std_bright "$@")m"
}

ansi::c256::fg_true() {
  echo "\e[${ansi_style_sgr_commands["fg_extended_color"]};$(ansi::c256::raw_true "$@")m"
}

ansi::c256::fg_grey() {
  echo "\e[${ansi_style_sgr_commands["fg_extended_color"]};$(ansi::c256::raw_grey "$@")m"
}

ansi::c256::bg() {
  echo "\e[${ansi_style_sgr_commands["bg_extended_color"]};$(ansi::raw_std "$@")m"
}

ansi::c256::bg_std() {
  echo "\e[${ansi_style_sgr_commands["bg_extended_color"]};$(ansi::raw_std "$@")m"
}

ansi::c256::bg_std_bright() {
  echo "\e[${ansi_style_sgr_commands["bg_extended_color"]};$(ansi::c256::raw_std_bright "$@")m"
}

ansi::c256::bg_true() {
  echo "\e[${ansi_style_sgr_commands["bg_extended_color"]};$(ansi::c256::raw_true "$@")m"
}

ansi::c256::bg_grey() {
  echo "\e[${ansi_style_sgr_commands["bg_extended_color"]};$(ansi::c256::raw_grey "$@")m"
}

ansi::true::fg() {
  echo "\e[${ansi_style_sgr_commands["fg_extended_color"]};$(ansi::raw_true "$@")m"
}

ansi::true::bg() {
  echo "\e[${ansi_style_sgr_commands["bg_extended_color"]};$(ansi::raw_true "$@")m"
}

ansi::strip() {
  local string="$1"
  sed 's/\(\x1B\|\\e\|\\x1B\|\\033\)\[[0-9;:]*[a-z]//gi' <<< "$string"
}

ansi::extract_sgr_commands() {
  local command="$1"
  local regex='^(\e|\\e|\\033|\\x1B|\\x1b)\[([0-9\;:]+)m$'
  if [[ "$command" =~ $regex ]]; then
    echo "${BASH_REMATCH[1]%;}"
    return 0
  fi
  echo "Error: Invalid command (${#command} characters): '$command'"
  return 1
}

ansi::err() {
  if [[ -t 2 || -z "$TERM" ]]; then
    echo -e "$@" >&2
    return 1
  fi

  local args=()
  for arg in "$@"; do
    args+=("$(ansi::strip "$arg")")
  done
  echo -e "${args[@]}" >&2
  return 1
}

ansi::out() {
  if [[ -t 1 || -z "$TERM" ]]; then
    echo -e "$@"
    return 0
  fi

  local args=()
  for arg in "$@"; do
    args+=("$(ansi::strip "$arg")")
  done
  echo -e "${args[@]}"
  return 0
}
