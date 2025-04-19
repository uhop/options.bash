#!/usr/bin/env bash

if type ansi::style::get > /dev/null 2>&1; then return; fi

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
  declare -g -A ansi_style_colors=(
    [black]=0
    [red]=1
    [green]=2
    [yellow]=3
    [blue]=4
    [magenta]=5
    [cyan]=6
    [white]=7
  )
  declare -g -A ansi_style_sgr_commands=(
    # commands
    [text_reset_all]=0
    [text_bold]=1
    [text_dim]=2
    [text_italic]=3
    [text_underline]=4
    [text_blink]=5
    [text_rapid_blink]=6
    [text_reverse]=7
    [text_hidden]=8
    [text_strike_through]=9
    [text_default_font]=10
    [text_reset_bold]=22
    [text_reset_dim]=22
    [text_reset_italic]=23
    [text_reset_underline]=24
    [text_reset_blink]=25
    [text_reset_rapid_blink]=25
    [text_reset_reverse]=27
    [text_reset_hidden]=28
    [text_reset_strike_through]=29
    [text_curly_underline]='4:3'
    [text_reset_curly_underline]=24
    [text_double_underline]=21
    [text_reset_double_underline]=24
    [text_extended_color]=38
    [fg_extended_color]=38
    [bg_extended_color]=48
    [fg_default]=39
    [bg_default]=49
    [text_reset_color]=39
    [text_reset_fg_color]=39
    [text_reset_bg_color]=49
    [text_overline]=53
    [text_reset_overline]=55
    [text_decoration_color]=58
    [text_decoration_default_color]=59
    [text_reset_decoration_color]=59
  )

  for color in "${!ansi_style_colors[@]}"; do
    ansi_style_sgr_commands["fg_${color}"]=$(("${ansi_style_colors[$color]}" + 30))
    ansi_style_sgr_commands["bg_${color}"]=$(("${ansi_style_colors[$color]}" + 40))
    ansi_style_sgr_commands["fg_bright_${color}"]=$(("${ansi_style_colors[$color]}" + 90))
    ansi_style_sgr_commands["bg_bright_${color}"]=$(("${ansi_style_colors[$color]}" + 100))
  done

  declare -g -A ansi_style_sgr_extended_commands=(
    [text_extended_color]=1
    [fg_extended_color]=1
    [bg_extended_color]=1
    [text_decoration_color]=1
  )

  ansi::style::define_commands() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    for command in "${!ansi_style_sgr_commands[@]}"; do
      if [ -v ansi_style_sgr_extended_commands["$command"] ]; then continue; fi
      echo "${prefix}${command^^}='\e[${ansi_style_sgr_commands[$command]}m'"
    done
  }

  ansi::style::alias_simple_command_names() {
    local prefix="${1:-}"
    prefix="${prefix^^}"

    for color in "${!ansi_style_colors[@]}"; do
      echo "${prefix}${color^^}=\"\${${prefix}FG_${color^^}:-}\""
      echo "${prefix}BRIGHT_${color^^}=\"\${${prefix}FG_BRIGHT_${color^^}:-}\""
    done

    for name in "${!ansi_style_sgr_commands[@]}"; do
      if ! [[ "$name" =~ ^text_ ]]; then continue; fi
      local short_name="${name#text_}"
      echo "${prefix}${short_name^^}=\"\${${prefix}${name^^}:-}\""
    done
  }

  ansi::style::get() {
    local name="$1"
    if [ -v ansi_style_sgr_commands["$name"] ]; then
      echo "\e[${ansi_style_sgr_commands["$name"]}m"
    fi
  }

  ansi::style::make() {
    local string="\e["
    for arg in "$@"; do
      if [ -v ansi_style_sgr_commands["$arg"] ]; then
        string+="${ansi_style_sgr_commands["$arg"]};"
      elif [[ -v ansi_style_sgr_commands["text_${arg}"] ]]; then
        string+="${ansi_style_sgr_commands["text_${arg}"]};"
      elif [[ "$arg" =~ ^[0-9] ]]; then
        string+="$arg;"
      else
        local regex='^(\e|\\e|\\033|\\x1B|\\x1b)\[([0-9\;:]+)m$'
        if [[ "$arg" =~ $regex ]]; then
          string+="${BASH_REMATCH[2]%;};"
        else
          echo "Error: Invalid command (${#arg} characters): ${arg@Q}"
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

# if [ -z "${ANSI_NO_DEFAULT_COMMANDS:-}" ] && [ -z "${ANSI_NO_DEFAULT_STYLE_COMMANDS:-}" ]; then
#   eval "$(ansi::style::define_commands)"
# fi

ansi_style_simple_command_names=""
if [ -z "${ANSI_STYLE_NO_SIMPLE_NAMES:-}" ]; then
  ansi_style_simple_command_names="$(ansi::style::alias_simple_command_names)"
fi
eval "$(printf '%s\n%s\n' \
  "$(ansi::style::define_commands)" \
  "${ansi_style_simple_command_names}")"
unset ansi_style_simple_command_names

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

ansi::length() {
  local string="$1"
  local string_clean=$(ansi::strip "$string")
  echo "${#string_clean}"
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

ansi::prompt() {
  if [[ -t 1 || -z "$TERM" ]]; then
    echo -en "$@"
    return 0
  fi

  local args=()
  for arg in "$@"; do
    args+=("$(ansi::strip "$arg")")
  done
  echo -en "${args[@]}"
  return 0
}
